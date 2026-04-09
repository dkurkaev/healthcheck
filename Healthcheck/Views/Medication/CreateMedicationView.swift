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
    
    // Snapshots for template change detection
    @State private var originalTemplateName = ""
    @State private var originalTemplateBodyAreas: Set<UUID> = []
    
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
            // Medication Fields Section
            VStack(alignment: .leading, spacing: 8) {
                Text("ОСНОВНАЯ ИНФОРМАЦИЯ")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                MedicationFields(name: $editName, emoji: $editEmoji)
                    .padding()
                    .cardStyle()
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: .appHorizontalPadding, bottom: 8, trailing: .appHorizontalPadding))
            
            if let med = medication {
                // Statistics Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("СТАТИСТИКА")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text("Применений")
                        Spacer()
                        Text("\(med.entries.count)")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .cardStyle()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: .appHorizontalPadding, bottom: 8, trailing: .appHorizontalPadding))
            }
            
            // Templates Header
            Text("ШАБЛОНЫ ПРИМЕНЕНИЯ")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: .appHorizontalPadding, bottom: 8, trailing: .appHorizontalPadding))
            
            if isNew {
                // Show temp templates
                ForEach(tempTemplates) { template in
                    Button(action: { prepareEditTemp(template) }) {
                        templateRow(name: template.name, areaIDs: template.bodyAreaIDs)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            tempTemplates.removeAll { $0.id == template.id }
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: .appHorizontalPadding, bottom: 4, trailing: .appHorizontalPadding))
            } else if let med = medication {
                // Show saved templates
                ForEach(med.templates) { template in
                    Button(action: { prepareEditSaved(template) }) {
                        templateRow(name: template.name, areaIDs: Set(template.bodyAreas.map(\.id)))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(template)
                            try? modelContext.save()
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: .appHorizontalPadding, bottom: 4, trailing: .appHorizontalPadding))
            }
            
            // Add Template Button as a Card
            ActionButtonCard(title: "Добавить шаблон", icon: "plus.circle.fill", color: .medicationBlue) {
                clearEditorState()
                showAddTemplate = true 
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: .appHorizontalPadding, bottom: 8, trailing: .appHorizontalPadding))
            
            // Footer Info
            Text("Шаблоны связывают лекарство с зонами тела для быстрого применения")
                .font(.caption)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: .appHorizontalPadding, bottom: 20, trailing: .appHorizontalPadding))

            if !isNew {
                // Delete Section
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Label("Удалить лекарство", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding()
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 20, leading: .appHorizontalPadding, bottom: 40, trailing: .appHorizontalPadding))
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isNew ? "Новое лекарство" : (medication?.name ?? "Правка"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if isNew {
                    Button("Создать") {
                        saveNewMedication()
                    }
                    .fontWeight(.bold)
                    .disabled(editName.isEmpty)
                } else {
                    let hasChanges = medication?.name != editName || medication?.emoji != editEmoji
                    Button("Сохранить") {
                        updateMedication()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!hasChanges || editName.isEmpty)
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
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.medicationBlue.opacity(0.1))
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
    
    private func clearEditorState() {
        newTemplateName = ""
        selectedBodyAreas = []
        originalTemplateName = ""
        originalTemplateBodyAreas = []
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
        clearEditorState()
        
        newTemplateName = template.name
        
        // Ensure areas are loaded and mapped correctly
        let areas = Array(template.bodyAreas)
        let ids = Set(areas.map(\.id))
        selectedBodyAreas = ids
        
        // Snapshot for change detection
        originalTemplateName = template.name
        originalTemplateBodyAreas = ids
        
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("НАЗВАНИЕ ШАБЛОНА")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        TextField("Например: На всю кожу", text: $newTemplateName)
                            .font(.headline)
                            .padding()
                            .cardStyle()
                    }
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("ЗОНЫ ТЕЛА")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(action: {
                                let skinAreas = bodyAreas.filter { $0.isSkinRelated }
                                let skinAreaIDs = Set(skinAreas.map(\.id))
                                if skinAreaIDs.isSubset(of: selectedBodyAreas) && !skinAreaIDs.isEmpty {
                                    selectedBodyAreas.subtract(skinAreaIDs)
                                } else {
                                    selectedBodyAreas.formUnion(skinAreaIDs)
                                }
                            }) {
                                let skinAreas = bodyAreas.filter { $0.isSkinRelated }
                                let skinAreaIDs = Set(skinAreas.map(\.id))
                                let allSkinSelected = !skinAreaIDs.isEmpty && skinAreaIDs.isSubset(of: selectedBodyAreas)
                                Text(allSkinSelected ? "Снять все" : "Вся кожа")
                                    .font(.caption2)
                                    .foregroundStyle(Color.medicationBlue)
                            }
                            .buttonStyle(.plain)
                        }
                        
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
                                    }
                                    .font(.footnote)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.medicationBlue.opacity(0.12) : Color(.tertiarySystemGroupedBackground))
                                    .foregroundStyle(isSelected ? Color.medicationBlue : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.medicationBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
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
                    let hasTemplateChanges = newTemplateName != originalTemplateName || selectedBodyAreas != originalTemplateBodyAreas
                    Button("Сохранить") {
                        handleSaveTemplate()
                    }
                    .fontWeight(.bold)
                    .disabled(newTemplateName.isEmpty || selectedBodyAreas.isEmpty || (editingSavedTemplate != nil && !hasTemplateChanges))
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
