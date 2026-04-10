import SwiftUI

public struct LargeSelectableTile: View {
    public let emoji: String
    public let title: String
    public let isSelected: Bool
    public let accentColor: Color
    public let action: () -> Void
    
    public init(emoji: String, title: String, isSelected: Bool, accentColor: Color, action: @escaping () -> Void) {
        self.emoji = emoji
        self.title = title
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 28))
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 85) // Fixed height for grid stability
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? accentColor : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
