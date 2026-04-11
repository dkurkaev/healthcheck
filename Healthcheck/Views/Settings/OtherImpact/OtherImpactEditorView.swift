import SwiftUI
import SwiftData

struct OtherImpactEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var impact: OtherImpact?
    
    @State private var name: String = ""
    @State private var emoji: String = "☀️"
    @State private var isFavorite: Bool = false
    @State private var showDeleteConfirmation = false
    
    private var isNew: Bool { impact == nil }
    
    var body: some View {
        Group {
            if isNew {
                NavigationStack {
                    editorContent
                }
            } else {
                editorContent
            }
        }
    }
    
    private var editorContent: some View {
        List {
            Section("Основная информация") {
                HStack(spacing: 16) {
                    EmojiPickerButton(emoji: $emoji)
                    
                    TextField("Название воздействия", text: $name)
                        .font(.headline)
                }
                
                Toggle("Избранное", isOn: $isFavorite)
            }
            
            if impact != nil {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Удалить воздействие", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(isNew ? "Новое воздействие" : (impact?.name ?? "Правка"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    save()
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            if let imp = impact {
                name = imp.name
                emoji = imp.emoji
                isFavorite = imp.isFavorite
            }
        }
        .alert("Удалить воздействие?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                if let imp = impact {
                    modelContext.delete(imp)
                    try? modelContext.save()
                    dismiss()
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Воздействие \"\(name)\" и все связанные записи будут удалены.")
        }
    }
    
    private func save() {
        if let imp = impact {
            imp.name = name
            imp.emoji = emoji
            imp.isFavorite = isFavorite
        } else {
            let newImp = OtherImpact(name: name, emoji: emoji, isFavorite: isFavorite)
            modelContext.insert(newImp)
        }
        try? modelContext.save()
    }
}
