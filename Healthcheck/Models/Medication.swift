import Foundation
import SwiftData

@Model
final class Medication: EditableListItem {
    var id: UUID
    var name: String
    var emoji: String
    var sortOrder: Int?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \MedicationEntry.medication)
    var entries: [MedicationEntry]
    
    @Relationship(deleteRule: .cascade, inverse: \MedicationTemplate.medication)
    var templates: [MedicationTemplate]
    
    init(
        name: String,
        emoji: String = "💊",
        sortOrder: Int? = 0
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.entries = []
        self.templates = []
    }
    
    func delete(from context: ModelContext) { context.delete(self) }
    
    var stableID: AnyHashable { id }
}
