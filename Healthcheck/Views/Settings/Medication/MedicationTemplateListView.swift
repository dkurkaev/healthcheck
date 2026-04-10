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
            if !tempTemplates.isEmpty {
                Section(header: Text("Шаблоны применения")) {
                    ForEach(tempTemplates, id: \.id) { template in
                        templateCard(name: template.name, areaIDs: template.bodyAreaIDs) {
                            onEditTemp(template)
                        } deleteAction: {
                            onDeleteTemp(template.id)
                        }
                    }
                }
            }
        } else if let med = medication {
            if !med.templates.isEmpty {
                Section(header: Text("Шаблоны применения")) {
                    ForEach(med.templates) { template in
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
    }
    
    private func templateCard(name: String, areaIDs: Set<UUID>, action: @escaping () -> Void, deleteAction: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(name)
                        .font(.body)
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
                                .background(Color.secondary.opacity(0.1))
                                .foregroundStyle(.secondary)
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
