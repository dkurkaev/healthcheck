import SwiftUI
import SwiftData

@MainActor
protocol EditableListItem {
    var stableID: AnyHashable { get }
    var sortOrder: Int? { get set }
    func delete(from context: ModelContext)
}

@MainActor
struct AppEditableList<T: EditableListItem, Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    let items: [T]
    let emptyView: AnyView
    let content: (T) -> Content
    
    init(
        items: [T],
        @ViewBuilder emptyView: @escaping () -> some View,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.items = items
        self.emptyView = AnyView(emptyView())
        self.content = content
    }
    
    var body: some View {
        List {
            if items.isEmpty {
                emptyView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(items, id: \.stableID) { item in
                    content(item)
                        .padding()
                        .contentShape(Rectangle())
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
                    for index in offsets {
                        items[index].delete(from: modelContext)
                    }
                    try? modelContext.save()
                }
                .onMove(perform: move)
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        var revisedItems = items
        revisedItems.move(fromOffsets: source, toOffset: destination)
        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].sortOrder = reverseIndex
        }
        try? modelContext.save()
    }
}
