import Foundation
import SwiftData

public struct DataSeeder {
    static let defaultBodyAreas: [(name: String, emoji: String, isSkinRelated: Bool)] = [
        ("Волосы", "💇", false),
        ("Кожа на лбу", "🫥", true),
        ("Кожа над глазами", "👁", true),
        ("Кожа под глазами", "👀", true),
        ("Кожа лица", "😶", true),
        ("Кожа на груди", "🫁", true),
        ("Кожа под локтями", "💪", true),
        ("Кожа под коленями", "🦵", true),
        ("Общее состояние кожи", "🧴", true),
        ("Желудок", "🫄", false),
        ("Зубы", "🦷", false),
    ]
    
    @MainActor
    static func seedDefaultBodyAreas(context: ModelContext) {
        // Check if we already have body areas
        let descriptor = FetchDescriptor<BodyArea>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else { return }
        
        for (index, area) in defaultBodyAreas.enumerated() {
            let bodyArea = BodyArea(
                name: area.name,
                emoji: area.emoji,
                isSkinRelated: area.isSkinRelated,
                sortOrder: index
            )
            context.insert(bodyArea)
        }
        
        try? context.save()
    }
}
