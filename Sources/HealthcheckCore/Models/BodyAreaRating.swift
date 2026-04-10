import Foundation
import SwiftData

@Model
public final class BodyAreaRating {
    public var id: UUID
    public var timestamp: Date
    public var rating: Int // 1-5
    public var note: String
    public var bodyArea: BodyArea?
    
    public init(
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
