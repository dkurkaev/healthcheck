import SwiftUI
import SwiftData

struct MedicationTemplateEditorView: View {
    let mode: MedicationEditorView.ActiveTemplateSheet
    let bodyAreas: [BodyArea]
    let isParentNew: Bool
    let onSave: (MedicationTemplate?, MedicationEditorView.TempTemplate?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedBodyAreas: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            List {
                Section("Название шаблона") {
                    TextField("Например: На всю кожу", text: $name)
                        .font(.headline)
                }
                
                Section("Зоны применения") {
                    FlowLayoutList(spacing: 8) {
                        ForEach(bodyAreas) { area in
                            let isSelected = selectedBodyAreas.contains(area.id)
                            Button(action: {
                                if isSelected { selectedBodyAreas.remove(area.id) }
                                else { selectedBodyAreas.insert(area.id) }
                            }) {
                                HStack(spacing: 4) {
                                    Text(area.emoji)
                                    Text(area.name).font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.medicationBlue.opacity(0.12) : Color.clear)
                                .foregroundStyle(isSelected ? Color.medicationBlue : .primary)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(isSelected ? Color.medicationBlue.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { 
                    Button("Отмена") { dismiss() } 
                }
                ToolbarItem(placement: .confirmationAction) {
                    let canSave = !name.isEmpty && !selectedBodyAreas.isEmpty
                    
                    Button("Готово") {
                        handleSave()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: setup)
        }
    }
    
    private var title: String {
        if case .new = mode { return "Новый шаблон" }
        return "Изменить шаблон"
    }
    
    private func setup() {
        switch mode {
        case .new: break
        case .editSaved(let t):
            name = t.name
            selectedBodyAreas = Set(t.bodyAreas.map(\.id))
        case .editTemp(let t):
            name = t.name
            selectedBodyAreas = t.bodyAreaIDs
        }
    }
    
    private func handleSave() {
        if isParentNew {
            let temp = MedicationEditorView.TempTemplate(name: name, bodyAreaIDs: selectedBodyAreas)
            onSave(nil, temp)
        } else {
            if case .editSaved(let t) = mode {
                t.name = name
                t.bodyAreas = bodyAreas.filter { selectedBodyAreas.contains($0.id) }
                onSave(t, nil)
            } else {
                let newT = MedicationTemplate(name: name, bodyAreas: bodyAreas.filter { selectedBodyAreas.contains($0.id) })
                onSave(newT, nil)
            }
        }
    }
}
