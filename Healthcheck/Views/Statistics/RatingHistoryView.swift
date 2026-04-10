import SwiftUI
import SwiftData

struct RatingHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \BodyAreaRating.timestamp, order: .reverse)
    private var allRatings: [BodyAreaRating]
    
    @State private var showDeleteConfirmation = false
    @State private var transactionToDelete: [BodyAreaRating]?
    
    var body: some View {
        List {
            Section {
                AppHistoryList(items: RatingTransaction.group(allRatings), emptyMessage: "Пока нет оценок") { transaction in
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
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("История оценок")
    }
}

#Preview {
    NavigationStack {
        RatingHistoryView()
    }
    .modelContainer(for: [BodyArea.self, BodyAreaRating.self], inMemory: true)
}
