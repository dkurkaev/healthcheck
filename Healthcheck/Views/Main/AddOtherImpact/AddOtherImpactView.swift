import SwiftUI
import SwiftData

struct AddOtherImpactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \OtherImpact.createdAt, order: .reverse)
    private var existingImpacts: [OtherImpact]
    
    @State private var searchText = ""
    @State private var showCreateNew = false
    
    var favorites: [OtherImpact] {
        existingImpacts.filter { $0.isFavorite }
    }
    
    var filteredSearch: [OtherImpact] {
        if searchText.isEmpty { return [] }
        return existingImpacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Quick Search
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Поиск воздействия...", text: $searchText)
                    }
                    
                    if !filteredSearch.isEmpty {
                        ForEach(filteredSearch.prefix(5)) { item in
                            Button(action: {
                                logExistingImpact(item)
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
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Быстрый выбор")
                }
                
                // Favorites tags
                if !favorites.isEmpty && searchText.isEmpty {
                    Section {
                        FlowLayoutList(spacing: 8) {
                            ForEach(favorites) { item in
                                Button(action: { logExistingImpact(item) }) {
                                    HStack(spacing: 4) {
                                        Text(item.emoji)
                                        Text(item.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundStyle(Color.orange)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Избранное")
                    }
                }
                
                // Create new
                Section {
                    Button(action: { showCreateNew = true }) {
                        Label("Создать новое воздействие", systemImage: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Прочие воздействия")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateNew) {
                CreateOtherImpactInlineView(onSave: { dismiss() })
            }
        }
    }
    
    private func logExistingImpact(_ item: OtherImpact) {
        let entry = OtherImpactEntry(impact: item)
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Create Other Impact Inline
struct CreateOtherImpactInlineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var onSave: (() -> Void)? = nil
    
    @State private var name = ""
    @State private var emoji = "☀️"
    @State private var isFavorite = false
    @State private var saveToFeed = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    HStack(spacing: 16) {
                        EmojiPickerButton(emoji: $emoji)
                        TextField("Название", text: $name)
                            .font(.headline)
                    }
                    Toggle("Избранное", isOn: $isFavorite)
                }
                
                Section {
                    Toggle("Сохранить в ленту", isOn: $saveToFeed)
                } footer: {
                    Text(saveToFeed
                         ? "Воздействие будет добавлено в справочник и записано в историю."
                         : "Воздействие будет сохранено только в справочник.")
                }
            }
            .navigationTitle("Новое воздействие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .fontWeight(.bold)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let impact = OtherImpact(
            name: name,
            emoji: emoji,
            isFavorite: isFavorite
        )
        modelContext.insert(impact)
        
        if saveToFeed {
            let entry = OtherImpactEntry(impact: impact)
            modelContext.insert(entry)
        }
        
        try? modelContext.save()
        dismiss()
        onSave?()
    }
}
