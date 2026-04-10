import Foundation
import SwiftData

@Model
public final class MedicationEntry {
    public var id: UUID
    public var timestamp: Date
    public var note: String
    public var medication: Medication?
    
    @Relationship
    public var bodyAreas: [BodyArea]
    
    public init(
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
