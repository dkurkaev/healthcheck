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
struct AppTextField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }
            
            TextField(title, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

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
                    .shadow(color: isSelected ? accentColor.opacity(0.3) : Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.secondary.opacity(0.1), lineWidth: 1)
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
                                .fill(selection == level ? Color.dangerColor(level) : Color(.tertiarySystemBackground))
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
