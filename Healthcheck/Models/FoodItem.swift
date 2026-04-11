import Foundation
import SwiftData

enum FoodType: String, Codable, CaseIterable {
    case food = "food"
    case beverage = "beverage"
    
    var localizedName: String {
        switch self {
        case .food: return "Еда"
        case .beverage: return "Напиток"
        }
    }
}

@Model
final class FoodItem: EditableListItem {
    var id: UUID
    var name: String
    var emoji: String
    var isFavorite: Bool
    var dangerLevel: Int // 1-5 (1=safe, 5=very dangerous)
    var sortOrder: Int?
    var createdAt: Date
    var _type: FoodType?
    
    var type: FoodType {
        get { _type ?? .food }
        set { _type = newValue }
    }
    
    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.foodItem)
    var entries: [FoodEntry]
    
    init(
        name: String,
        emoji: String = "🍽",
        isFavorite: Bool = false,
        dangerLevel: Int = 1,
        sortOrder: Int? = 0,
        type: FoodType = .food
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.isFavorite = isFavorite
        self.dangerLevel = min(max(dangerLevel, 1), 5)
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self._type = type
        self.entries = []
    }
    
    func delete(from context: ModelContext) { context.delete(self) }
    
    var stableID: AnyHashable { id }
    
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
