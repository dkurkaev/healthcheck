import SwiftUI
import SwiftData

struct ApplyMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Medication.createdAt, order: .reverse)
    private var medications: [Medication]
    
    @Query(sort: \MedicationTemplate.createdAt, order: .reverse)
    private var templates: [MedicationTemplate]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var selectedMedication: Medication?
    @State private var selectedBodyAreas: Set<UUID> = []
    @State private var note = ""
    @State private var showSavedAnimation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick templates
                    if !templates.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Быстрые шаблоны")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(templates) { template in
                                    LargeSelectableTile(
                                        emoji: template.medication?.emoji ?? "💊",
                                        title: template.name,
                                        isSelected: false,
                                        accentColor: .medicationBlue,
                                        action: {
                                            withAnimation {
                                                applyTemplate(template)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                        .cardStyle()
                        
                        // Divider
                        HStack {
                            VStack { Divider() }
                            Text("или вручную")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            VStack { Divider() }
                        }
                    }
                    
                    // Manual Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Лекарство")
                            .font(.headline)
                        
                        if medications.isEmpty {
                            Text("Сначала добавьте лекарства в настройках")
                                .foregroundStyle(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(medications) { med in
                                    LargeSelectableTile(
                                        emoji: med.emoji,
                                        title: med.name,
                                        isSelected: selectedMedication?.id == med.id,
                                        accentColor: .medicationBlue,
                                        action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedMedication = med
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // Body Areas
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Зоны применения")
                            .font(.headline)
                        
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
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Заметка")
                            .font(.headline)
                        
                        AppTextField(title: "Дополнительная информация...", text: $note, icon: "note.text")
                    }
                    .padding()
                    .cardStyle()
                }
                .padding()
                .contentShape(Rectangle())
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Применить лекарство")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Записать") {
                        saveEntry()
                    }
                    .fontWeight(.bold)
                    .disabled(selectedMedication == nil || selectedBodyAreas.isEmpty)
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
    
    // MARK: - Apply Template
    private func applyTemplate(_ template: MedicationTemplate) {
        guard let medication = template.medication else { return }
        
        let entry = MedicationEntry(
            note: "Шаблон: \(template.name)",
            medication: medication,
            bodyAreas: template.bodyAreas
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
    
    // MARK: - Save Entry
    private func saveEntry() {
        let selected = bodyAreas.filter { selectedBodyAreas.contains($0.id) }
        let entry = MedicationEntry(
            note: note,
            medication: selectedMedication,
            bodyAreas: selected
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
