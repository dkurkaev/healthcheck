import SwiftUI

public struct AppTextField: View { public init() {}
    let title: String
    @Binding var text: String
    var icon: String? = nil
    
    public var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }
            
            TextField(title, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
