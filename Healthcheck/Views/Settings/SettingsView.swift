import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("notificationFrequency") private var notificationFrequency = 1
    @AppStorage("hasRequestedNotifications") private var hasRequestedNotifications = false
    
    var body: some View {
        NavigationStack {
            List {
                // Notifications Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Частота напоминаний")
                            .font(.subheadline)
                        
                        Picker("Частота", selection: $notificationFrequency) {
                            Text("1 раз в день (вечер)").tag(1)
                            Text("2 раза в день").tag(2)
                            Text("3 раза в день").tag(3)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: notificationFrequency) { _, newValue in
                            NotificationService.shared.scheduleHealthRating(timesPerDay: newValue)
                        }
                    }
                    
                    if !hasRequestedNotifications {
                        Button(action: {
                            NotificationService.shared.requestPermission()
                            hasRequestedNotifications = true
                            NotificationService.shared.scheduleHealthRating(timesPerDay: notificationFrequency)
                        }) {
                            Label("Включить уведомления", systemImage: "bell.badge.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("Уведомления")
                } footer: {
                    Text("Приложение будет напоминать вам оценить состояние здоровья")
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
            ScrollView {
                VStack(spacing: 20) {
                    // Template Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название шаблона")
                            .font(.headline)
                        
                        AppTextField(title: "Например: На всю кожу", text: $newTemplateName, icon: "text.quote")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Body Areas
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Зоны тела")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                let skinAreas = bodyAreas.filter { $0.isSkinRelated }
                                if selectedBodyAreas == Set(skinAreas.map(\.id)) {
                                    selectedBodyAreas.removeAll()
                                } else {
                                    selectedBodyAreas = Set(skinAreas.map(\.id))
                                }
                            }) {
                                let allSkinSelected = Set(bodyAreas.filter(\.isSkinRelated).map(\.id)).isSubset(of: selectedBodyAreas) && !bodyAreas.filter(\.isSkinRelated).isEmpty
                                Text(allSkinSelected ? "Снять все" : "Вся кожа")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(allSkinSelected ? Color.medicationBlue : Color(.tertiarySystemBackground))
                                    .foregroundStyle(allSkinSelected ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        ForEach(bodyAreas) { area in
                            Button(action: {
                                if selectedBodyAreas.contains(area.id) {
                                    selectedBodyAreas.remove(area.id)
                                } else {
                                    selectedBodyAreas.insert(area.id)
                                }
                            }) {
                                HStack {
                                    Text(area.emoji)
                                    Text(area.name)
                                        .font(.subheadline)
                                    
                                    if area.isSkinRelated {
                                        Text("кожа")
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedBodyAreas.contains(area.id)
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                        .foregroundStyle(selectedBodyAreas.contains(area.id) ? Color.medicationBlue : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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
                NavigationLink(destination: FoodEditView(food: food)) {
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

// MARK: - Food Edit View
struct FoodEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var food: FoodItem
    
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    @State private var editDangerLevel: Int = 1
    @State private var editIsFavorite: Bool = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            FoodItemFields(name: $editName, emoji: $editEmoji, dangerLevel: $editDangerLevel, isFavorite: $editIsFavorite)
            
            Section {
                HStack {
                    Text("Записей")
                    Spacer()
                    Text("\(food.entries.count)")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Удалить продукт", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(food.name)
        .onAppear {
            editName = food.name
            editEmoji = food.emoji
            editDangerLevel = food.dangerLevel
            editIsFavorite = food.isFavorite
        }
        .onDisappear {
            if !editName.isEmpty { food.name = editName }
            if !editEmoji.isEmpty { food.emoji = editEmoji }
            food.dangerLevel = editDangerLevel
            food.isFavorite = editIsFavorite
            try? modelContext.save()
        }
        .alert("Удалить продукт?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                modelContext.delete(food)
                try? modelContext.save()
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Продукт \"\(food.name)\" и все связанные записи будут удалены.")
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
struct CreateFoodItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var emoji = "🍎"
    @State private var dangerLevel = 1
    @State private var isFavorite = false
    
    var body: some View {
        NavigationStack {
            Form {
                FoodItemFields(name: $name, emoji: $emoji, dangerLevel: $dangerLevel, isFavorite: $isFavorite)
            }
            .navigationTitle("Новый продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveFoodItem()
                    }
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveFoodItem() {
        let food = FoodItem(name: name, emoji: emoji, isFavorite: isFavorite, dangerLevel: dangerLevel)
        modelContext.insert(food)
        try? modelContext.save()
        dismiss()
    }
}

struct CreateMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var draftMedication: Medication?
    
    var body: some View {
        NavigationStack {
            Group {
                if let medication = draftMedication {
                    MedicationEditView(medication: medication, isNew: true)
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            if draftMedication == nil {
                let newMed = Medication(name: "", emoji: "💊")
                modelContext.insert(newMed)
                draftMedication = newMed
            }
        }
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

// MARK: - Reusable Components
struct EmojiPickerButton: View {
    @Binding var emoji: String
    @FocusState private var isEmojiFocused: Bool
    
    var body: some View {
        ZStack {
            // Invisible Native TextField to trigger emoji keyboard
            EmojiTextFieldNative(text: $emoji)
                .focused($isEmojiFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: emoji) { _, newValue in
                    if newValue.count > 1 {
                        emoji = String(newValue.last!)
                        isEmojiFocused = false // Dismiss after choice
                    }
                }
            
            Button(action: { isEmojiFocused = true }) {
                Text(emoji)
                    .font(.title)
                    .frame(width: 54, height: 54)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}
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
