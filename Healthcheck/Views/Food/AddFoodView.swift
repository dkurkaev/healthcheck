import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \FoodItem.createdAt, order: .reverse)
    private var existingFoods: [FoodItem]
    
    @State private var name = ""
    @State private var emoji = "🍽"
    @State private var dangerLevel = 1
    @State private var isFavorite = false
    @State private var logImmediately = true
    @State private var searchText = ""
    @State private var selectedExisting: FoodItem?
    
    var filteredExisting: [FoodItem] {
        if searchText.isEmpty { return [] }
        return existingFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Quick Search Existing
                Section {
                    AppTextField(title: "Поиск существующих...", text: $searchText, icon: "magnifyingglass")
                    
                    if !filteredExisting.isEmpty {
                        ForEach(filteredExisting.prefix(5)) { item in
                            Button(action: {
                                selectedExisting = item
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
                
                // New Food Form - Shared Pattern
                FoodItemFields(name: $name, emoji: $emoji, dangerLevel: $dangerLevel, isFavorite: $isFavorite)
                
                Section {
                    Toggle(isOn: $logImmediately) {
                        Label {
                            Text("Записать сразу")
                        } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("Действие")
                } footer: {
                    Text("Если включено, продукт будет не только создан, но и сразу добавлен в ваш журнал")
                }
            }
            .navigationTitle("Добавить еду")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveFood()
                    }
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
        
        if logImmediately {
            let entry = FoodEntry(foodItem: food)
            modelContext.insert(entry)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func logExistingFood(_ item: FoodItem) {
        let entry = FoodEntry(foodItem: item)
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}
