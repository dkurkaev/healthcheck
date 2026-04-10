import Foundation
import SwiftData

@Model
public final class Medication {
    public var id: UUID
    public var name: String
    public var emoji: String
    public var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \MedicationEntry.medication)
    public var entries: [MedicationEntry]
    
    @Relationship(deleteRule: .cascade, inverse: \MedicationTemplate.medication)
    public var templates: [MedicationTemplate]
    
    public init(
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
