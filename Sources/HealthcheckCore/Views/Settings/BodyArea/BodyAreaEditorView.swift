import SwiftUI
import SwiftData

public struct BodyAreaEditorView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var area: BodyArea? // If nil, we are creating
    
    @State private var name: String = ""
    @State private var emoji: String = "📍"
    @State private var isSkinRelated: Bool = true
    @State private var showDeleteConfirmation = false
    
    private var isNew: Bool { area == nil }
    
    public var body: some View {
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
                
                TextField("Название зоны", text: $name)
                    .font(.headline)
            }
        }
        
        Section("Параметры") {
            Toggle("Связана с кожей", isOn: $isSkinRelated)
        }

            if !isNew {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Удалить зону", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(isNew ? "Новая зона" : (area?.name ?? "Правка"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                let hasChanges = isNew || area?.name != name || area?.emoji != emoji
                let canSave = !name.isEmpty && hasChanges
                
                Button("Готово") {
                    save()
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let area = area {
                name = area.name
                emoji = area.emoji
                isSkinRelated = area.isSkinRelated
            }
        }
        .alert("Удалить зону?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                if let area = area {
                    modelContext.delete(area)
                    try? modelContext.save()
                    dismiss()
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Зона \"\(name)\" и все связанные оценки будут удалены.")
        }
    }
    
    private func save() {
        if let area = area {
            area.name = name
            area.emoji = emoji
            area.isSkinRelated = isSkinRelated
        } else {
            let newArea = BodyArea(name: name, emoji: emoji, isSkinRelated: isSkinRelated)
            modelContext.insert(newArea)
        }
        try? modelContext.save()
    }
}
