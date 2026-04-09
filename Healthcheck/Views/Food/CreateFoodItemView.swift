import SwiftUI
import SwiftData

struct CreateFoodItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var food: FoodItem?
    
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    @State private var editDangerLevel: Int = 1
    @State private var editIsFavorite: Bool = false
    @State private var showDeleteConfirmation = false
    
    @State private var originalName: String = ""
    @State private var originalEmoji: String = ""
    @State private var originalDangerLevel: Int = 1
    @State private var originalIsFavorite: Bool = false
    
    private var isNew: Bool { food == nil }
    
    private var hasChanges: Bool {
        editName != originalName ||
        editEmoji != originalEmoji ||
        editDangerLevel != originalDangerLevel ||
        editIsFavorite != originalIsFavorite
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
                isFavorite: $editIsFavorite
            )
            
            if let food = food {
                StandardHeader(title: "Статистика")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
                
                HStack {
                    Text("Записей")
                    Spacer()
                    Text("\(food.entries.count)")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .cardStyle()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: .appHorizontalPadding, bottom: 8, trailing: .appHorizontalPadding))
                
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Label("Удалить продукт", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding()
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 20, leading: .appHorizontalPadding, bottom: 40, trailing: .appHorizontalPadding))
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isNew ? "Новый продукт" : (food?.name ?? "Правка"))
                    .font(.headline)
            }
            
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveFoodItem()
                    }
                    .fontWeight(.bold)
                    .disabled(editName.isEmpty)
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        updateFoodItem()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!hasChanges || editName.isEmpty)
                }
            }
        }
        .onAppear {
            if let f = food {
                editName = f.name
                editEmoji = f.emoji
                editDangerLevel = f.dangerLevel
                editIsFavorite = f.isFavorite
                // Snapshot for change detection
                originalName = f.name
                originalEmoji = f.emoji
                originalDangerLevel = f.dangerLevel
                originalIsFavorite = f.isFavorite
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
