import SwiftUI
import SwiftData

public struct FoodLogView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \FoodItem.createdAt, order: .reverse)
    private var foodItems: [FoodItem]
    
    @Query(sort: \FoodEntry.timestamp, order: .reverse)
    private var foodEntries: [FoodEntry]
    
    @State private var showAddFood = false
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    
    var filteredItems: [FoodItem] {
        var items = foodItems
        if showFavoritesOnly {
            items = items.filter { $0.isFavorite }
        }
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return items
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Filter
                    HStack {
                        Button(action: { withAnimation { showFavoritesOnly.toggle() } }) {
                            Label(
                                showFavoritesOnly ? "Все" : "Избранное",
                                systemImage: showFavoritesOnly ? "star.fill" : "star"
                            )
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(showFavoritesOnly ? .yellow.opacity(0.2) : Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("\(foodEntries.filter { $0.timestamp.isToday }.count) записей сегодня")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Food Items
                    if filteredItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                            Text("Нет продуктов")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Добавьте первый продукт")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredItems) { item in
                                FoodItemRow(foodItem: item, onLog: { logFood(item) })
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent entries
                    recentEntriesSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Еда")
            .searchable(text: $searchText, prompt: "Искать продукт...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.foodRed)
                    }
                }
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodView()
            }
        }
    }
    
    // MARK: - Recent Entries
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Недавние записи")
                .font(.headline)
                .padding(.horizontal)
            
            let recent = foodEntries.prefix(10)
            
            if recent.isEmpty {
                Text("Пока нет записей")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(Array(recent)) { entry in
                    HStack(spacing: 12) {
                        Text(entry.foodItem?.emoji ?? "🍽")
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.foodItem?.name ?? "—")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(entry.timestamp.relativeString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let danger = entry.foodItem?.dangerLevel, danger > 1 {
                            DangerBadge(level: danger)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Log Food
    private func logFood(_ item: FoodItem) {
        let entry = FoodEntry(foodItem: item)
        modelContext.insert(entry)
        try? modelContext.save()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Danger Badge
public struct DangerBadge: View { public init() {}
    let level: Int
    
    public var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            Text("\(level)")
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.dangerColor(level).opacity(0.2))
        .foregroundStyle(Color.dangerColor(level))
        .clipShape(Capsule())
    }
}

#Preview {
    FoodLogView()
        .modelContainer(for: [FoodItem.self, FoodEntry.self], inMemory: true)
}
