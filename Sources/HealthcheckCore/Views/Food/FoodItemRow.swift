import SwiftUI
import SwiftData

public struct FoodItemRow: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    let foodItem: FoodItem
    let onLog: () -> Void
    
    public var body: some View {
        HStack(spacing: 14) {
            // Emoji
            Text(foodItem.emoji)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(Color.dangerColor(foodItem.dangerLevel).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(foodItem.name)
                        .font(.headline)
                    
                    if foodItem.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                
                HStack(spacing: 6) {
                    DangerBadge(level: foodItem.dangerLevel)
                    
                    Text("\(foodItem.entries.count) записей")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Quick Log Button
            Button(action: onLog) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.foodRed)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .cardStyle()
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(foodItem)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
            
            Button {
                foodItem.isFavorite.toggle()
                try? modelContext.save()
            } label: {
                Label(
                    foodItem.isFavorite ? "Убрать" : "В избранное",
                    systemImage: foodItem.isFavorite ? "star.slash" : "star.fill"
                )
            }
        }
    }
}
