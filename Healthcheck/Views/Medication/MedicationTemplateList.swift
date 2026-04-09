import SwiftUI
import SwiftData

/// Dedicated component for medication templates display
/// Ensures consistent card-based UI with proper spacing and interaction logic.
struct MedicationTemplateList: View {
    let templates: [MedicationTemplate]?
    let tempTemplates: [MedicationEditorView.TempTemplate]?
    let onEditSaved: (MedicationTemplate) -> Void
    let onEditTemp: (MedicationEditorView.TempTemplate) -> Void
    let onAdd: () -> Void
    let onDeleteSaved: (MedicationTemplate) -> Void
    let onDeleteTemp: (MedicationEditorView.TempTemplate) -> Void
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Шаблоны применения")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, .appHorizontalPadding)
                .padding(.top, 8)
            
            // Templates List
            if let saved = templates {
                ForEach(saved) { template in
                    templateCard(
                        name: template.name,
                        areaIDs: Set(template.bodyAreas.map(\.id)),
                        action: { onEditSaved(template) },
                        deleteAction: { onDeleteSaved(template) }
                    )
                }
            } else if let temp = tempTemplates {
                ForEach(temp) { template in
                    templateCard(
                        name: template.name,
                        areaIDs: template.bodyAreaIDs,
                        action: { onEditTemp(template) },
                        deleteAction: { onDeleteTemp(template) }
                    )
                }
            }
            
            // Add Template Button (Standard row-style button inside a card container for spacing)
            VStack(spacing: 0) {
                ActionButtonRow(title: "Добавить шаблон", color: .medicationBlue) {
                    onAdd()
                }
            }
            .padding()
            .cardStyle()
            .padding(.horizontal, .appHorizontalPadding)
            
            // Footer
            Text("Шаблоны связывают лекарство с зонами тела для быстрого применения")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, .appHorizontalPadding)
                .padding(.bottom, 12)
        }
    }
    
    private func templateCard(name: String, areaIDs: Set<UUID>, action: @escaping () -> Void, deleteAction: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
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
        }
        .buttonStyle(.plain)
        .padding()
        .cardStyle()
        .padding(.horizontal, .appHorizontalPadding)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteAction()
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}
