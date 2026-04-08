import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \FoodEntry.timestamp, order: .reverse)
    private var recentFoodEntries: [FoodEntry]
    
    @Query(sort: \MedicationEntry.timestamp, order: .reverse)
    private var recentMedicationEntries: [MedicationEntry]
    
    @Query(sort: \BodyAreaRating.timestamp, order: .reverse)
    private var recentRatings: [BodyAreaRating]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var showAddFood = false
    @State private var showApplyMedication = false
    @State private var showRateHealth = false
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
    
    var body: some View {
        NavigationStack {
            List {
                // Header Sections
                Section {
                    quickActionSection
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listSectionSeparator(.hidden)
                
                Section {
                    healthStatusCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listSectionSeparator(.hidden)
                
                // Switchable history timeline
                Section {
                    historySection
                } header: {
                    historyHeader
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .listStyle(.grouped)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Хелс чек")
            .sheet(isPresented: $showAddFood) {
                AddFoodView()
            }
            .sheet(isPresented: $showApplyMedication) {
                ApplyMedicationView()
            }
            .sheet(isPresented: $showRateHealth) {
                RateHealthView()
            }
        }
    }
    
    // MARK: - Quick Actions
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
                action: { showApplyMedication = true }
            )
        }
        .padding(.horizontal, .appHorizontalPadding)
    }
    
    // MARK: - Health Status Card
    private var healthStatusCard: some View {
        Button(action: { showRateHealth = true }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Оценка здоровья")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let lastRating = recentRatings.first {
                        if lastRating.timestamp.isToday {
                            Label("Оценено сегодня в \(lastRating.timestamp.timeString)", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        } else {
                            Label("Последняя оценка: \(lastRating.timestamp.relativeString)", systemImage: "exclamationmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Label("Ещё не оценивали", systemImage: "questionmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .cardStyle()
            .padding(.horizontal, .appHorizontalPadding)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - History Section
    // MARK: - History Section
    // MARK: - History Section
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
        .textCase(nil) // Disable default section header caps
        .padding(.horizontal, .appHorizontalPadding)
        .padding(.bottom, 8)
    }

    private var historySection: some View {
        Group {
            if selectedHistoryType == .ratings {
                ratingsList
            } else if selectedHistoryType == .food {
                foodHistoryList
            } else {
                medsHistoryList
            }
        }
        .animation(nil, value: selectedHistoryType)
    }
    
    private var ratingsList: some View {
        let transactions = groupRatingsIntoTransactions(recentRatings)
        return Group {
            if transactions.isEmpty {
                emptyHistoryView(message: "Пока нет оценок")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(transactions.prefix(30), id: \.key) { transaction in
                    let avgRating = transaction.ratings.isEmpty ? 0 : Int((Double(transaction.ratings.map(\.rating).reduce(0, +)) / Double(transaction.ratings.count)).rounded())
                    ZStack {
                        NavigationLink(destination: RatingTransactionDetailView(timestamp: transaction.timestamp, ratings: transaction.ratings)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        TimelineRow(
                            emoji: RatingLabel.emoji(for: avgRating),
                            title: "Оценка здоровья",
                            subtitle: "\(transaction.ratings.count) зон · \(RatingLabel.text(for: avgRating))",
                            time: transaction.timestamp.relativeString,
                            accentColor: Color.ratingColor(avgRating)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteRatingTransaction(transaction.ratings)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private var foodHistoryList: some View {
        Group {
            if recentFoodEntries.isEmpty {
                emptyHistoryView(message: "Пока нет записей о еде")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            try? modelContext.save()
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private var medsHistoryList: some View {
        Group {
            if recentMedicationEntries.isEmpty {
                emptyHistoryView(message: "Пока нет записей о лекарствах")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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
                            accentColor: .medicationBlue
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            try? modelContext.save()
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private func emptyHistoryView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private func deleteRatingTransaction(_ ratings: [BodyAreaRating]) {
        for rating in ratings {
            modelContext.delete(rating)
        }
        try? modelContext.save()
    }
    
    // MARK: - Helpers
    private func groupRatingsIntoTransactions(_ ratings: [BodyAreaRating]) -> [(key: String, timestamp: Date, ratings: [BodyAreaRating])] {
        let grouped = Dictionary(grouping: ratings) { rating -> String in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: rating.timestamp)
            return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)-\(components.minute ?? 0)"
        }
        
        return grouped.map { key, ratings in
            (key: key, timestamp: ratings.first?.timestamp ?? Date(), ratings: ratings.sorted { ($0.bodyArea?.sortOrder ?? 0) < ($1.bodyArea?.sortOrder ?? 0) })
        }
        .sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Timeline Row
struct TimelineRow: View {
    let emoji: String
    let title: String
    let subtitle: String?
    let time: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [
            BodyArea.self, BodyAreaRating.self,
            FoodItem.self, FoodEntry.self,
            Medication.self, MedicationTemplate.self, MedicationEntry.self
        ], inMemory: true)
}
