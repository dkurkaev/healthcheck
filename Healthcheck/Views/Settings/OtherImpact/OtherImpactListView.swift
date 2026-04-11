import SwiftUI
import SwiftData

struct OtherImpactListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \OtherImpact.sortOrder)
    private var impacts: [OtherImpact]
    
    @State private var showAdd = false
    
    var body: some View {
        AppEditableList(items: impacts, emptyView: {
            VStack(spacing: 12) {
                Image(systemName: "sun.max.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text("Нет воздействий")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }) { impact in
            NavigationLink(destination: OtherImpactEditorView(impact: impact)) {
                HStack(spacing: 12) {
                    Text(impact.emoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(impact.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            if impact.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        
                        Text("\(impact.entries.count) записей")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Прочие воздействия")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            OtherImpactEditorView()
        }
    }
}
