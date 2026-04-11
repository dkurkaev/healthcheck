import Foundation
import SwiftData

@Model
final class OtherImpact: EditableListItem {
    var id: UUID
    var name: String
    var emoji: String
    var isFavorite: Bool
    var sortOrder: Int? // Required for EditableListItem
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \OtherImpactEntry.impact)
    var entries: [OtherImpactEntry]
    
    init(name: String, emoji: String = "☀️", isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.isFavorite = isFavorite
        self.sortOrder = 0
        self.createdAt = Date()
        self.entries = []
    }
    
    @MainActor var stableID: AnyHashable { id }
    @MainActor func delete(from context: ModelContext) {
        context.delete(self)
    }
}
