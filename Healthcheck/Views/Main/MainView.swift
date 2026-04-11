import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \FoodEntry.timestamp, order: .reverse)
    private var recentFoodEntries: [FoodEntry]
    
    @Query(sort: \MedicationEntry.timestamp, order: .reverse)
    private var recentMedicationEntries: [MedicationEntry]
    
    @Query(sort: \BodyAreaRating.timestamp, order: .reverse)
    private var recentRatings: [BodyAreaRating]
    
    @Query(sort: \OtherImpactEntry.timestamp, order: .reverse)
    private var recentOtherImpactEntries: [OtherImpactEntry]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var showAddFood = false
    @State private var showAddMedication = false
    @State private var showAddRatings = false
    @State private var showAddOtherImpact = false
    @State private var selectedHistoryType: HistoryType = .ratings
    @State private var healthStatusHeight: CGFloat = 0
    
    enum HistoryType: String, CaseIterable {
        case ratings = "Оценки"
        case food = "Еда"
        case meds = "Лекарства"
        case other = "Прочее"
        
        var icon: String {
            switch self {
            case .ratings: return "star.bubble.fill"
            case .food: return "fork.knife"
            case .meds: return "pills.fill"
            case .other: return "sun.max.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            QuickActionButton(title: "Еда", emoji: "🍽", gradient: .foodGradient, action: { showAddFood = true })
                            QuickActionButton(title: "Лекарство", emoji: "💊", gradient: .medicationGradient, action: { showAddMedication = true })
                        }
                        
                        HStack(spacing: 12) {
                            healthStatusCard
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear { healthStatusHeight = geo.size.height }
                                            .onChange(of: geo.size.height) { healthStatusHeight = geo.size.height }
                                    }
                                )
                            
                            Button(action: { showAddOtherImpact = true }) {
                                ZStack {
                                    Color.orange
                                    Image(systemName: "sun.max.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                                .frame(width: healthStatusHeight, height: healthStatusHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: .appHorizontalPadding, bottom: 0, trailing: .appHorizontalPadding))
                .listRowSeparator(.hidden).listRowBackground(Color.clear)
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("История").font(.title2).fontWeight(.bold).padding(.horizontal, .appHorizontalPadding)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(HistoryType.allCases, id: \.self) { type in
                                    HistoryTabButton(title: type.rawValue, icon: type.icon, isSelected: selectedHistoryType == type, action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedHistoryType = type }
                                    })
                                }
                            }
                            .padding(.horizontal, .appHorizontalPadding)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .listRowInsets(EdgeInsets()).listRowSeparator(.hidden).listRowBackground(Color.clear)
                
                Section {
                    switch selectedHistoryType {
                    case .ratings:
                        AppHistoryList(items: RatingTransaction.group(recentRatings), limit: 25, emptyMessage: "Пока нет оценок") { transaction in
                            NavigationLink(destination: RatingTransactionDetailView(timestamp: transaction.timestamp, ratings: transaction.ratings)) {
                                TimelineRow(
                                    emoji: RatingLabel.emoji(for: transaction.averageRating),
                                    title: "Оценка здоровья",
                                    subtitle: "\(transaction.ratings.count) зон · \(RatingLabel.text(for: transaction.averageRating))",
                                    time: transaction.timestamp.relativeString,
                                    accentColor: Color.ratingColor(transaction.averageRating)
                                )
                            }
                        }
                    case .food:
                        AppHistoryList(items: recentFoodEntries, limit: 30, emptyMessage: "Пока нет записей о еде") { entry in
                            NavigationLink(destination: FoodEntryDetailView(entry: entry)) {
                                TimelineRow(emoji: entry.foodItem?.emoji ?? "🍽", title: entry.foodItem?.name ?? "Продукт", subtitle: entry.note.isEmpty ? (DangerLabel.text(for: entry.foodItem?.dangerLevel ?? 1)) : entry.note, time: entry.timestamp.relativeString, accentColor: Color.dangerColor(entry.foodItem?.dangerLevel ?? 1))
                            }
                        }
                    case .meds:
                        AppHistoryList(items: recentMedicationEntries, limit: 30, emptyMessage: "Пока нет записей о лекарствах") { entry in
                            NavigationLink(destination: MedicationEntryDetailView(entry: entry)) {
                                TimelineRow(emoji: entry.medication?.emoji ?? "💊", title: entry.medication?.name ?? "Лекарство", subtitle: entry.bodyAreas.map(\.emoji).joined(separator: " "), time: entry.timestamp.relativeString, accentColor: Color.medicationBlue)
                            }
                        }
                    case .other:
                        AppHistoryList(items: recentOtherImpactEntries, limit: 30, emptyMessage: "Пока нет прочих записей") { entry in
                            NavigationLink(destination: OtherImpactEntryDetailView(entry: entry)) {
                                TimelineRow(emoji: entry.impact?.emoji ?? "☀️", title: entry.impact?.name ?? "Воздействие", subtitle: entry.note, time: entry.timestamp.relativeString, accentColor: Color.orange)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain).background(Color(.systemGroupedBackground))
            .navigationTitle("Хелс чек")
            .sheet(isPresented: $showAddFood) { AddFoodView() }
            .sheet(isPresented: $showAddMedication) { AddMedicationView() }
            .sheet(isPresented: $showAddOtherImpact) { AddOtherImpactView() }
            .sheet(isPresented: $showAddRatings) { AddRatingsView() }
        }
    }
    
    private var healthStatusCard: some View {
        Button(action: { showAddRatings = true }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Оценка здоровья").font(.headline).foregroundStyle(.white)
                    if let lastRating = recentRatings.first {
                        Label(lastRating.timestamp.isToday ? "Оценено сегодня в \(lastRating.timestamp.timeString)" : "Последняя: \(lastRating.timestamp.relativeString)", 
                              systemImage: lastRating.timestamp.isToday ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.9))
                    } else {
                        Label("Ещё не оценивали", systemImage: "questionmark.circle.fill")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.title3).foregroundStyle(.white)
            }
            .padding().background(Color.green).clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct HistoryTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
