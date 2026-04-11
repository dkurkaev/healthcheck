import SwiftUI
import SwiftData

struct FoodItemEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var food: FoodItem?
    
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    @State private var editDangerLevel: Int = 1
    @State private var editIsFavorite: Bool = false
    @State private var editType: FoodType = .food
    @State private var showDeleteConfirmation = false
    
    @State private var originalName: String = ""
    @State private var originalEmoji: String = ""
    @State private var originalDangerLevel: Int = 1
    @State private var originalIsFavorite: Bool = false
    @State private var originalType: FoodType = .food
    
    private var isNew: Bool { food == nil }
    
    private var hasChanges: Bool {
        editName != originalName ||
        editEmoji != originalEmoji ||
        editDangerLevel != originalDangerLevel ||
        editIsFavorite != originalIsFavorite ||
        editType != originalType
    }
    
    var body: some View {
        Group {
            if isNew {
                NavigationStack {
                    editorContent
                }
            } else {
                editorContent
            }
        }
    }
    
    private var editorContent: some View {
        List {
            FoodItemFields(
                name: $editName,
                emoji: $editEmoji,
                dangerLevel: $editDangerLevel,
                isFavorite: $editIsFavorite,
                type: $editType
            )
            
            if food != nil {
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
        .listStyle(.insetGrouped)
        .navigationTitle(isNew ? "Новый продукт" : (food?.name ?? "Правка"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                let canSave = !editName.isEmpty && (isNew || hasChanges)
                
                Button("Сохранить") {
                    if isNew {
                        saveFoodItem()
                    } else {
                        updateFoodItem()
                        dismiss()
                    }
                }
                .fontWeight(.bold)
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let f = food {
                editName = f.name
                editEmoji = f.emoji
                editDangerLevel = f.dangerLevel
                editIsFavorite = f.isFavorite
                editType = f.type
                originalName = f.name
                originalEmoji = f.emoji
                originalDangerLevel = f.dangerLevel
                originalIsFavorite = f.isFavorite
                originalType = f.type
            } else {
                editEmoji = "🍎"
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
            dangerLevel: editDangerLevel,
            type: editType
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
        f.type = editType
        try? modelContext.save()
    }
}

// MARK: - Food Item Fields Component
struct FoodItemFields: View {
    @Binding var name: String
    @Binding var emoji: String
    @Binding var dangerLevel: Int
    @Binding var isFavorite: Bool
    @Binding var type: FoodType
    
    var body: some View {
        Section("Основная информация") {
            HStack(spacing: 16) {
                EmojiPickerButton(emoji: $emoji)
                
                TextField("Название продукта", text: $name)
                    .font(.headline)
            }
            
            Toggle("Избранное", isOn: $isFavorite)
            
            Picker("Тип", selection: $type) {
                ForEach(FoodType.allCases, id: \.self) { type in
                    Text(type.localizedName).tag(type)
                }
            }
        }
        
        Section("Параметры") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Уровень опасности")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                DangerLevelPicker(selection: $dangerLevel)
            }
            .padding(.vertical, 4)
        }
    }
}
