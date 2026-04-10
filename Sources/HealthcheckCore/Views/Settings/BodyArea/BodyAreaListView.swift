import SwiftUI
import SwiftData

public struct BodyAreaListView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyArea.sortOrder) private var bodyAreas: [BodyArea]
    @State private var showAddArea = false
    
    public var body: some View {
        List {
            if bodyAreas.isEmpty {
                Section {
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
                }
            }
            
            ForEach(bodyAreas) { area in
                ZStack {
                    NavigationLink(destination: BodyAreaEditorView(area: area)) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    HStack(spacing: 12) {
                        Text(area.emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(area.name)
                                .font(.headline)
                            if area.isSkinRelated {
                                Text("Связано с кожей")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "line.3.horizontal")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .cardStyle()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
            }
            .onMove(perform: moveAreas)
        }
        .listStyle(.plain)
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
        .sheet(isPresented: $showAddArea) {
            BodyAreaEditorView()
        }
    }
    
    private func moveAreas(from source: IndexSet, to destination: Int) {
        var revisedItems = bodyAreas
        revisedItems.move(fromOffsets: source, toOffset: destination)
        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].sortOrder = reverseIndex
        }
        try? modelContext.save()
    }
}
