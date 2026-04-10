import SwiftUI
import SwiftData

public struct BodyAreasView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    
    public init() {}
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Body Areas List
                    LazyVStack(spacing: 12) {
                        if bodyAreas.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "figure.stand")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                Text("Зоны не настроены")
                                    .font(.headline)
                                Text("Настройте зоны тела в меню Настройки")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 100)
                        } else {
                            ForEach(bodyAreas) { area in
                                NavigationLink(destination: BodyAreaDetailView(bodyArea: area)) {
                                    BodyAreaRow(bodyArea: area)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Зоны тела")
        }
    }
}

// MARK: - Body Area Row
public struct BodyAreaRow: View { public init() {}
    let bodyArea: BodyArea
    
    public var body: some View {
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
                        Text(rating.timestamp.relativeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
public struct RatingBadge: View { public init() {}
    let rating: Int
    
    public var body: some View {
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
