import SwiftUI
import SwiftData

// Протокол для удаления
@MainActor 
protocol DeletableHistoryItem {
    var stableID: AnyHashable { get }
    func delete(from context: ModelContext)
}

// Универсальная транзакция рейтинга (сгруппированная)
@MainActor
struct RatingTransaction: DeletableHistoryItem {
    let id: String
    let timestamp: Date
    let ratings: [BodyAreaRating]
    
    var stableID: AnyHashable { id }
    
    func delete(from context: ModelContext) {
        for rating in ratings { context.delete(rating) }
    }
    
    // Централизованная логика группировки
    static func group(_ ratings: [BodyAreaRating]) -> [RatingTransaction] {
        let grouped = Dictionary(grouping: ratings) { rating -> String in
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: rating.timestamp)
            return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)-\(components.minute ?? 0)"
        }
        return grouped.map { key, ratings in
            RatingTransaction(id: key, timestamp: ratings.first?.timestamp ?? Date(), ratings: ratings.sorted { ($0.bodyArea?.sortOrder ?? 0) < ($1.bodyArea?.sortOrder ?? 0) })
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    // Централизованный расчет среднего рейтинга
    var averageRating: Int {
        guard !ratings.isEmpty else { return 3 }
        return Int((Double(ratings.map(\.rating).reduce(0, +)) / Double(ratings.count)).rounded())
    }
}

@MainActor
struct AppHistoryList<T: DeletableHistoryItem, Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    let items: [T]
    let limit: Int?
    let emptyMessage: String
    let content: (T) -> Content
    
    init(items: [T], limit: Int? = nil, emptyMessage: String = "Нет записей", @ViewBuilder content: @escaping (T) -> Content) {
        self.items = items
        self.limit = limit
        self.emptyMessage = emptyMessage
        self.content = content
    }
    
    var body: some View {
        if items.isEmpty {
            Text(emptyMessage).font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 40).listRowBackground(Color.clear)
        } else {
            let displayList = limit != nil ? Array(items.prefix(limit!)) : items
            ForEach(displayList, id: \.stableID) { item in
                content(item)
                    .padding()
                    .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .padding(.vertical, 6)
                            .padding(.horizontal, .appHorizontalPadding)
                    )
                    .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                for index in offsets { displayList[index].delete(from: modelContext) }
                try? modelContext.save()
            }
        }
    }
}
