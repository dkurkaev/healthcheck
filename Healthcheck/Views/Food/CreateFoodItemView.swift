import SwiftUI
import SwiftData

struct CreateFoodItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // If nil, we are creating a new item
    var food: FoodItem?
    
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    @State private var editDangerLevel: Int = 1
    @State private var editIsFavorite: Bool = false
    @State private var showDeleteConfirmation = false
    
    private var isNew: Bool { food == nil }
    
    var body: some View {
        if isNew {
            NavigationStack {
                editorContent
            }
        } else {
            editorContent
        }
    }
    
    private var editorContent: some View {
        List {
            FoodItemFields(
                name: $editName, 
                emoji: $editEmoji, 
                dangerLevel: $editDangerLevel, 
                isFavorite: $editIsFavorite
            )
            
            if let food = food {
                Section {
                    HStack {
                        Text("Записей")
                        Spacer()
                        Text("\(food.entries.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Удалить продукт", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle(isNew ? "Новый продукт" : (food?.name ?? "Правка"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(isNew ? "Отмена" : "Готово") {
                    dismiss()
                }
            }
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveFoodItem()
                    }
                    .fontWeight(.bold)
                    .disabled(editName.isEmpty)
                }
            }
        }
        .onAppear {
            if let f = food {
                editName = f.name
                editEmoji = f.emoji
                editDangerLevel = f.dangerLevel
                editIsFavorite = f.isFavorite
            } else {
                editEmoji = "🍎"
            }
        }
        .onDisappear {
            if !isNew {
                updateFoodItem()
            }
        }
        .alert("Удалить продукт?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                if let f = food {
                    modelContext.delete(f)
                    try? modelContext.save()
                    dismiss()
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Продукт \"\(editName)\" и все связанные записи будут удалены.")
        }
    }
    
    private func saveFoodItem() {
        let newItem = FoodItem(
            name: editName,
            emoji: editEmoji,
            isFavorite: editIsFavorite,
            dangerLevel: editDangerLevel
        )
        modelContext.insert(newItem)
        try? modelContext.save()
        dismiss()
    }
    
    private func updateFoodItem() {
        guard let f = food else { return }
        if !editName.isEmpty { f.name = editName }
        if !editEmoji.isEmpty { f.emoji = editEmoji }
        f.dangerLevel = editDangerLevel
        f.isFavorite = editIsFavorite
        try? modelContext.save()
    }
}
