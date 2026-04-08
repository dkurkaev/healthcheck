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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Action Buttons
                    quickActionSection
                    
                    // Health Rating Status
                    healthStatusCard
                    
                    // Ratings timeline
                    ratingsSection
                }
                .padding()
            }
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
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Ratings Section (all history, newest first)
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Оценки")
                .font(.title2)
                .fontWeight(.bold)
            
            // Group ratings by transaction (same minute)
            let transactions = groupRatingsIntoTransactions(recentRatings)
            
            if transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Пока нет оценок")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(transactions.prefix(30), id: \.key) { transaction in
                    let avgRating = transaction.ratings.isEmpty ? 0 : transaction.ratings.map(\.rating).reduce(0, +) / transaction.ratings.count
                    TimelineRow(
                        emoji: RatingLabel.emoji(for: avgRating),
                        title: "Оценка здоровья",
                        subtitle: "\(transaction.ratings.count) зон · \(RatingLabel.text(for: avgRating))",
                        time: transaction.timestamp.relativeString,
                        accentColor: Color.ratingColor(avgRating)
                    )
                }
            }
        }
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
