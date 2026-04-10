import Foundation
import SwiftData

@Model
final class BodyArea: EditableListItem {
    var id: UUID
    var name: String
    var emoji: String
    var isSkinRelated: Bool
    var sortOrder: Int?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \BodyAreaRating.bodyArea)
    var ratings: [BodyAreaRating]
    
    @Relationship(inverse: \MedicationTemplate.bodyAreas)
    var medicationTemplates: [MedicationTemplate]
    
    @Relationship(inverse: \MedicationEntry.bodyAreas)
    var medicationEntries: [MedicationEntry]
    
    init(
        name: String,
        emoji: String,
        isSkinRelated: Bool = false,
        sortOrder: Int? = 0
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.isSkinRelated = isSkinRelated
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.ratings = []
        self.medicationTemplates = []
        self.medicationEntries = []
    }
    
    func delete(from context: ModelContext) { context.delete(self) }
    
    var stableID: AnyHashable { id }
    
    var latestRating: BodyAreaRating? {
        ratings.sorted { $0.timestamp > $1.timestamp }.first
    }
    
    var todayRating: BodyAreaRating? {
        let calendar = Calendar.current
        return ratings.first { calendar.isDateInToday($0.timestamp) }
    }
}
