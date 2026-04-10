import SwiftUI

struct BodyAreaSelector: View {
    var bodyAreas: [BodyArea]
    @Binding var selectedBodyAreas: Set<UUID>
    
    init(bodyAreas: [BodyArea], selectedBodyAreas: Binding<Set<UUID>>) {
        self.bodyAreas = bodyAreas
        self._selectedBodyAreas = selectedBodyAreas
    }
    
    var body: some View {
        FlowLayoutList(spacing: 8) {
            ForEach(bodyAreas) { area in
                let isSelected = selectedBodyAreas.contains(area.id)
                Button(action: {
                    if isSelected { 
                        selectedBodyAreas.remove(area.id) 
                    } else { 
                        selectedBodyAreas.insert(area.id) 
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(area.emoji)
                        Text(area.name)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color.medicationBlue.opacity(0.12) : Color.clear)
                    .foregroundStyle(isSelected ? Color.medicationBlue : .primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.medicationBlue.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}
