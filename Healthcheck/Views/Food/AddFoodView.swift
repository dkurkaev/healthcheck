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
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Search Existing
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Быстрый выбор")
                            .font(.headline)
                        
                        AppTextField(title: "Поиск существующих...", text: $searchText, icon: "magnifyingglass")
                        
                        if !filteredExisting.isEmpty {
                            LazyVStack(spacing: 6) {
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
                                        .padding(10)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // Divider
                    HStack {
                        VStack { Divider() }
                        Text("или создать новый")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        VStack { Divider() }
                    }
                    
                    // New Food Form
                    VStack(spacing: 16) {
                        // Emoji Picker (simplified)
                        Text(emoji)
                            .font(.system(size: 60))
                            .frame(maxWidth: .infinity)
                        
                        // Common food emojis
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["🍽", "🥗", "🍕", "🍔", "🍣", "🥩", "🍳", "🥛", "🧀", "🍞", "🍎", "🍌", "🥕", "🍫", "🍰", "☕️", "🍺", "🥤", "🍷", "🧃"], id: \.self) { e in
                                    Button(action: { emoji = e }) {
                                        Text(e)
                                            .font(.title2)
                                            .padding(8)
                                            .background(emoji == e ? Color.accentColor.opacity(0.2) : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        AppTextField(title: "Название продукта", text: $name, icon: "text.cursor")
                        
                        // Danger Level
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Уровень опасности")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text(DangerLabel.text(for: dangerLevel))
                                    .font(.caption)
                                    .foregroundStyle(Color.dangerColor(dangerLevel))
                            }
                            
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            dangerLevel = level
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: level <= dangerLevel ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                                                .font(.title3)
                                            Text("\(level)")
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(level <= dangerLevel ? Color.dangerColor(level).opacity(0.2) : Color(.tertiarySystemBackground))
                                        )
                                        .foregroundStyle(level <= dangerLevel ? Color.dangerColor(level) : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Favorite
                        Toggle(isOn: $isFavorite) {
                            Label("Добавить в избранное", systemImage: isFavorite ? "star.fill" : "star")
                                .foregroundStyle(isFavorite ? .yellow : .primary)
                        }
                        
                        // Log immediately
                        Toggle(isOn: $logImmediately) {
                            Label("Записать сразу", systemImage: "clock.arrow.circlepath")
                        }
                    }
                    .padding()
                    .cardStyle()
                }
                .padding()
                .contentShape(Rectangle())
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
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
