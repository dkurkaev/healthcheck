import Foundation
import SwiftData

@Model
final class FoodEntry {
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
}
