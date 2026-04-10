import SwiftUI
import SwiftData

public struct MainView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    
    public init() {}
    
    @Query(sort: \FoodEntry.timestamp, order: .reverse)
    private var recentFoodEntries: [FoodEntry]
    
    @Query(sort: \MedicationEntry.timestamp, order: .reverse)
    private var recentMedicationEntries: [MedicationEntry]
    
    @Query(sort: \BodyAreaRating.timestamp, order: .reverse)
    private var recentRatings: [BodyAreaRating]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var showAddFood = false
    @State private var showAddMedication = false
    @State private var showAddRatings = false
    @State private var selectedHistoryType: HistoryType = .ratings
    
    enum HistoryType: String, CaseIterable {
        case ratings = "Оценки"
        case food = "Еда"
        case meds = "Лекарства"
        
        var icon: String {
            switch self {
            case .ratings: return "star.bubble"
            case .food: return "fork.knife"
            case .meds: return "pills"
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            List {
                // Top Sections (Quick Actions & Status)
                Group {
                    quickActionSection
                    healthStatusCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowSeparator(.hidden)
                
                // History Section Header
                historyHeader
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
                
                // History Items
                historyBody
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Хелс чек")
            .sheet(isPresented: $showAddFood) { AddFoodView() }
            .sheet(isPresented: $showAddMedication) { AddMedicationView() }
            .sheet(isPresented: $showAddRatings) { AddRatingsView() }
        }
    }
    
    private var quickActionSection: some View {
        HStack(spacing: 16) {
            QuickActionButton(
                title: "Еда",
                emoji: "🍽",
                gradient: .foodGradient,
                action: { showAddFood = true }
            )
            
            QuickActionButton(
                title: "Лекарство",
                emoji: "💊",
                gradient: .medicationGradient,
                action: { showAddMedication = true }
            )
        }
        .padding(.horizontal, .appHorizontalPadding)
    }
    
    private var healthStatusCard: some View {
        Button(action: { showAddRatings = true }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Оценка здоровья")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    if let lastRating = recentRatings.first {
                        if lastRating.timestamp.isToday {
                            Label("Оценено сегодня в \(lastRating.timestamp.timeString)", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        } else {
                            Label("Последняя оценка: \(lastRating.timestamp.relativeString)", systemImage: "exclamationmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    } else {
                        Label("Ещё не оценивали", systemImage: "questionmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.title3).foregroundStyle(.white)
            }
            .padding()
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, .appHorizontalPadding)
        }
        .buttonStyle(.plain)
    }
    
    private var historyHeader: some View {
        Menu {
            ForEach(HistoryType.allCases, id: \.self) { type in
                Button(action: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        selectedHistoryType = type
                    }
                }) {
                    Label(type.rawValue, systemImage: type.icon)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedHistoryType.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Image(systemName: "chevron.down.circle.fill")
                    .font(.body)
                    .foregroundStyle(.blue)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .appHorizontalPadding)
    }

    @ViewBuilder
    private var historyBody: some View {
        switch selectedHistoryType {
        case .ratings: ratingsList
        case .food: foodHistoryList
        case .meds: medsHistoryList
        }
    }
    
    private var ratingsList: some View {
        Group {
            if recentRatings.isEmpty {
                emptyHistoryView(message: "Пока нет оценок")
            } else {
                SharedRatingsList(ratings: recentRatings, limit: 25)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
            }
        }
    }
    
    private var foodHistoryList: some View {
        Group {
            if recentFoodEntries.isEmpty {
                emptyHistoryView(message: "Пока нет записей о еде")
            } else {
                ForEach(recentFoodEntries.prefix(30)) { entry in
                    ZStack {
                        NavigationLink(destination: FoodEntryDetailView(entry: entry)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        TimelineRow(
                            emoji: entry.foodItem?.emoji ?? "🍽",
                            title: entry.foodItem?.name ?? "Продукт",
                            subtitle: entry.note.isEmpty ? (DangerLabel.text(for: entry.foodItem?.dangerLevel ?? 1)) : entry.note,
                            time: entry.timestamp.relativeString,
                            accentColor: Color.dangerColor(entry.foodItem?.dangerLevel ?? 1)
                        )
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            try? modelContext.save()
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
            }
        }
    }
    
    private var medsHistoryList: some View {
        Group {
            if recentMedicationEntries.isEmpty {
                emptyHistoryView(message: "Пока нет записей о лекарствах")
            } else {
                ForEach(recentMedicationEntries.prefix(30)) { entry in
                    let areas = entry.bodyAreas.map(\.name).joined(separator: ", ")
                    ZStack {
                        NavigationLink(destination: MedicationEntryDetailView(entry: entry)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        TimelineRow(
                            emoji: entry.medication?.emoji ?? "💊",
                            title: entry.medication?.name ?? "Лекарство",
                            subtitle: areas.isEmpty ? "Применение" : areas,
                            time: entry.timestamp.relativeString,
                            accentColor: Color.medicationBlue
                        )
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            try? modelContext.save()
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
            }
        }
    }
    
    private func emptyHistoryView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars").font(.system(size: 40)).foregroundStyle(.secondary)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
