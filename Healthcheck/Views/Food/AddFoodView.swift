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
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Поиск существующих...", text: $searchText)
                    }
                    
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
                
                // More compact Divider
                HStack {
                    VStack { Divider() }
                    Text("или создать новый")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    VStack { Divider() }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                
                FoodItemFields(name: $name, emoji: $emoji, dangerLevel: $dangerLevel, isFavorite: $isFavorite)
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
        
        let entry = FoodEntry(foodItem: food)
        modelContext.insert(entry)
        
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
