import Foundation
import SwiftData

@Model
final class FoodEntry: DeletableHistoryItem {
    var id: UUID
    var timestamp: Date
    var note: String
    var foodItem: FoodItem?
    
    init(
        note: String = "",
        foodItem: FoodItem? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.note = note
        self.foodItem = foodItem
    }
    
    var stableID: AnyHashable { id }
    func delete(from context: ModelContext) { context.delete(self) }
}
