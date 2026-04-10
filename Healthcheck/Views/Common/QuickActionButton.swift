import SwiftUI

struct QuickActionButton: View {
    let title: String
    let emoji: String
    let gradient: LinearGradient
    let action: () -> Void
    
    init(title: String, emoji: String, gradient: LinearGradient, action: @escaping () -> Void) {
        self.title = title
        self.emoji = emoji
        self.gradient = gradient
        self.action = action
    }
    
    var body: some View {
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
