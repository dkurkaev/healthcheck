import Foundation
import SwiftData

@Model
final class BodyAreaRating {
    var id: UUID
    var timestamp: Date
    var rating: Int // 1-5
    var note: String
    
    var bodyArea: BodyArea?
    
    init(
        rating: Int,
        note: String = "",
        bodyArea: BodyArea? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.rating = min(max(rating, 1), 5)
        self.note = note
        self.bodyArea = bodyArea
    }
}
