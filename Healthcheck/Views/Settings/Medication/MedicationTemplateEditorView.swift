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
                    BodyAreaSelector(bodyAreas: bodyAreas, selectedBodyAreas: $selectedBodyAreas)
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
