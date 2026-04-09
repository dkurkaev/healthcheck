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
                
                // Medications Section
                Section {
                    NavigationLink(destination: MedicationManagementView()) {
                        Label("Управление лекарствами", systemImage: "pills.fill")
                    }
                    
                    NavigationLink(destination: FoodManagementView()) {
                        Label("Управление продуктами", systemImage: "fork.knife")
                    }
                    
                    NavigationLink(destination: BodyAreaManagementView()) {
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
        
        // Time 1
        times.append((hour: Int(notificationTime1) / 3600, minute: (Int(notificationTime1) % 3600) / 60))
        
        // Time 2
        if notificationFrequency >= 2 {
            times.append((hour: Int(notificationTime2) / 3600, minute: (Int(notificationTime2) % 3600) / 60))
        }
        
        // Time 3
        if notificationFrequency >= 3 {
            times.append((hour: Int(notificationTime3) / 3600, minute: (Int(notificationTime3) % 3600) / 60))
        }
        
        NotificationService.shared.scheduleHealthRating(at: times)
    }
}

// MARK: - Medication Management View
struct MedicationManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Medication.createdAt, order: .reverse)
    private var medications: [Medication]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var showAddMedication = false
    
    var body: some View {
        List {
            if medications.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "pills.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("Нет лекарств")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Нажмите + чтобы добавить первое лекарство")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            
            ForEach(medications) { medication in
                NavigationLink(destination: MedicationEditView(medication: medication)) {
                    HStack(spacing: 12) {
                        Text(medication.emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color.medicationBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(medication.name)
                                .font(.headline)
                            
                            let templateCount = medication.templates.count
                            let entryCount = medication.entries.count
                            Text("\(templateCount) шаблонов · \(entryCount) применений")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(medication)
                        try? modelContext.save()
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Лекарства")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddMedication = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.medicationBlue)
                }
            }
        }
        .sheet(isPresented: $showAddMedication) {
            CreateMedicationView()
        }
    }
}

// MARK: - Medication Edit View
struct MedicationEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var medication: Medication
    var isNew: Bool = false
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var showAddTemplate = false
    @State private var newTemplateName = ""
    @State private var selectedBodyAreas: Set<UUID> = []
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    @State private var isDiscarding = false
    
    var body: some View {
        List {
            // Information Section
            MedicationFields(name: $editName, emoji: $editEmoji)
            
            if !isNew {
                Section {
                    HStack {
                        Text("Применений")
                        Spacer()
                        Text("\(medication.entries.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Templates Section
            Section {
                ForEach(medication.templates) { template in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(template.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if !template.bodyAreas.isEmpty {
                            FlowLayoutList {
                                ForEach(template.bodyAreas) { area in
                                    Text("\(area.emoji) \(area.name)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.medicationBlue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(template)
                            try? modelContext.save()
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
                
                Button(action: { showAddTemplate = true }) {
                    Label("Добавить шаблон", systemImage: "plus.circle")
                        .foregroundStyle(Color.medicationBlue)
                }
            } header: {
                Text("Шаблоны применения")
            } footer: {
                Text("Шаблоны связывают лекарство с зонами тела для быстрого применения")
            }
        }
        .navigationTitle(isNew ? "Новое лекарство" : medication.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        isDiscarding = true
                        modelContext.delete(medication)
                        try? modelContext.save()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveAndClose()
                    }
                    .fontWeight(.bold)
                    .disabled(editName.isEmpty)
                }
            }
        }
        .onAppear {
            editName = medication.name
            editEmoji = medication.emoji
        }
        .onDisappear {
            if !isDiscarding {
                saveAndClose()
            }
        }
        .sheet(isPresented: $showAddTemplate) {
            addTemplateSheet
        }
    }
    
    private func saveAndClose() {
        if !editName.isEmpty { medication.name = editName }
        if !editEmoji.isEmpty { medication.emoji = editEmoji }
        try? modelContext.save()
        if isNew { dismiss() }
    }
    
    // MARK: - Add Template Sheet
    private var addTemplateSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Например: На всю кожу", text: $newTemplateName)
                } header: {
                    Text("Название шаблона")
                }
                
                Section {
                    FlowLayout(spacing: 8) {
                        ForEach(bodyAreas) { area in
                            let isSelected = selectedBodyAreas.contains(area.id)
                            Button(action: {
                                if isSelected {
                                    selectedBodyAreas.remove(area.id)
                                } else {
                                    selectedBodyAreas.insert(area.id)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(area.emoji)
                                    Text(area.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.medicationBlue.opacity(0.15) : Color.clear)
                                .foregroundStyle(isSelected ? .medicationBlue : .primary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.medicationBlue : Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack {
                        Text("Зоны применения")
                        Spacer()
                        Button(action: {
                            let skinAreas = bodyAreas.filter { $0.isSkinRelated }
                            let allSelected = !skinAreas.isEmpty && skinAreas.allSatisfy { selectedBodyAreas.contains($0.id) }
                            if allSelected {
                                selectedBodyAreas.removeAll()
                            } else {
                                selectedBodyAreas = Set(skinAreas.map(\.id))
                            }
                        }) {
                            let skinAreas = bodyAreas.filter { $0.isSkinRelated }
                            let allSelected = !skinAreas.isEmpty && skinAreas.allSatisfy { selectedBodyAreas.contains($0.id) }
                            Text(allSelected ? "Снять все" : "Вся кожа")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .textCase(.none)
                        }
                    }
                }
            }
            .navigationTitle("Новый шаблон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        showAddTemplate = false
                        newTemplateName = ""
                        selectedBodyAreas = []
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveTemplate()
                    }
                    .fontWeight(.bold)
                    .disabled(newTemplateName.isEmpty || selectedBodyAreas.isEmpty)
                }
            }
        }
    }
    
    private func saveTemplate() {
        let selected = bodyAreas.filter { selectedBodyAreas.contains($0.id) }
        let template = MedicationTemplate(
            name: newTemplateName,
            medication: medication,
            bodyAreas: selected
        )
        modelContext.insert(template)
        try? modelContext.save()
        showAddTemplate = false
        newTemplateName = ""
        selectedBodyAreas = []
    }
}

// MARK: - Flow Layout for List (simplified)
struct FlowLayoutList: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
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

// MARK: - Food Management View
struct FoodManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \FoodItem.createdAt, order: .reverse)
    private var foodItems: [FoodItem]
    
    @State private var showAddFood = false
    
    var body: some View {
        List {
            if foodItems.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("Нет продуктов")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            
            ForEach(foodItems) { food in
                NavigationLink(destination: CreateFoodItemView(food: food)) {
                    HStack(spacing: 12) {
                        Text(food.emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color.dangerColor(food.dangerLevel).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(food.name)
                                    .font(.headline)
                                
                                if food.isFavorite {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }
                            
                            HStack(spacing: 6) {
                                DangerBadge(level: food.dangerLevel)
                                Text("\(food.entries.count) записей")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(food)
                        try? modelContext.save()
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
        .navigationTitle("Продукты")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddFood = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.foodRed)
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            CreateFoodItemView()
        }
    }
}

// MARK: - Body Area Management View
struct BodyAreaManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var showAddArea = false
    @State private var newAreaName = ""
    @State private var newAreaEmoji = "🔵"
    @State private var newAreaIsSkin = false
    
    var body: some View {
        List {
            ForEach(bodyAreas) { area in
                NavigationLink(destination: BodyAreaEditView(bodyArea: area)) {
                    HStack(spacing: 12) {
                        Text(area.emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(area.name)
                                .font(.headline)
                            
                            HStack(spacing: 4) {
                                if area.isSkinRelated {
                                    Text("🧴 Кожа")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                                
                                Text("\(area.ratings.count) оценок")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(area)
                        try? modelContext.save()
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
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
            CreateBodyAreaView()
        }
    }
}

// MARK: - Body Area Creation View
struct CreateBodyAreaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var name = ""
    @State private var emoji = "🔵"
    @State private var isSkinRelated = false
    
    var body: some View {
        NavigationStack {
            Form {
                BodyAreaFields(name: $name, emoji: $emoji, isSkinRelated: $isSkinRelated)
            }
            .navigationTitle("Новая зона тела")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveArea()
                    }
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveArea() {
        let area = BodyArea(
            name: name,
            emoji: emoji,
            isSkinRelated: isSkinRelated,
            sortOrder: bodyAreas.count
        )
        modelContext.insert(area)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Body Area Edit View
struct BodyAreaEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var bodyArea: BodyArea
    
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    @State private var editIsSkin: Bool = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            BodyAreaFields(name: $editName, emoji: $editEmoji, isSkinRelated: $editIsSkin)
            
            Section {
                HStack {
                    Text("Оценок")
                    Spacer()
                    Text("\(bodyArea.ratings.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Шаблонов лекарств")
                    Spacer()
                    Text("\(bodyArea.medicationTemplates.count)")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Удалить зону", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(bodyArea.name)
        .onAppear {
            editName = bodyArea.name
            editEmoji = bodyArea.emoji
            editIsSkin = bodyArea.isSkinRelated
        }
        .onDisappear {
            if !editName.isEmpty { bodyArea.name = editName }
            if !editEmoji.isEmpty { bodyArea.emoji = editEmoji }
            bodyArea.isSkinRelated = editIsSkin
            try? modelContext.save()
        }
        .alert("Удалить зону?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                modelContext.delete(bodyArea)
                try? modelContext.save()
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Зона \"\(bodyArea.name)\" и все связанные оценки будут удалены.")
        }
    }
}

// MARK: - Data Management View
struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            Section {
                Button(action: {
                    DataSeeder.seedDefaultBodyAreas(context: modelContext)
                }) {
                    Label("Восстановить зоны по умолчанию", systemImage: "arrow.counterclockwise")
                }
            } footer: {
                Text("Добавит стандартные зоны тела, если они были удалены")
            }
            
            Section {
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Label("Удалить все данные", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            } footer: {
                Text("Это действие нельзя отменить. Все записи будут удалены безвозвратно.")
            }
        }
        .navigationTitle("Управление данными")
        .alert("Удалить все данные?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                deleteAllData()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все записи о еде, лекарствах и оценках здоровья будут удалены безвозвратно.")
        }
    }
    
    private func deleteAllData() {
        try? modelContext.delete(model: BodyAreaRating.self)
        try? modelContext.delete(model: FoodEntry.self)
        try? modelContext.delete(model: MedicationEntry.self)
        try? modelContext.delete(model: MedicationTemplate.self)
        try? modelContext.delete(model: FoodItem.self)
        try? modelContext.delete(model: Medication.self)
        try? modelContext.delete(model: BodyArea.self)
        try? modelContext.save()
    }
}

// MARK: - Native Dictionary Views


#Preview {
    SettingsView()
        .modelContainer(for: [
            BodyArea.self, BodyAreaRating.self,
            FoodItem.self, FoodEntry.self,
            Medication.self, MedicationTemplate.self, MedicationEntry.self
        ], inMemory: true)
}

// MARK: - Reusable Components


