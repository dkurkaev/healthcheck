import SwiftUI
import SwiftData

struct FoodEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let entry: FoodEntry
    
    @State private var timestamp: Date
    @State private var note: String
    
    init(entry: FoodEntry) {
        self.entry = entry
        _timestamp = State(initialValue: entry.timestamp)
        _note = State(initialValue: entry.note)
    }
    
    var hasChanges: Bool {
        timestamp != entry.timestamp || note != entry.note
    }
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Text(entry.foodItem?.emoji ?? "🍽").font(.system(size: 40)).padding(8).background(Color.accentColor.opacity(0.1)).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.foodItem?.name ?? "Продукт").font(.headline)
                        if let dangerLevel = entry.foodItem?.dangerLevel { DangerBadge(level: dangerLevel) }
                    }
                }
                .padding(.vertical, 8)
            }
            Section { DatePicker("Дата и время", selection: $timestamp) } header: { Text("Время приема") }
            Section { TextEditor(text: $note).frame(minHeight: 100) } header: { Text("Заметка") }
        }
        .navigationTitle("Детали записи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    entry.timestamp = timestamp
                    entry.note = note
                    try? modelContext.save()
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!hasChanges)
            }
        }
    }
}

struct MedicationEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let entry: MedicationEntry
    @Query(sort: \BodyArea.sortOrder) private var allBodyAreas: [BodyArea]
    
    @State private var timestamp: Date
    @State private var note: String
    @State private var selectedBodyAreas: Set<UUID>
    
    init(entry: MedicationEntry) {
        self.entry = entry
        _timestamp = State(initialValue: entry.timestamp)
        _note = State(initialValue: entry.note)
        _selectedBodyAreas = State(initialValue: Set(entry.bodyAreas.map(\.id)))
    }
    
    var hasChanges: Bool {
        timestamp != entry.timestamp || 
        note != entry.note || 
        selectedBodyAreas != Set(entry.bodyAreas.map(\.id))
    }
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Text(entry.medication?.emoji ?? "💊").font(.system(size: 40)).padding(8).background(Color.medicationBlue.opacity(0.1)).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) { Text(entry.medication?.name ?? "Лекарство").font(.headline) }
                }
                .padding(.vertical, 8)
            }
            Section { DatePicker("Дата и время", selection: $timestamp) } header: { Text("Время приема") }
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(allBodyAreas) { area in
                        let isSelected = selectedBodyAreas.contains(area.id)
                        Button(action: {
                            if isSelected { selectedBodyAreas.remove(area.id) }
                            else { selectedBodyAreas.insert(area.id) }
                        }) {
                            VStack(spacing: 4) { Text(area.emoji).font(.title3); Text(area.name).font(.caption2).lineLimit(1) }
                            .frame(maxWidth: .infinity).padding(.vertical, 8).background(isSelected ? Color.medicationBlue : Color(.tertiarySystemBackground)).foregroundStyle(isSelected ? .white : .primary).clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            } header: { Text("Зоны применения") }
            Section { TextEditor(text: $note).frame(minHeight: 100) } header: { Text("Заметка") }
        }
        .navigationTitle("Детали записи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    entry.timestamp = timestamp
                    entry.note = note
                    entry.bodyAreas = allBodyAreas.filter { selectedBodyAreas.contains($0.id) }
                    try? modelContext.save()
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!hasChanges)
            }
        }
    }
}

struct RatingTransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let timestamp: Date
    let ratings: [BodyAreaRating]
    @State private var showEditSheet = false
    var body: some View {
        List {
            Section {
                LabeledContent("Время оценки", value: timestamp.relativeString)
            }
            Section {
                ForEach(ratings) { rating in
                    HStack(spacing: 12) {
                        Text(rating.bodyArea?.emoji ?? "❓").font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rating.bodyArea?.name ?? "—").font(.subheadline).fontWeight(.medium)
                            if !rating.note.isEmpty { Text(rating.note).font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text(RatingLabel.emoji(for: rating.rating))
                            Text("\(rating.rating)").font(.headline).fontWeight(.bold).foregroundStyle(Color.ratingColor(rating.rating))
                        }
                    }
                }
            } header: { Text("Оценки по зонам (\(ratings.count))") }
        }
        .navigationTitle("Детали оценки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .primaryAction) { Button("Изменить") { showEditSheet = true } } }
        .sheet(isPresented: $showEditSheet) { EditRatingViewFromHistory(ratings: ratings, timestamp: timestamp) }
    }
}

struct OtherImpactEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let entry: OtherImpactEntry
    
    @State private var timestamp: Date
    @State private var note: String
    
    init(entry: OtherImpactEntry) {
        self.entry = entry
        _timestamp = State(initialValue: entry.timestamp)
        _note = State(initialValue: entry.note)
    }
    
    var hasChanges: Bool {
        timestamp != entry.timestamp || note != entry.note
    }
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Text(entry.impact?.emoji ?? "☀️").font(.system(size: 40)).padding(8).background(Color.orange.opacity(0.1)).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.impact?.name ?? "Воздействие").font(.headline)
                    }
                }
                .padding(.vertical, 8)
            }
            Section { DatePicker("Дата и время", selection: $timestamp) } header: { Text("Время приема") }
            Section { TextEditor(text: $note).frame(minHeight: 100) } header: { Text("Заметка") }
        }
        .navigationTitle("Детали записи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    entry.timestamp = timestamp
                    entry.note = note
                    try? modelContext.save()
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!hasChanges)
            }
        }
    }
}
