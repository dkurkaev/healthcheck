import Foundation
import SwiftUI
import SwiftData

extension Date {
    public var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    public var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    public var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    public var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }
    
    public var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }
    
    public var relativeString: String {
        if isToday {
            return "Сегодня, \(timeString)"
        } else if isYesterday {
            return "Вчера, \(timeString)"
        } else {
            return "\(shortDateString), \(timeString)"
        }
    }
    
    public func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
}

extension Array {
    public func grouped<Key: Hashable>(by keyPath: (Element) -> Key) -> [Key: [Element]] {
        Dictionary(grouping: self, by: keyPath)
    }
}

extension CGFloat {
    public static let appHorizontalPadding: CGFloat = 16
    public static let appSpacing: CGFloat = 20
}

extension View {
    public func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    public func dismissKeyboardOnTap() -> some View {
        self.modifier(DismissKeyboardOnTap())
    }
}

public struct DismissKeyboardOnTap: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

// MARK: - Native Emoji Keyboard Support
public struct EmojiTextFieldNative: UIViewRepresentable {
    @Binding public var text: String
    @Binding public var isPresented: Bool
    public var placeholder: String = ""
    
    public init(text: Binding<String>, isPresented: Binding<Bool>, placeholder: String = "") {
        self._text = text
        self._isPresented = isPresented
        self.placeholder = placeholder
    }
    
    public func makeUIView(context: Context) -> EmojiUITextField {
        let textField = EmojiUITextField()
        textField.placeholder = placeholder
        textField.text = text
        textField.delegate = context.coordinator
        textField.textAlignment = .center
        return textField
    }
    
    public func updateUIView(_ uiView: EmojiUITextField, context: Context) {
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
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextFieldNative
        
        public init(parent: EmojiTextFieldNative) {
            self.parent = parent
        }
        
        public func textFieldDidChangeSelection(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText.count > 1 {
                parent.text = String(newText.last!)
                parent.isPresented = false
            } else {
                parent.text = newText
            }
        }
        
        public func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isPresented = false
        }
    }
}

public class EmojiUITextField: UITextField {
    public override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }
}

public struct StandardHeader: View {
    public let title: String
    public init(title: String) { self.title = title }
    
    public var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, .appHorizontalPadding + 8)
            .padding(.top, 18)
            .padding(.bottom, 2)
    }
}

public struct ActionButtonRow: View {
    public let title: String
    public let icon: String
    public let color: Color
    public let action: () -> Void
    
    public init(title: String, icon: String = "plus.circle.fill", color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    public var body: some View {
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

public struct FlowLayoutList: Layout {
    public var spacing: CGFloat = 6
    public init(spacing: CGFloat = 6) { self.spacing = spacing }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

public struct DangerLevelPicker: View {
    @Binding public var selection: Int
    public init(selection: Binding<Int>) { self._selection = selection }
    
    public var body: some View {
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

public struct TimelineRow: View {
    public let emoji: String
    public let title: String
    public let subtitle: String?
    public let time: String
    public let accentColor: Color
    
    public init(emoji: String, title: String, subtitle: String?, time: String, accentColor: Color) {
        self.emoji = emoji
        self.title = title
        self.subtitle = subtitle
        self.time = time
        self.accentColor = accentColor
    }
    
    public var body: some View {
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

public struct EmojiPickerButton: View {
    @Binding public var emoji: String
    @State private var isPickerPresented = false
    public init(emoji: Binding<String>) { self._emoji = emoji }
    
    public var body: some View {
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

public struct FoodEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable public var entry: FoodEntry
    public init(entry: FoodEntry) { self.entry = entry }
    
    public var body: some View {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.blue)
                }
            }
        }
    }
}

public struct MedicationEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable public var entry: MedicationEntry
    @Query(sort: \BodyArea.sortOrder) private var allBodyAreas: [BodyArea]
    public init(entry: MedicationEntry) { self.entry = entry }
    
    public var body: some View {
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
                    .fontWeight(.bold)
            }
        }
    }
}

public struct RatingTransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    public let timestamp: Date
    public let ratings: [BodyAreaRating]
    @State private var showEditSheet = false
    
    public init(timestamp: Date, ratings: [BodyAreaRating]) {
        self.timestamp = timestamp
        self.ratings = ratings
    }
    
    public var body: some View {
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

public struct SharedRatingsList: View {
    @Environment(\.modelContext) private var modelContext
    public let ratings: [BodyAreaRating]
    public var limit: Int? = nil
    
    public init(ratings: [BodyAreaRating], limit: Int? = nil) {
        self.ratings = ratings
        self.limit = limit
    }
    
    public var body: some View {
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

public struct RatingTransaction: Identifiable {
    public let id: String
    public let timestamp: Date
    public let ratings: [BodyAreaRating]
    
    public init(id: String, timestamp: Date, ratings: [BodyAreaRating]) {
        self.id = id
        self.timestamp = timestamp
        self.ratings = ratings
    }
}
