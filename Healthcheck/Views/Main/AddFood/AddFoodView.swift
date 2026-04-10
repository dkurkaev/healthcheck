import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \FoodItem.createdAt, order: .reverse)
    private var existingFoods: [FoodItem]
    
    @State private var searchText = ""
    @State private var showCreateNew = false
    
    var favorites: [FoodItem] {
        existingFoods.filter { $0.isFavorite }
    }
    
    var filteredSearch: [FoodItem] {
        if searchText.isEmpty { return [] }
        return existingFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Quick Search
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Поиск продукта...", text: $searchText)
                    }
                    
                    if !filteredSearch.isEmpty {
                        ForEach(filteredSearch.prefix(5)) { item in
                            Button(action: {
                                logExistingFood(item)
                            }) {
                                HStack {
                                    Text(item.emoji)
                                    Text(item.name)
                                        .font(.subheadline)
                                    Spacer()
                                    if item.isFavorite {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.yellow)
                                            .font(.caption)
                                    }
                                    DangerBadge(level: item.dangerLevel)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Быстрый выбор")
                }
                
                // Favorites tags
                if !favorites.isEmpty && searchText.isEmpty {
                    Section {
                        FlowLayoutList(spacing: 8) {
                            ForEach(favorites) { item in
                                Button(action: { logExistingFood(item) }) {
                                    HStack(spacing: 4) {
                                        Text(item.emoji)
                                        Text(item.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.dangerColor(item.dangerLevel).opacity(0.1))
                                    .foregroundStyle(Color.dangerColor(item.dangerLevel))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.dangerColor(item.dangerLevel).opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Избранное")
                    }
                }
                
                // Create new
                Section {
                    Button(action: { showCreateNew = true }) {
                        Label("Создать новый продукт", systemImage: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Добавить еду")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateNew) {
                CreateFoodItemInlineView(onSave: { dismiss() })
            }
        }
    }
    
    private func logExistingFood(_ item: FoodItem) {
        let entry = FoodEntry(foodItem: item)
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Create Food Item Inline (with "Сохранить в ленту" toggle)
struct CreateFoodItemInlineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var onSave: (() -> Void)? = nil
    
    @State private var name = ""
    @State private var emoji = "🍎"
    @State private var dangerLevel = 1
    @State private var isFavorite = false
    @State private var saveToFeed = true
    
    var body: some View {
        NavigationStack {
            Form {
                FoodItemFields(name: $name, emoji: $emoji, dangerLevel: $dangerLevel, isFavorite: $isFavorite)
                
                Section {
                    Toggle("Сохранить в ленту еды", isOn: $saveToFeed)
                } footer: {
                    Text(saveToFeed
                         ? "Продукт будет добавлен в справочник и записан в историю питания."
                         : "Продукт будет сохранён только в справочник без записи в историю.")
                }
            }
            .navigationTitle("Новый продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: saveFood)
                        .fontWeight(.bold)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveFood() {
        let food = FoodItem(
            name: name,
            emoji: emoji,
            isFavorite: isFavorite,
            dangerLevel: dangerLevel
        )
        modelContext.insert(food)
        
        if saveToFeed {
            let entry = FoodEntry(foodItem: food)
            modelContext.insert(entry)
        }
        
        try? modelContext.save()
        dismiss()
        onSave?()
    }
}
