import Foundation
import SwiftData

@Model
final class MedicationEntry {
    var id: UUID
    var timestamp: Date
    var note: String
    
    var medication: Medication?
    
    @Relationship
    var bodyAreas: [BodyArea]
    
    init(
        note: String = "",
        medication: Medication? = nil,
        bodyAreas: [BodyArea] = []
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.note = note
        self.medication = medication
        self.bodyAreas = bodyAreas
    }
}
