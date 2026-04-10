import SwiftUI
import SwiftData

public struct RatingHistoryView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \BodyAreaRating.timestamp, order: .reverse)
    private var allRatings: [BodyAreaRating]
    
    @State private var showDeleteConfirmation = false
    @State private var transactionToDelete: [BodyAreaRating]?
    
    public var body: some View {
        List {
            if allRatings.isEmpty {
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
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                SharedRatingsList(ratings: allRatings)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
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
