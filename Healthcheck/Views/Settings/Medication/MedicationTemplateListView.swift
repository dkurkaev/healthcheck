import SwiftUI
import SwiftData

struct MedicationTemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    
    let isNew: Bool
    let medication: Medication?
    let tempTemplates: [MedicationEditorView.TempTemplate]
    let bodyAreas: [BodyArea]
    
    var onEditTemp: (MedicationEditorView.TempTemplate) -> Void
    var onDeleteTemp: (UUID) -> Void
    var onEditSaved: (MedicationTemplate) -> Void
    
    var body: some View {
        if isNew {
            ForEach(Array(tempTemplates.enumerated()), id: \.element.id) { index, template in
                Section(header: index == 0 ? Text("Шаблоны применения") : nil) {
                    templateCard(name: template.name, areaIDs: template.bodyAreaIDs) {
                        onEditTemp(template)
                    } deleteAction: {
                        onDeleteTemp(template.id)
                    }
                }
            }
        } else if let med = medication {
            ForEach(Array(med.templates.enumerated()), id: \.element.id) { index, template in
                Section(header: index == 0 ? Text("Шаблоны применения") : nil) {
                    templateCard(name: template.name, areaIDs: Set(template.bodyAreas.map(\.id))) {
                        onEditSaved(template)
                    } deleteAction: {
                        modelContext.delete(template)
                        try? modelContext.save()
                    }
                }
            }
        }
    }
    
    private func templateCard(name: String, areaIDs: Set<UUID>, action: @escaping () -> Void, deleteAction: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    let areas = bodyAreas.filter { areaIDs.contains($0.id) }
                    if !areas.isEmpty {
                        FlowLayoutList(spacing: 6) {
                            ForEach(areas) { area in
                                HStack(spacing: 4) {
                                    Text(area.emoji)
                                    Text(area.name)
                                }
                                .font(.caption2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.medicationBlue.opacity(0.12))
                                .foregroundStyle(Color.medicationBlue)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteAction() } label: { Label("Удалить", systemImage: "trash") }
        }
    }
}
