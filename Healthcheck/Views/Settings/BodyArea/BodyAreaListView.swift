import SwiftUI
import SwiftData

struct BodyAreaListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyArea.sortOrder) private var bodyAreas: [BodyArea]
    @State private var showAddArea = false
    
    var body: some View {
        AppEditableList(items: bodyAreas, emptyView: {
            VStack(spacing: 12) {
                Image(systemName: "figure.walk.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text("Нет зон тела")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }) { area in
            NavigationLink(destination: BodyAreaEditorView(area: area)) {
                HStack(spacing: 12) {
                    Text(area.emoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(area.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if area.isSkinRelated {
                            Text("Связано с кожей")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Зоны тела")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddArea = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddArea) {
            BodyAreaEditorView()
        }
    }
}
