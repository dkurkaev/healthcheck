import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationFrequency") private var notificationFrequency = 1
    @AppStorage("notificationTime1") private var notificationTime1: Double = 72000 // 20:00 default
    @AppStorage("notificationTime2") private var notificationTime2: Double = 32400 // 09:00 default
    @AppStorage("notificationTime3") private var notificationTime3: Double = 54000 // 15:00 default
    
    var body: some View {
        NavigationStack {
            List {
                // Notifications Section
                Section {
                    Toggle("Напоминания", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                NotificationService.shared.requestPermission()
                                rescheduleNotifications()
                            } else {
                                NotificationService.shared.cancelAll()
                            }
                        }
                    
                    if notificationsEnabled {
                        Picker("Частота", selection: $notificationFrequency) {
                            Text("1 раз в день").tag(1)
                            Text("2 раза в день").tag(2)
                            Text("3 раза в день").tag(3)
                        }
                        .onChange(of: notificationFrequency) { _, _ in rescheduleNotifications() }
                        
                        DatePicker("Время 1", selection: timeBinding(for: $notificationTime1), displayedComponents: .hourAndMinute)
                            .onChange(of: notificationTime1) { _, _ in rescheduleNotifications() }
                        
                        if notificationFrequency >= 2 {
                            DatePicker("Время 2", selection: timeBinding(for: $notificationTime2), displayedComponents: .hourAndMinute)
                                .onChange(of: notificationTime2) { _, _ in rescheduleNotifications() }
                        }
                        
                        if notificationFrequency >= 3 {
                            DatePicker("Время 3", selection: timeBinding(for: $notificationTime3), displayedComponents: .hourAndMinute)
                                .onChange(of: notificationTime3) { _, _ in rescheduleNotifications() }
                        }
                    }
                } header: {
                    Text("Уведомления")
                } footer: {
                    Text(notificationsEnabled ? "Приложение будет напоминать вам оценить состояние здоровья в выбранное время" : "Напоминания отключены")
                }
                
                // Dictionaries Section
                Section {
                    NavigationLink(destination: MedicationListView()) {
                        Label("Управление лекарствами", systemImage: "pills.fill")
                    }
                    
                    NavigationLink(destination: FoodListView()) {
                        Label("Управление продуктами", systemImage: "fork.knife")
                    }
                    
                    NavigationLink(destination: BodyAreaListView()) {
                        Label("Управление зонами тела", systemImage: "figure.stand")
                    }
                } header: {
                    Text("Справочники")
                }
                
                // Data Section
                Section("Данные") {
                    NavigationLink(destination: DataManagementView()) {
                        Label("Управление данными", systemImage: "cylinder.split.1x2.fill")
                    }
                }
                
                // About Section
                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Платформа")
                        Spacer()
                        Text("iOS 17+")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
    
    // MARK: - Notification Helpers
    private func timeBinding(for storage: Binding<Double>) -> Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.hour, .minute], from: Date())
                components.hour = Int(storage.wrappedValue) / 3600
                components.minute = (Int(storage.wrappedValue) % 3600) / 60
                return calendar.date(from: components) ?? Date()
            },
            set: {
                let components = Calendar.current.dateComponents([.hour, .minute], from: $0)
                storage.wrappedValue = Double((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60)
            }
        )
    }
    
    private func rescheduleNotifications() {
        guard notificationsEnabled else { return }
        
        var times: [(hour: Int, minute: Int)] = []
        times.append((hour: Int(notificationTime1) / 3600, minute: (Int(notificationTime1) % 3600) / 60))
        
        if notificationFrequency >= 2 {
            times.append((hour: Int(notificationTime2) / 3600, minute: (Int(notificationTime2) % 3600) / 60))
        }
        
        if notificationFrequency >= 3 {
            times.append((hour: Int(notificationTime3) / 3600, minute: (Int(notificationTime3) % 3600) / 60))
        }
        
        NotificationService.shared.scheduleHealthRating(at: times)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [
            BodyArea.self, BodyAreaRating.self,
            FoodItem.self, FoodEntry.self,
            Medication.self, MedicationTemplate.self, MedicationEntry.self
        ], inMemory: true)
}
