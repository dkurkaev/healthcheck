import SwiftUI

struct SelectionTilePanel<Item: Identifiable>: View {
    let title: String
    let items: [Item]
    let selectedID: UUID?
    let emojiProvider: (Item) -> String
    let titleProvider: (Item) -> String
    let accentColor: Color
    let action: (Item) -> Void
    
    init(
        title: String,
        items: [Item],
        selectedID: UUID?,
        emojiProvider: @escaping (Item) -> String,
        titleProvider: @escaping (Item) -> String,
        accentColor: Color,
        action: @escaping (Item) -> Void
    ) {
        self.title = title
        self.items = items
        self.selectedID = selectedID
        self.emojiProvider = emojiProvider
        self.titleProvider = titleProvider
        self.accentColor = accentColor
        self.action = action
    }
    
    var body: some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(items) { item in
                    LargeSelectableTile(
                        emoji: emojiProvider(item),
                        title: titleProvider(item),
                        isSelected: selectedID == (item.id as? UUID ?? UUID()),
                        accentColor: accentColor,
                        action: { action(item) }
                    )
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text(title)
        }
    }
}
