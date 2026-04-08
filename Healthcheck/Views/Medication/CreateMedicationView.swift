import SwiftUI
import SwiftData

struct CreateMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var emoji = "💊"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Новое лекарство") {
                    HStack {
                        Text("Эмоджи")
                        Spacer()
                        TextField("💊", text: $emoji)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                    }
                    
                    TextField("Название лекарства", text: $name)
                }
            }
            .navigationTitle("Создать лекарство")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveMedication()
                    }
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveMedication() {
        let medication = Medication(
            name: name,
            emoji: emoji
        )
        modelContext.insert(medication)
        try? modelContext.save()
        dismiss()
    }
}
