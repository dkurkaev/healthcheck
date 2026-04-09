import SwiftUI
import SwiftData

struct CreateMedicationView: View {
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
    
    struct TempTemplate: Identifiable, Equatable {
        let id = UUID()
        var name: String
        var bodyAreaIDs: Set<UUID>
    }
    
    enum ActiveTemplateSheet: Identifiable {
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
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isNew ? "Новое лекарство" : (medication?.name ?? "Правка"))
                    .font(.headline)
            }
            
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if isNew {
                    Button("Создать") { saveNewMedication() }
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
        .sheet(item: $activeSheet) { sheet in
            TemplateEditorSheet(
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
    
    // MARK: - Sub-views (Required for compiler performance)
    
    @ViewBuilder
    private var mainInfoSection: some View {
        // Headers are now DIRECT elements of the List for color consistency
        StandardHeader(title: "Основная информация")
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
        
        MedicationFields(name: $editName, emoji: $editEmoji)
            .padding()
            .cardStyle()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: .appHorizontalPadding, bottom: 8, trailing: .appHorizontalPadding))
        
        if let med = medication {
            StandardHeader(title: "Статистика")
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
            
            HStack {
                Text("Применений")
                Spacer()
                Text("\(med.entries.count)")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .cardStyle()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: .appHorizontalPadding, bottom: 8, trailing: .appHorizontalPadding))
        }
    }
    
    @ViewBuilder
    private var templatesSection: some View {
        StandardHeader(title: "Шаблоны применения")
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 8, trailing: 0))
        
        if isNew {
            ForEach(tempTemplates) { template in
                templateCard(name: template.name, areaIDs: template.bodyAreaIDs) {
                    activeSheet = .editTemp(template)
                } deleteAction: {
                    tempTemplates.removeAll { $0.id == template.id }
                }
            }
        } else if let med = medication {
            ForEach(med.templates) { template in
                templateCard(name: template.name, areaIDs: Set(template.bodyAreas.map(\.id))) {
                    activeSheet = .editSaved(template)
                } deleteAction: {
                    modelContext.delete(template)
                    try? modelContext.save()
                }
            }
        }
    }
    
    @ViewBuilder
    private var actionsSection: some View {
        ActionButtonRow(title: "Добавить шаблон", color: .medicationBlue) {
            activeSheet = .new
        }
        .padding()
        .cardStyle()
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: .appHorizontalPadding, bottom: 8, trailing: .appHorizontalPadding))
        
        Text("Шаблоны связывают лекарство с зонами тела для быстрого применения")
            .font(.caption)
            .foregroundStyle(.secondary)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: .appHorizontalPadding, bottom: 20, trailing: .appHorizontalPadding))

        if !isNew {
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
    
    private func templateCard(name: String, areaIDs: Set<UUID>, action: @escaping () -> Void, deleteAction: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
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
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: .appHorizontalPadding, bottom: 4, trailing: .appHorizontalPadding))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteAction() } label: { Label("Удалить", systemImage: "trash") }
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

// MARK: - Dedicated Template Editor Sheet
struct TemplateEditorSheet: View {
    let mode: CreateMedicationView.ActiveTemplateSheet
    let bodyAreas: [BodyArea]
    let isParentNew: Bool
    let onSave: (MedicationTemplate?, CreateMedicationView.TempTemplate?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedBodyAreas: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Например: На всю кожу", text: $name)
                        .font(.headline)
                } header: {
                    StandardHeader(title: "Название шаблона")
                        .padding(.leading, -20)
                }
                
                Section {
                    HStack {
                        Text("Зоны тела")
                        Spacer()
                        Button(action: toggleSkin) {
                            Text(isAllSkinSelected ? "Снять все" : "Вся кожа")
                                .font(.caption).fontWeight(.bold)
                        }
                    }
                    
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
                } header: {
                    StandardHeader(title: "Зоны применения")
                        .padding(.leading, -20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        handleSave()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(name.isEmpty || selectedBodyAreas.isEmpty)
                }
            }
            .onAppear(perform: setup)
        }
    }
    
    private var title: String {
        if case .new = mode { return "Новый шаблон" }
        return "Изменить шаблон"
    }
    
    private var isAllSkinSelected: Bool {
        let skinAreas = bodyAreas.filter { $0.isSkinRelated }
        return !skinAreas.isEmpty && skinAreas.allSatisfy { selectedBodyAreas.contains($0.id) }
    }
    
    private func toggleSkin() {
        if isAllSkinSelected {
            selectedBodyAreas.removeAll()
        } else {
            let skinAreas = bodyAreas.filter { $0.isSkinRelated }
            selectedBodyAreas.formUnion(skinAreas.map(\.id))
        }
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
            let temp = CreateMedicationView.TempTemplate(name: name, bodyAreaIDs: selectedBodyAreas)
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
