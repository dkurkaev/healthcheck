import Foundation
import SwiftData

@Model
final class Medication {
    var id: UUID
    var name: String
    var emoji: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \MedicationEntry.medication)
    var entries: [MedicationEntry]
    
    @Relationship(deleteRule: .cascade, inverse: \MedicationTemplate.medication)
    var templates: [MedicationTemplate]
    
    init(
        name: String,
        emoji: String = "💊"
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.createdAt = Date()
        self.entries = []
        self.templates = []
    }
}
