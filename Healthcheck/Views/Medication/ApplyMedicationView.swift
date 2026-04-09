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
    @State private var selectedTemplate: MedicationTemplate?
    @State private var selectedBodyAreas: Set<UUID> = []
    @State private var comment = ""
    @State private var showSavedAnimation = false
    @State private var useManual = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Toggle (out of Form for better styling)
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
                        // Quick templates
                        Section {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(templates) { template in
                                    LargeSelectableTile(
                                        emoji: template.medication?.emoji ?? "💊",
                                        title: template.name,
                                        isSelected: selectedTemplate?.id == template.id,
                                        accentColor: .medicationBlue,
                                        action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedTemplate = template
                                                selectedMedication = template.medication
                                                if let areas = template.bodyAreas as? [BodyArea] {
                                                    selectedBodyAreas = Set(areas.map(\.id))
                                                } else {
                                                    selectedBodyAreas = Set(template.bodyAreas.map(\.id))
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                        } header: {
                            Text("Быстрые шаблоны")
                        }
                    } else {
                        // Manual Selection - Medication
                        Section {
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
                                                    selectedTemplate = nil
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        } header: {
                            Text("Лекарство")
                        }
                        
                        // Body Areas
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
                                        selectedTemplate = nil // Manual change breaks template link
                                    }) {
                                        HStack(spacing: 4) {
                                            Text(area.emoji)
                                            Text(area.name)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.medicationBlue.opacity(0.15) : Color.clear)
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
                            Text("Зоны применения")
                        }
                    }
                    
                    // Comment — always at the bottom
                    Section {
                        TextField("Дополнительная информация...", text: $comment, axis: .vertical)
                            .lineLimit(3...10)
                    } header: {
                        Text("Комментарий")
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
                    Button("Сохранить") {
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
