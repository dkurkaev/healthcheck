import SwiftUI
import SwiftData

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Medication.createdAt, order: .reverse)
    private var medications: [Medication]
    
    @Query(sort: \MedicationTemplate.createdAt, order: .reverse)
    private var templates: [MedicationTemplate]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var selectedMedication: Medication?
    @State private var selectedTemplate: MedicationTemplate?
    @State private var selectedBodyAreas: Set<UUID> = []
    @State private var comment = ""
    @State private var showSavedAnimation = false
    @State private var useManual = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !templates.isEmpty {
                    Picker("Режим", selection: $useManual) {
                        Text("Шаблоны").tag(false)
                        Text("Вручную").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .onChange(of: useManual) { _, _ in
                        selectedTemplate = nil
                        selectedMedication = nil
                        selectedBodyAreas = []
                    }
                }
                
                Form {
                    if !useManual && !templates.isEmpty {
                        SelectionTilePanel(
                            title: "Быстрые шаблоны",
                            items: templates,
                            selectedID: selectedTemplate?.id,
                            emojiProvider: { $0.medication?.emoji ?? "💊" },
                            titleProvider: { $0.name },
                            accentColor: .medicationBlue
                        ) { template in
                            selectedTemplate = template
                            selectedMedication = template.medication
                            selectedBodyAreas = Set(template.bodyAreas.map(\.id))
                            saveEntry()
                        }
                    } else {
                        SelectionTilePanel(
                            title: "Лекарство",
                            items: medications,
                            selectedID: selectedMedication?.id,
                            emojiProvider: { $0.emoji },
                            titleProvider: { $0.name },
                            accentColor: .medicationBlue
                        ) { med in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMedication = med
                                selectedTemplate = nil
                            }
                        }
                        
                        Section("Зоны применения") {
                            BodyAreaSelector(bodyAreas: bodyAreas, selectedBodyAreas: $selectedBodyAreas)
                                .onChange(of: selectedBodyAreas) { _, _ in
                                    selectedTemplate = nil
                                }
                        }
                    }
                    
                    if useManual {
                        Section("Комментарий") {
                            TextField("Дополнительная информация...", text: $comment, axis: .vertical)
                                .lineLimit(3...10)
                        }
                    }
                }
            }
            .navigationTitle("Применить лекарство")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if useManual {
                        let canSave = selectedMedication != nil && !selectedBodyAreas.isEmpty
                        Button("Готово", action: saveEntry)
                            .fontWeight(.bold)
                            .disabled(!canSave)
                    }
                }
            }
            .overlay {
                if showSavedAnimation {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        Text("Записано!")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(40)
                    .background(.ultraThickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let medication = selectedMedication else { return }
        let selectedAreas = bodyAreas.filter { selectedBodyAreas.contains($0.id) }
        
        let finalNote: String
        if let template = selectedTemplate {
            finalNote = comment.isEmpty ? "Шаблон: \(template.name)" : comment
        } else {
            finalNote = comment
        }
        
        let entry = MedicationEntry(
            note: finalNote,
            medication: medication,
            bodyAreas: selectedAreas
        )
        modelContext.insert(entry)
        try? modelContext.save()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSavedAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}
