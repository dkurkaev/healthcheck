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

struct ActionButtonRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String = "plus.circle.fill", color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        HStack(spacing: 16) {
            EmojiPickerButton(emoji: $emoji)
            
            TextField("Название лекарства", text: $name)
                .font(.headline)
        }
        .padding(.vertical, 4)
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

// MARK: - Timeline Row
struct TimelineRow: View {
    let emoji: String
    let title: String
    let subtitle: String?
    let time: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                HStack(spacing: 8) {
                    Text(timestamp.fullDateString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(timestamp.timeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
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
    @State private var editTimestamp: Date
    
    init(ratings: [BodyAreaRating], timestamp: Date) {
        self.ratings = ratings
        self.timestamp = timestamp
        _editTimestamp = State(initialValue: timestamp)
    }
    
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
                            
                            // Rating selector with correct colors (1=red, 5=green)
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { value in
                                    let currentValue = editedRatings[rating.id] ?? rating.rating
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            editedRatings[rating.id] = value
                                        }
                                    }) {
                                        Text("\(value)")
                                            .font(.headline)
                                            .fontWeight(currentValue == value ? .bold : .regular)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(currentValue == value ? Color.ratingColor(value) : Color(.tertiarySystemBackground))
                                            )
                                            .foregroundStyle(currentValue == value ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
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


// MARK: - Shared Ratings Components
struct RatingTransaction: Identifiable {
    let id: String
    let timestamp: Date
    let ratings: [BodyAreaRating]
}

struct SharedRatingsList: View {
    @Environment(\.modelContext) private var modelContext
    let ratings: [BodyAreaRating]
    var limit: Int? = nil
    
    var body: some View {
        let transactions = groupRatingsIntoTransactions(ratings)
        let displayList = limit != nil ? Array(transactions.prefix(limit!)) : transactions
        
        ForEach(displayList, id: \.id) { transaction in
            let ratings = transaction.ratings
            let avgRating = ratings.isEmpty ? 0 : Int((Double(ratings.map(\.rating).reduce(0, +)) / Double(ratings.count)).rounded())
            
            ZStack {
                NavigationLink(destination: RatingTransactionDetailView(timestamp: transaction.timestamp, ratings: ratings)) {
                    EmptyView()
                }
                .opacity(0)
                
                TimelineRow(
                    emoji: RatingLabel.emoji(for: avgRating),
                    title: "Оценка здоровья",
                    subtitle: "\(ratings.count) зон · \(RatingLabel.text(for: avgRating))",
                    time: transaction.timestamp.relativeString,
                    accentColor: Color.ratingColor(avgRating)
                )
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    ratings.forEach { modelContext.delete($0) }
                    try? modelContext.save()
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
                .tint(.red)
            }
        }
    }
    
    private func groupRatingsIntoTransactions(_ ratings: [BodyAreaRating]) -> [RatingTransaction] {
        let grouped = Dictionary(grouping: ratings) { rating -> String in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: rating.timestamp)
            return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)-\(components.minute ?? 0)"
        }
        return grouped.map { key, ratings in
            RatingTransaction(
                id: key,
                timestamp: ratings.first?.timestamp ?? Date(),
                ratings: ratings.sorted { ($0.bodyArea?.sortOrder ?? 0) < ($1.bodyArea?.sortOrder ?? 0) }
            )
        }.sorted { $0.timestamp > $1.timestamp }
    }
}
