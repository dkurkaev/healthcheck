import SwiftUI
import SwiftData

struct CreateFoodItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var emoji = "🍎"
    @State private var dangerLevel = 1
    @State private var isFavorite = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    HStack {
                        Text("Эмоджи")
                        Spacer()
                        TextField("🍎", text: $emoji)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                    }
                    
                    TextField("Название продукта", text: $name)
                }
                
                Section("Параметры") {
                    Picker("Уровень опасности", selection: $dangerLevel) {
                        ForEach(1...5, id: \.self) { level in
                            Text(DangerLabel.text(for: level)).tag(level)
                        }
                    }
                    
                    Toggle("В избранном", isOn: $isFavorite)
                }
            }
            .navigationTitle("Новый продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveFoodItem()
                    }
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveFoodItem() {
        let food = FoodItem(
            name: name,
            emoji: emoji,
            isFavorite: isFavorite,
            dangerLevel: dangerLevel
        )
        modelContext.insert(food)
        try? modelContext.save()
        dismiss()
    }
}
