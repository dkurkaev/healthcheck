import Foundation
import SwiftData

@Model
final class OtherImpactEntry: DeletableHistoryItem {
    var id: UUID
    var timestamp: Date
    var note: String
    var impact: OtherImpact?
    
    init(note: String = "", impact: OtherImpact? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.note = note
        self.impact = impact
    }
    
    var stableID: AnyHashable { id }
    func delete(from context: ModelContext) {
        context.delete(self)
    }
}
