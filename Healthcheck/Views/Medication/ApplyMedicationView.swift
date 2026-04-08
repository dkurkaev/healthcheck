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
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Быстрые шаблоны")
                                .font(.headline)
                            
                            ForEach(templates) { template in
                                Button(action: { applyTemplate(template) }) {
                                    HStack {
                                        Image(systemName: "rectangle.stack.fill")
                                            .foregroundStyle(.medicationBlue)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Text("\(template.medication?.emoji ?? "💊") → \(template.bodyAreas.map(\.name).joined(separator: ", "))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundStyle(.medicationBlue)
                                    }
                                    .padding()
                                    .background(Color.medicationBlue.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.medicationBlue.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
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
                            Text("Сначала добавьте лекарства")
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(medications) { med in
                                        Button(action: { selectedMedication = med }) {
                                            VStack(spacing: 6) {
                                                Text(med.emoji)
                                                    .font(.title2)
                                                Text(med.name)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 80, height: 70)
                                            .background(
                                                selectedMedication?.id == med.id
                                                    ? Color.medicationBlue.opacity(0.2)
                                                    : Color(.tertiarySystemBackground)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        selectedMedication?.id == med.id ? Color.medicationBlue : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
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
                        
                        TextField("Дополнительная информация...", text: $note)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .cardStyle()
                }
                .padding()
            }
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
