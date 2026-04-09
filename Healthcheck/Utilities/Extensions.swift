import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }
    
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }
    
    var relativeString: String {
        if isToday {
            return "Сегодня, \(timeString)"
        } else if isYesterday {
            return "Вчера, \(timeString)"
        } else {
            return "\(shortDateString), \(timeString)"
        }
    }
    
    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
}

extension Array {
    func grouped<Key: Hashable>(by keyPath: (Element) -> Key) -> [Key: [Element]] {
        Dictionary(grouping: self, by: keyPath)
    }
}

import SwiftUI
import SwiftData

extension CGFloat {
    static let appHorizontalPadding: CGFloat = 16
    static let appSpacing: CGFloat = 20
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func dismissKeyboardOnTap() -> some View {
        self.modifier(DismissKeyboardOnTap())
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

// MARK: - Components


// MARK: - Native Emoji Keyboard Support
struct EmojiTextFieldNative: UIViewRepresentable {
    @Binding var text: String
    @Binding var isPresented: Bool
    var placeholder: String = ""
    
    func makeUIView(context: Context) -> EmojiUITextField {
        let textField = EmojiUITextField()
        textField.placeholder = placeholder
        textField.text = text
        textField.delegate = context.coordinator
        textField.textAlignment = .center
        return textField
    }
    
    func updateUIView(_ uiView: EmojiUITextField, context: Context) {
        uiView.text = text
        if isPresented {
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        } else {
            if uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextFieldNative
        
        init(parent: EmojiTextFieldNative) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText.count > 1 {
                // Keep only the last emoji
                parent.text = String(newText.last!)
                parent.isPresented = false
            } else {
                parent.text = newText
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isPresented = false
        }
    }
}

class EmojiUITextField: UITextField {
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }
}
struct LargeSelectableTile: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 28))
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 85) // Fixed height for grid stability
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? accentColor : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Shared Dictionary Fields
struct FoodItemFields: View {
    @Binding var name: String
    @Binding var emoji: String
    @Binding var dangerLevel: Int
    @Binding var isFavorite: Bool
    
    var body: some View {
        Group {
            Section {
                HStack(spacing: 16) {
                    EmojiPickerButton(emoji: $emoji)
                    
                    TextField("Название продукта", text: $name)
                        .font(.headline)
                }
                .padding(.vertical, 4)
                
                Toggle("Избранное", isOn: $isFavorite)
            } header: {
                Text("Основная информация")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Уровень опасности")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    DangerLevelPicker(selection: $dangerLevel)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Параметры")
            }
        }
    }
}

struct MedicationFields: View {
    @Binding var name: String
    @Binding var emoji: String
    
    var body: some View {
        Section {
            HStack(spacing: 16) {
                EmojiPickerButton(emoji: $emoji)
                
                TextField("Название лекарства", text: $name)
                    .font(.headline)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Основная информация")
        }
    }
}

struct BodyAreaFields: View {
    @Binding var name: String
    @Binding var emoji: String
    @Binding var isSkinRelated: Bool
    
    var body: some View {
        Group {
            Section {
                HStack(spacing: 16) {
                    EmojiPickerButton(emoji: $emoji)
                    
                    TextField("Название зоны", text: $name)
                        .font(.headline)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Основная информация")
            }
            
            Section {
                Toggle("Связана с кожей", isOn: $isSkinRelated)
            } header: {
                Text("Параметры")
            }
        }
    }
}

struct DangerLevelPicker: View {
    @Binding var selection: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { level in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = level
                    }
                }) {
                    Text("\(level)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selection == level ? Color.dangerColor(level) : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(selection == level ? .white : .primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selection == level ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct EmojiPickerButton: View {
    @Binding var emoji: String
    @State private var isPickerPresented = false
    
    var body: some View {
        Button(action: { isPickerPresented = true }) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor.opacity(0.1)))
                .overlay(Circle().stroke(Color.accentColor.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .overlay {
            EmojiTextFieldNative(text: $emoji, isPresented: $isPickerPresented)
                .frame(width: 0, height: 0)
                .opacity(0)
        }
    }
}

// MARK: - History Detail Views
struct FoodEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: FoodEntry
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Text(entry.foodItem?.emoji ?? "🍽")
                        .font(.system(size: 40))
                        .padding(8)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.foodItem?.name ?? "Продукт")
                            .font(.headline)
                        if let dangerLevel = entry.foodItem?.dangerLevel {
                            DangerBadge(level: dangerLevel)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Информация о продукте")
            }
            
            Section {
                DatePicker("Дата и время", selection: $entry.timestamp)
            } header: {
                Text("Время приема")
            }
            
            Section {
                TextEditor(text: $entry.note)
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if entry.note.isEmpty {
                            Text("Добавьте заметку...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            } header: {
                Text("Заметка")
            }
        }
        .navigationTitle("Детали записи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") { dismiss() }
            }
        }
    }
}

struct MedicationEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: MedicationEntry
    @Query(sort: \BodyArea.sortOrder) private var allBodyAreas: [BodyArea]
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Text(entry.medication?.emoji ?? "💊")
                        .font(.system(size: 40))
                        .padding(8)
                        .background(Color.medicationBlue.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.medication?.name ?? "Лекарство")
                            .font(.headline)
                        Text("Запись приема")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Лекарство")
            }
            
            Section {
                DatePicker("Дата и время", selection: $entry.timestamp)
            } header: {
                Text("Время приема")
            }
            
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(allBodyAreas) { area in
                        let isSelected = entry.bodyAreas.contains(where: { $0.id == area.id })
                        Button(action: {
                            if isSelected {
                                entry.bodyAreas.removeAll(where: { $0.id == area.id })
                            } else {
                                entry.bodyAreas.append(area)
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(area.emoji)
                                    .font(.title3)
                                Text(area.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.medicationBlue : Color(.tertiarySystemBackground))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Зоны применения")
            }
            
            Section {
                TextEditor(text: $entry.note)
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if entry.note.isEmpty {
                            Text("Добавьте заметку...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            } header: {
                Text("Заметка")
            }
        }
        .navigationTitle("Детали записи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") { dismiss() }
            }
        }
    }
}

struct RatingTransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let timestamp: Date
    let ratings: [BodyAreaRating]
    @State private var showEditSheet = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timestamp.fullDateString)
                        .font(.headline)
                    Text(timestamp.timeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Время оценки")
            }
            
            Section {
                ForEach(ratings) { rating in
                    HStack(spacing: 12) {
                        Text(rating.bodyArea?.emoji ?? "❓")
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rating.bodyArea?.name ?? "—")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if !rating.note.isEmpty {
                                Text(rating.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text(RatingLabel.emoji(for: rating.rating))
                            Text("\(rating.rating)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.ratingColor(rating.rating))
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Оценки по зонам (\(ratings.count))")
            }
        }
        .navigationTitle("Детали оценки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Изменить") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditRatingViewFromHistory(ratings: ratings, timestamp: timestamp)
        }
    }
}

struct EditRatingViewFromHistory: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let ratings: [BodyAreaRating]
    let timestamp: Date
    
    @State private var editedRatings: [UUID: Int] = [:]
    @State private var editedNotes: [UUID: String] = [:]
    @State private var editTimestamp: Date = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Time Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Время оценки")
                            .font(.headline)
                        DatePicker("Выберите время", selection: $editTimestamp)
                    }
                    .padding()
                    .cardStyle()
                    
                    ForEach(ratings) { rating in
                        VStack(spacing: 12) {
                            HStack {
                                Text(rating.bodyArea?.emoji ?? "❓")
                                    .font(.title2)
                                Text(rating.bodyArea?.name ?? "—")
                                    .font(.headline)
                                Spacer()
                                let current = editedRatings[rating.id] ?? rating.rating
                                Text(RatingLabel.emoji(for: current))
                                    .font(.title3)
                            }
                            
                            DangerLevelPicker(selection: Binding(
                                get: { editedRatings[rating.id] ?? rating.rating },
                                set: { editedRatings[rating.id] = $0 }
                            ))
                            
                            TextField("Заметка...", text: Binding(
                                get: { editedNotes[rating.id] ?? rating.note },
                                set: { editedNotes[rating.id] = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        .padding()
                        .cardStyle()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Изменить")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func save() {
        for rating in ratings {
            if let newValue = editedRatings[rating.id] {
                rating.rating = newValue
            }
            if let newNote = editedNotes[rating.id] {
                rating.note = newNote
            }
        }
        try? modelContext.save()
    }
}

