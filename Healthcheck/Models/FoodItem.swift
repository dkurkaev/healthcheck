import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var emoji: String
    var isFavorite: Bool
    var dangerLevel: Int // 1-5 (1=safe, 5=very dangerous)
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.foodItem)
    var entries: [FoodEntry]
    
    init(
        name: String,
        emoji: String = "🍽",
        isFavorite: Bool = false,
        dangerLevel: Int = 1
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.isFavorite = isFavorite
        self.dangerLevel = min(max(dangerLevel, 1), 5)
        self.createdAt = Date()
        self.entries = []
    }
    
    var dangerColor: String {
        switch dangerLevel {
        case 1: return "dangerLevel1"
        case 2: return "dangerLevel2"
        case 3: return "dangerLevel3"
        case 4: return "dangerLevel4"
        case 5: return "dangerLevel5"
        default: return "dangerLevel1"
        }
    }
}
