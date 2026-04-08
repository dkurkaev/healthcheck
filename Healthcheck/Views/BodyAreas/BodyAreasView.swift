import SwiftUI
import SwiftData

struct BodyAreasView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var showAddArea = false
    @State private var showRateHealth = false
    @State private var newAreaName = ""
    @State private var newAreaEmoji = "🔵"
    @State private var newAreaIsSkin = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Rate All Button
                    Button(action: { showRateHealth = true }) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title2)
                            Text("Оценить все зоны")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    
                    // Body Areas List
                    LazyVStack(spacing: 12) {
                        ForEach(bodyAreas) { area in
                            NavigationLink(destination: BodyAreaDetailView(bodyArea: area)) {
                                BodyAreaRow(bodyArea: area)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Зоны тела")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddArea = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showRateHealth) {
                RateHealthView()
            }
            .alert("Новая зона тела", isPresented: $showAddArea) {
                TextField("Название", text: $newAreaName)
                TextField("Эмоджи", text: $newAreaEmoji)
                Toggle("Связана с кожей", isOn: $newAreaIsSkin)
                
                Button("Добавить") {
                    addArea()
                }
                Button("Отмена", role: .cancel) {
                    newAreaName = ""
                    newAreaEmoji = "🔵"
                    newAreaIsSkin = false
                }
            }
        }
    }
    
    private func addArea() {
        guard !newAreaName.isEmpty else { return }
        let area = BodyArea(
            name: newAreaName,
            emoji: newAreaEmoji,
            isSkinRelated: newAreaIsSkin,
            sortOrder: bodyAreas.count
        )
        modelContext.insert(area)
        newAreaName = ""
        newAreaEmoji = "🔵"
        newAreaIsSkin = false
    }
}

// MARK: - Body Area Row
struct BodyAreaRow: View {
    let bodyArea: BodyArea
    
    var body: some View {
        HStack(spacing: 14) {
            Text(bodyArea.emoji)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bodyArea.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    if bodyArea.isSkinRelated {
                        Label("Кожа", systemImage: "hand.raised.fill")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                    
                    if let rating = bodyArea.latestRating {
                        Text("\(RatingLabel.emoji(for: rating.rating)) \(RatingLabel.text(for: rating.rating))")
                            .font(.caption)
                            .foregroundStyle(Color.ratingColor(rating.rating))
                    }
                }
            }
            
            Spacer()
            
            if let rating = bodyArea.latestRating {
                RatingBadge(rating: rating.rating)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Rating Badge
struct RatingBadge: View {
    let rating: Int
    
    var body: some View {
        Text("\(rating)")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Color.ratingColor(rating))
            .clipShape(Circle())
    }
}

#Preview {
    BodyAreasView()
        .modelContainer(for: [BodyArea.self, BodyAreaRating.self], inMemory: true)
}
