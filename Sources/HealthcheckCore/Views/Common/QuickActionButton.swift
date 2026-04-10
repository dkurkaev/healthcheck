import SwiftUI

public struct QuickActionButton: View {
    public let title: String
    public let emoji: String
    public let gradient: LinearGradient
    public let action: () -> Void
    
    public init(title: String, emoji: String, gradient: LinearGradient, action: @escaping () -> Void) {
        self.title = title
        self.emoji = emoji
        self.gradient = gradient
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 34))
                    .shadow(radius: 2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
