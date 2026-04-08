import SwiftUI
import SwiftData

struct CreateMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // If nil, we are creating a new medication
    var medication: Medication?
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    
    // For creating new templates before the medication is saved
    @State private var tempTemplates: [TempTemplate] = []
    
    @State private var showAddTemplate = false
    @State private var editingSavedTemplate: MedicationTemplate?
    @State private var editingTempTemplateID: UUID?
    
    @State private var newTemplateName = ""
    @State private var selectedBodyAreas: Set<UUID> = []
    
    @State private var showDeleteConfirmation = false
    
    private var isNew: Bool { medication == nil }
    
    struct TempTemplate: Identifiable {
        let id = UUID()
        var name: String
        var bodyAreaIDs: Set<UUID>
    }
    
    var body: some View {
        if isNew {
            NavigationStack {
                editorContent
            }
        } else {
            editorContent
        }
    }
    
    private var editorContent: some View {
        List {
            // Information Section
            MedicationFields(name: $editName, emoji: $editEmoji)
            
            if let med = medication {
                Section {
                    HStack {
                        Text("Применений")
                        Spacer()
                        Text("\(med.entries.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Templates Section
            Section {
                if isNew {
                    // Show temp templates
                    ForEach(tempTemplates) { template in
                        templateRow(name: template.name, areaIDs: template.bodyAreaIDs)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    tempTemplates.removeAll { $0.id == template.id }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                                
                                Button {
                                    prepareEditTemp(template)
                                } label: {
                                    Label("Изменить", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                } else if let med = medication {
                    // Show saved templates
                    ForEach(med.templates) { template in
                        templateRow(name: template.name, areaIDs: Set(template.bodyAreas.map(\.id)))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(template)
                                    try? modelContext.save()
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                                
                                Button {
                                    prepareEditSaved(template)
                                } label: {
                                    Label("Изменить", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                }
                
                Button(action: { 
                    clearEditorState()
                    showAddTemplate = true 
                }) {
                    Label("Добавить шаблон", systemImage: "plus.circle")
                        .foregroundStyle(Color.medicationBlue)
                }
            } header: {
                Text("Шаблоны применения")
            } footer: {
                Text("Шаблоны связывают лекарство с зонами тела для быстрого применения")
            }
            
            if !isNew {
                // Delete Section
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
        .navigationTitle(isNew ? "Новое лекарство" : (medication?.name ?? "Правка"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(isNew ? "Отмена" : "Готово") {
                    dismiss()
                }
            }
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveNewMedication()
                    }
                    .fontWeight(.bold)
                    .disabled(editName.isEmpty)
                }
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
        .onDisappear {
            if !isNew {
                updateMedication()
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
        .sheet(isPresented: $showAddTemplate) {
            addTemplateSheet
        }
    }
    
    private func templateRow(name: String, areaIDs: Set<UUID>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            let areas = bodyAreas.filter { areaIDs.contains($0.id) }
            if !areas.isEmpty {
                FlowLayoutList {
                    ForEach(areas) { area in
                        Text("\(area.emoji) \(area.name)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.medicationBlue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func clearEditorState() {
        newTemplateName = ""
        selectedBodyAreas = []
        editingTempTemplateID = nil
        editingSavedTemplate = nil
    }
    
    private func prepareEditTemp(_ template: TempTemplate) {
        newTemplateName = template.name
        selectedBodyAreas = template.bodyAreaIDs
        editingTempTemplateID = template.id
        showAddTemplate = true
    }
    
    private func prepareEditSaved(_ template: MedicationTemplate) {
        newTemplateName = template.name
        selectedBodyAreas = Set(template.bodyAreas.map(\.id))
        editingSavedTemplate = template
        showAddTemplate = true
    }
    
    private func saveNewMedication() {
        let newMed = Medication(name: editName, emoji: editEmoji)
        modelContext.insert(newMed)
        
        // Save temp templates
        for temp in tempTemplates {
            let selectedAreas = bodyAreas.filter { temp.bodyAreaIDs.contains($0.id) }
            let template = MedicationTemplate(
                name: temp.name,
                medication: newMed,
                bodyAreas: selectedAreas
            )
            modelContext.insert(template)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func updateMedication() {
        guard let med = medication else { return }
        if !editName.isEmpty { med.name = editName }
        if !editEmoji.isEmpty { med.emoji = editEmoji }
        try? modelContext.save()
    }
    
    // MARK: - Add Template Sheet
    private var addTemplateSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название шаблона")
                            .font(.headline)
                        
                        TextField("Например: На всю кожу", text: $newTemplateName)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .cardStyle()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Зоны тела")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                let skinAreas = bodyAreas.filter { $0.isSkinRelated }
                                if selectedBodyAreas == Set(skinAreas.map(\.id)) {
                                    selectedBodyAreas.removeAll()
                                } else {
                                    selectedBodyAreas = Set(skinAreas.map(\.id))
                                }
                            }) {
                                let allSkinSelected = !bodyAreas.isEmpty && Set(bodyAreas.filter(\.isSkinRelated).map(\.id)).isSubset(of: selectedBodyAreas) && !bodyAreas.filter(\.isSkinRelated).isEmpty
                                Text(allSkinSelected ? "Снять все" : "Вся кожа")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(allSkinSelected ? Color.medicationBlue : Color(.tertiarySystemBackground))
                                    .foregroundStyle(allSkinSelected ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        ForEach(bodyAreas) { area in
                            Button(action: {
                                if selectedBodyAreas.contains(area.id) {
                                    selectedBodyAreas.remove(area.id)
                                } else {
                                    selectedBodyAreas.insert(area.id)
                                }
                            }) {
                                HStack {
                                    Text(area.emoji)
                                    Text(area.name)
                                        .font(.subheadline)
                                    
                                    if area.isSkinRelated {
                                        Text("кожа")
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedBodyAreas.contains(area.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedBodyAreas.contains(area.id) ? Color.medicationBlue : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .cardStyle()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle((editingSavedTemplate == nil && editingTempTemplateID == nil) ? "Новый шаблон" : "Изменить шаблон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        showAddTemplate = false
                        clearEditorState()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        handleSaveTemplate()
                    }
                    .fontWeight(.bold)
                    .disabled(newTemplateName.isEmpty || selectedBodyAreas.isEmpty)
                }
            }
        }
    }
    
    private func handleSaveTemplate() {
        if let tempID = editingTempTemplateID {
            // Update temp template
            if let index = tempTemplates.firstIndex(where: { $0.id == tempID }) {
                tempTemplates[index].name = newTemplateName
                tempTemplates[index].bodyAreaIDs = selectedBodyAreas
            }
        } else if let saved = editingSavedTemplate {
            // Update saved template
            saved.name = newTemplateName
            let selected = bodyAreas.filter { selectedBodyAreas.contains($0.id) }
            saved.bodyAreas = selected
            try? modelContext.save()
        } else {
            // New template
            if isNew {
                tempTemplates.append(TempTemplate(name: newTemplateName, bodyAreaIDs: selectedBodyAreas))
            } else {
                saveNewSavedTemplate()
            }
        }
        showAddTemplate = false
        clearEditorState()
    }
    
    private func saveNewSavedTemplate() {
        guard let med = medication else { return }
        let selected = bodyAreas.filter { selectedBodyAreas.contains($0.id) }
        let template = MedicationTemplate(
            name: newTemplateName,
            medication: med,
            bodyAreas: selected
        )
        modelContext.insert(template)
        try? modelContext.save()
    }
}
