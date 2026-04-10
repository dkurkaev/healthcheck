import Foundation
import SwiftData

@Model
public final class FoodItem {
    public var id: UUID
    public var name: String
    public var emoji: String
    public var isFavorite: Bool
    public var dangerLevel: Int // 1-5 (1=safe, 5=very dangerous)
    public var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.foodItem)
    public var entries: [FoodEntry]
    
    public init(
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
    
    public var dangerColor: String {
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
