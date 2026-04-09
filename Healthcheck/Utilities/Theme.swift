import SwiftUI

// MARK: - Color Theme
extension Color {
    // Primary action colors
    static let foodRed = Color(red: 0.95, green: 0.25, blue: 0.3)
    static let foodRedDark = Color(red: 0.8, green: 0.15, blue: 0.2)
    static let medicationBlue = Color(red: 0.2, green: 0.5, blue: 0.95)
    static let medicationBlueDark = Color(red: 0.15, green: 0.35, blue: 0.8)
    
    // Rating colors (1=terrible → 5=excellent)
    static let rating1 = Color(red: 0.95, green: 0.25, blue: 0.25)   // Terrible - red
    static let rating2 = Color(red: 0.95, green: 0.55, blue: 0.2)    // Bad - orange
    static let rating3 = Color(red: 0.95, green: 0.8, blue: 0.2)     // Okay - yellow
    static let rating4 = Color(red: 0.5, green: 0.85, blue: 0.3)     // Good - lime
    static let rating5 = Color(red: 0.2, green: 0.85, blue: 0.5)     // Excellent - green
    
    // Danger level colors (food)
    static let dangerLevel1 = Color(red: 0.2, green: 0.85, blue: 0.5)
    static let dangerLevel2 = Color(red: 0.6, green: 0.85, blue: 0.3)
    static let dangerLevel3 = Color(red: 0.95, green: 0.8, blue: 0.2)
    static let dangerLevel4 = Color(red: 0.95, green: 0.55, blue: 0.2)
    static let dangerLevel5 = Color(red: 0.95, green: 0.25, blue: 0.25)
    
    // Background & Surface
    static let surfaceCard = Color(.systemBackground).opacity(0.8)
    static let surfaceElevated = Color(.secondarySystemBackground)
    
    static func ratingColor(_ rating: Int) -> Color {
        switch rating {
        case 1: return .rating1
        case 2: return .rating2
        case 3: return .rating3
        case 4: return .rating4
        case 5: return .rating5
        default: return .gray
        }
    }
    
    static func dangerColor(_ level: Int) -> Color {
        switch level {
        case 1: return .dangerLevel1
        case 2: return .dangerLevel2
        case 3: return .dangerLevel3
        case 4: return .dangerLevel4
        case 5: return .dangerLevel5
        default: return .gray
        }
    }
}

// MARK: - ShapeStyle Extensions (for .foregroundStyle)
extension ShapeStyle where Self == Color {
    static var foodRed: Color { Color.foodRed }
    static var foodRedDark: Color { Color.foodRedDark }
    static var medicationBlue: Color { Color.medicationBlue }
    static var medicationBlueDark: Color { Color.medicationBlueDark }
}

// MARK: - Gradients
extension LinearGradient {
    static let foodGradient = LinearGradient(
        colors: [Color.foodRed, Color.foodRedDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let medicationGradient = LinearGradient(
        colors: [Color.medicationBlue, Color.medicationBlueDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color(.systemBackground).opacity(0.9),
            Color(.systemBackground).opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Card Style Modifier
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Rating Label
struct RatingLabel {
    static func text(for rating: Int) -> String {
        switch rating {
        case 1: return "Ужасно"
        case 2: return "Плохо"
        case 3: return "Нормально"
        case 4: return "Хорошо"
        case 5: return "Отлично"
        default: return "—"
        }
    }
    
    static func emoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😫"
        case 2: return "😟"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "❓"
        }
    }
}

// MARK: - Danger Label
struct DangerLabel {
    static func text(for level: Int) -> String {
        switch level {
        case 1: return "Безопасно"
        case 2: return "Скорее безопасно"
        case 3: return "Умеренно"
        case 4: return "Опасно"
        case 5: return "Очень опасно"
        default: return "—"
        }
    }
}
