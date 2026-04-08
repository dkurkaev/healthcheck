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
    @State private var selectAllSkin = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Template Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название шаблона")
                            .font(.headline)
                        
                        TextField("Например: Увлажняющий крем на всю кожу", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .cardStyle()
                    
                    // Select Medication
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Лекарство")
                            .font(.headline)
                        
                        if medications.isEmpty {
                            Text("Сначала добавьте лекарства")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(medications) { med in
                                Button(action: { selectedMedication = med }) {
                                    HStack {
                                        Text(med.emoji)
                                            .font(.title3)
                                        Text(med.name)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        if selectedMedication?.id == med.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.medicationBlue)
                                        }
                                    }
                                    .padding(10)
                                    .background(
                                        selectedMedication?.id == med.id
                                            ? Color.medicationBlue.opacity(0.1)
                                            : Color(.tertiarySystemBackground)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // Select Body Areas
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Зоны тела")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                selectAllSkin.toggle()
                                if selectAllSkin {
                                    let skinAreas = bodyAreas.filter { $0.isSkinRelated }
                                    selectedBodyAreas = Set(skinAreas.map(\.id))
                                } else {
                                    selectedBodyAreas.removeAll()
                                }
                            }) {
                                Text(selectAllSkin ? "Снять все" : "Вся кожа")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(selectAllSkin ? Color.medicationBlue : Color(.tertiarySystemBackground))
                                    .foregroundStyle(selectAllSkin ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        FlowLayout(spacing: 8) {
                            ForEach(bodyAreas) { area in
                                Button(action: {
                                    if selectedBodyAreas.contains(area.id) {
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
                                    .background(
                                        selectedBodyAreas.contains(area.id)
                                            ? Color.medicationBlue.opacity(0.2)
                                            : Color(.tertiarySystemBackground)
                                    )
                                    .foregroundStyle(selectedBodyAreas.contains(area.id) ? .medicationBlue : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedBodyAreas.contains(area.id) ? Color.medicationBlue : Color.clear,
                                                lineWidth: 1
                                            )
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
