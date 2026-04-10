import Foundation
import SwiftData

@Model
public final class FoodEntry {
    public var id: UUID
    public var timestamp: Date
    public var note: String
    public var foodItem: FoodItem?
    
    public init(
        note: String = "",
        foodItem: FoodItem? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.note = note
        self.foodItem = foodItem
    }
}
