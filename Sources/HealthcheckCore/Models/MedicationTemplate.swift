import Foundation
import SwiftData

@Model
public final class MedicationTemplate {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var medication: Medication?
    
    @Relationship
    public var bodyAreas: [BodyArea]
    
    public init(
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
