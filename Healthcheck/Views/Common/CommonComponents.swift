import SwiftUI

struct DangerLevelPicker: View {
    @Binding var selection: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { level in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = level }
                }) {
                    Text("\(level)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selection == level ? Color.dangerColor(level) : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(selection == level ? .white : .primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selection == level ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct EmojiPickerButton: View {
    @Binding var emoji: String
    @State private var isPickerPresented = false
    var body: some View {
        Button(action: { isPickerPresented = true }) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor.opacity(0.1)))
                .overlay(Circle().stroke(Color.accentColor.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .overlay {
            EmojiTextFieldNative(text: $emoji, isPresented: $isPickerPresented)
                .frame(width: 0, height: 0).opacity(0)
        }
    }
}

struct StandardHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline).fontWeight(.bold).foregroundStyle(.secondary)
            .padding(.horizontal, .appHorizontalPadding + 8)
            .padding(.top, 18).padding(.bottom, 2)
    }
}

struct ActionButtonRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String = "plus.circle.fill", color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon).foregroundStyle(color)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayoutList: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0; var currentY: CGFloat = 0; var lineHeight: CGFloat = 0; var maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0; currentY += lineHeight + spacing; lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}


