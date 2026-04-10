import SwiftUI
import SwiftData

struct MedicationEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var medication: Medication?
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    @State private var tempTemplates: [TempTemplate] = []
    
    @State private var activeSheet: ActiveTemplateSheet?
    @State private var showDeleteConfirmation = false
    
    private var isNew: Bool { medication == nil }
    
    struct TempTemplate: Identifiable, Equatable, Hashable {
        let id = UUID()
        var name: String
        var bodyAreaIDs: Set<UUID>
    }
    
    enum ActiveTemplateSheet: Identifiable, Hashable {
        case new
        case editSaved(MedicationTemplate)
        case editTemp(TempTemplate)
        
        var id: String {
            switch self {
            case .new: return "new"
            case .editSaved(let t): return t.id.uuidString
            case .editTemp(let t): return t.id.uuidString
            }
        }
    }
    
    var body: some View {
        Group {
            if isNew {
                NavigationStack {
                    editorContent
                }
            } else {
                editorContent
            }
        }
    }
    
    private var editorContent: some View {
        List {
            mainInfoSection
            templatesSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(isNew ? "Новое лекарство" : (medication?.name ?? "Правка"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                let hasChanges = isNew || medication?.name != editName || medication?.emoji != editEmoji
                let canSave = !editName.isEmpty && hasChanges
                
                Button("Сохранить") {
                    if isNew {
                        saveNewMedication()
                    } else {
                        updateMedication()
                        dismiss()
                    }
                }
                .fontWeight(.bold)
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let med = medication {
                editName = med.name
                editEmoji = med.emoji
            } else {
                editEmoji = "💊"
            }
        }
        .alert("Удалить лекарство?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                if let med = medication {
                    modelContext.delete(med)
                    try? modelContext.save()
                    dismiss()
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Лекарство \"\(editName)\" и все связанные шаблоны/записи будут удалены.")
        }
        .navigationDestination(item: $activeSheet) { sheet in
            MedicationTemplateEditorView(
                mode: sheet,
                bodyAreas: bodyAreas,
                isParentNew: isNew,
                onSave: { updatedTemplate, updatedTemp in
                    if let t = updatedTemplate {
                        if case .new = sheet {
                            saveNewSavedTemplate(t)
                        }
                    } else if let t = updatedTemp {
                        handleSaveTempTemplate(t, original: sheet)
                    }
                    activeSheet = nil
                }
            )
        }
    }
    
    // MARK: - Sub-views
    
    @ViewBuilder
    private var mainInfoSection: some View {
        Section("Основная информация") {
            MedicationFields(name: $editName, emoji: $editEmoji)
        }
    }
    
    @ViewBuilder
    private var templatesSection: some View {
        MedicationTemplateListView(
            isNew: isNew,
            medication: medication,
            tempTemplates: tempTemplates,
            bodyAreas: bodyAreas,
            onEditTemp: { activeSheet = .editTemp($0) },
            onDeleteTemp: { id in tempTemplates.removeAll { $0.id == id } },
            onEditSaved: { activeSheet = .editSaved($0) }
        )
    }
    
    @ViewBuilder
    private var actionsSection: some View {
        Section {
            ActionButtonRow(title: "Добавить шаблон", color: .medicationBlue) {
                activeSheet = .new
            }
        } footer: {
            Text("Шаблоны связывают лекарство с зонами тела для быстрого применения")
        }

        if !isNew {
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Удалить лекарство", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    
    private func handleSaveTempTemplate(_ template: TempTemplate, original: ActiveTemplateSheet) {
        if case .editTemp(let old) = original {
            if let index = tempTemplates.firstIndex(where: { $0.id == old.id }) {
                tempTemplates[index] = template
            }
        } else {
            tempTemplates.append(template)
        }
    }

    private func saveNewSavedTemplate(_ template: MedicationTemplate) {
        guard let med = medication else { return }
        template.medication = med
        modelContext.insert(template)
        try? modelContext.save()
    }
    
    private func saveNewMedication() {
        let newMed = Medication(name: editName, emoji: editEmoji)
        modelContext.insert(newMed)
        for temp in tempTemplates {
            let selectedAreas = bodyAreas.filter { temp.bodyAreaIDs.contains($0.id) }
            let template = MedicationTemplate(name: temp.name, medication: newMed, bodyAreas: selectedAreas)
            modelContext.insert(template)
        }
        try? modelContext.save()
        dismiss()
    }
    
    private func updateMedication() {
        guard let med = medication else { return }
        med.name = editName
        med.emoji = editEmoji
        try? modelContext.save()
    }
}

// MARK: - Medication Fields Component
struct MedicationFields: View {
    @Binding var name: String
    @Binding var emoji: String
    
    var body: some View {
        HStack(spacing: 16) {
            EmojiPickerButton(emoji: $emoji)
            
            TextField("Название лекарства", text: $name)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}
