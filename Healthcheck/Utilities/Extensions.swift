import Foundation
import SwiftUI

extension Date {
    private enum Formatters {
        static let time: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f
        }()
        
        static let short: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "d MMM"
            f.locale = Locale(identifier: "ru_RU")
            return f
        }()
        
        static let full: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "d MMMM yyyy"
            f.locale = Locale(identifier: "ru_RU")
            return f
        }()
    }
    
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    
    var timeString: String { Formatters.time.string(from: self) }
    var shortDateString: String { Formatters.short.string(from: self) }
    var fullDateString: String { Formatters.full.string(from: self) }
    
    var relativeString: String {
        if isToday { return "Сегодня, \(timeString)" }
        else if isYesterday { return "Вчера, \(timeString)" }
        else { return "\(shortDateString), \(timeString)" }
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
        content.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Native UIKit helpers
class EmojiUITextField: UITextField {
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" { return mode }
        }
        return super.textInputMode
    }
}

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
        if isPresented { if !uiView.isFirstResponder { uiView.becomeFirstResponder() } }
        else { if uiView.isFirstResponder { uiView.resignFirstResponder() } }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextFieldNative
        init(parent: EmojiTextFieldNative) { self.parent = parent }
        func textFieldDidChangeSelection(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText.count > 1 { parent.text = String(newText.last!); parent.isPresented = false }
            else { parent.text = newText }
        }
        func textFieldDidEndEditing(_ textField: UITextField) { parent.isPresented = false }
    }
}
