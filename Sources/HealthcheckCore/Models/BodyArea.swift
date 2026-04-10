import Foundation
import SwiftData

@Model
public final class BodyArea {
    public var id: UUID
    public var name: String
    public var emoji: String
    public var isSkinRelated: Bool
    public var sortOrder: Int
    public var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \BodyAreaRating.bodyArea)
    public var ratings: [BodyAreaRating]
    
    @Relationship(inverse: \MedicationTemplate.bodyAreas)
    public var medicationTemplates: [MedicationTemplate]
    
    @Relationship(inverse: \MedicationEntry.bodyAreas)
    public var medicationEntries: [MedicationEntry]
    
    public init(
        name: String,
        emoji: String,
        isSkinRelated: Bool = false,
        sortOrder: Int = 0
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
    
    public var latestRating: BodyAreaRating? {
        ratings.sorted { $0.timestamp > $1.timestamp }.first
    }
    
    public var todayRating: BodyAreaRating? {
        let calendar = Calendar.current
        return ratings.first { calendar.isDateInToday($0.timestamp) }
    }
}
