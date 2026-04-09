import SwiftUI
import SwiftData

struct MedicationTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Medication.createdAt, order: .reverse)
    private var medications: [Medication]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var name = ""
    @State private var selectedMedication: Medication?
    @State private var selectedBodyAreas: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            Form {
                // Template Name
                Section {
                    TextField("Например: Увлажняющий крем", text: $name)
                } header: {
                    Text("Название шаблона")
                }
                
                // Select Medication
                Section {
                    if medications.isEmpty {
                        Text("Сначала добавьте лекарства в настройках")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(medications) { med in
                            Button(action: { 
                                withAnimation {
                                    selectedMedication = med 
                                }
                            }) {
                                HStack {
                                    Text(med.emoji)
                                    Text(med.name)
                                    Spacer()
                                    if selectedMedication?.id == med.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Лекарство")
                }
                
                // Select Body Areas
                Section {
                    FlowLayout(spacing: 8) {
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
                                .background(isSelected ? Color.medicationBlue.opacity(0.1) : Color.clear)
                                .foregroundStyle(isSelected ? .medicationBlue : .primary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.medicationBlue : Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack {
                        Text("Зоны применения")
                        Spacer()
                        Button(action: toggleAllSkin) {
                            Text(isAllSkinSelected ? "Снять все" : "Вся кожа")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .textCase(.none)
                        }
                    }
                }
            }
            .navigationTitle("Новый шаблон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveTemplate()
                    }
                    .fontWeight(.bold)
                    .disabled(name.isEmpty || selectedMedication == nil || selectedBodyAreas.isEmpty)
                }
            }
        }
    }
    
    private var isAllSkinSelected: Bool {
        let skinAreas = bodyAreas.filter { $0.isSkinRelated }
        return !skinAreas.isEmpty && skinAreas.allSatisfy { selectedBodyAreas.contains($0.id) }
    }
    
    private func toggleAllSkin() {
        if isAllSkinSelected {
            selectedBodyAreas.removeAll()
        } else {
            let skinAreas = bodyAreas.filter { $0.isSkinRelated }
            selectedBodyAreas = Set(skinAreas.map(\.id))
        }
    }
    
    private func saveTemplate() {
        let selected = bodyAreas.filter { selectedBodyAreas.contains($0.id) }
        let template = MedicationTemplate(
            name: name,
            medication: selectedMedication,
            bodyAreas: selected
        )
        modelContext.insert(template)
        try? modelContext.save()
        dismiss()
    }
}
