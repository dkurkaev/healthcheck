import SwiftUI
import SwiftData

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var emoji = "💊"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Emoji
                    Text(emoji)
                        .font(.system(size: 70))
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                    
                    // Emoji picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["💊", "💉", "🧴", "🏥", "🩹", "🧪", "🫧", "🧫", "💧", "🌿", "🍯", "🫠", "🧊", "☀️", "🩺"], id: \.self) { e in
                                Button(action: { emoji = e }) {
                                    Text(e)
                                        .font(.title2)
                                        .padding(8)
                                        .background(emoji == e ? Color.medicationBlue.opacity(0.2) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Name
                    AppTextField(title: "Название лекарства", text: $name, icon: "pills.fill")
                        .padding(.horizontal)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Новое лекарство")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: saveMedication)
                        .fontWeight(.bold)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveMedication() {
        let medication = Medication(name: name, emoji: emoji)
        modelContext.insert(medication)
        try? modelContext.save()
        dismiss()
    }
}
