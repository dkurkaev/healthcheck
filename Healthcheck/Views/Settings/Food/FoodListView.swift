import SwiftUI
import SwiftData

struct FoodListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \FoodItem.sortOrder)
    private var foodItems: [FoodItem]
    
    @State private var showAddFood = false
    
    var body: some View {
        AppEditableList(items: foodItems, emptyView: {
            VStack(spacing: 12) {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text("Нет продуктов")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }) { food in
            NavigationLink(destination: FoodItemEditorView(food: food)) {
                HStack(spacing: 12) {
                    Text(food.emoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.dangerColor(food.dangerLevel).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(food.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            if food.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        
                        HStack(spacing: 6) {
                            DangerBadge(level: food.dangerLevel)
                            Text("\(food.entries.count) записей")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Продукты")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddFood = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            FoodItemEditorView()
        }
    }
}
