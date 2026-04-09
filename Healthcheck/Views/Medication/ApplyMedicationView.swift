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
    @State private var comment = ""
    @State private var showSavedAnimation = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Quick templates
                if !templates.isEmpty {
                    Section {
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
                        .padding(.vertical, 8)
                    } header: {
                        Text("Быстрые шаблоны")
                    }
                    
                    // Divider row
                    Section {
                        HStack {
                            VStack { Divider() }
                            Text("или вручную")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .lineLimit(1)
                                .fixedSize()
                            VStack { Divider() }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                
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
                
                // Comment
                Section {
                    TextField("Дополнительная информация...", text: $comment, axis: .vertical)
                        .lineLimit(3...10)
                } header: {
                    Text("Комментарий")
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
    
    private func saveEntry() {
        let selected = bodyAreas.filter { selectedBodyAreas.contains($0.id) }
        let entry = MedicationEntry(
            note: comment,
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
