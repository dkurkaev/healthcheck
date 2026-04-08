import Foundation
import SwiftData

@Model
final class MedicationTemplate {
    var id: UUID
    var name: String // e.g., "Увлажняющий крем на всю кожу"
    var createdAt: Date
    
    var medication: Medication?
    
    @Relationship
    var bodyAreas: [BodyArea]
    
    init(
        name: String,
        medication: Medication? = nil,
        bodyAreas: [BodyArea] = []
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.medication = medication
        self.bodyAreas = bodyAreas
    }
}
