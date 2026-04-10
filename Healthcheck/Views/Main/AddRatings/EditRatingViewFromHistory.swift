import SwiftUI
import SwiftData

struct EditRatingViewFromHistory: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let ratings: [BodyAreaRating]
    @State private var timestamp: Date // Made mutable
    
    @State private var ratingsMap: [UUID: Int] = [:]
    @State private var notesMap: [UUID: String] = [:]
    
    init(ratings: [BodyAreaRating], timestamp: Date) {
        self.ratings = ratings
        self._timestamp = State(initialValue: timestamp)
        
        // Initialize maps from existing ratings
        var rMap: [UUID: Int] = [:]
        var nMap: [UUID: String] = [:]
        for rating in ratings {
            if let area = rating.bodyArea {
                rMap[area.id] = rating.rating
                nMap[area.id] = rating.note
            }
        }
        _ratingsMap = State(initialValue: rMap)
        _notesMap = State(initialValue: nMap)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Дата и время", selection: $timestamp)
                } header: {
                    Text("Время оценки")
                }
                
                ForEach(ratings) { rating in
                    if let area = rating.bodyArea {
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(area.emoji)
                                        .font(.title2)
                                    Text(area.name)
                                        .font(.headline)
                                    Spacer()
                                    
                                    let currentRating = ratingsMap[area.id] ?? 0
                                    Text(RatingLabel.text(for: currentRating))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.ratingColor(currentRating))
                                }
                                
                                // Fixed color logic for Health Rating
                                HStack(spacing: 8) {
                                    ForEach(1...5, id: \.self) { level in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                ratingsMap[area.id] = level
                                            }
                                        }) {
                                            Text("\(level)")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(ratingsMap[area.id] == level ? Color.ratingColor(level) : Color(.secondarySystemGroupedBackground))
                                                )
                                                .foregroundStyle(ratingsMap[area.id] == level ? .white : .primary)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(ratingsMap[area.id] == level ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                TextField("Комментарий...", text: noteBinding(for: area.id))
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Изменить оценку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func noteBinding(for areaId: UUID) -> Binding<String> {
        Binding(
            get: { notesMap[areaId] ?? "" },
            set: { notesMap[areaId] = $0 }
        )
    }
    
    private func saveChanges() {
        for rating in ratings {
            if let area = rating.bodyArea {
                rating.rating = ratingsMap[area.id] ?? rating.rating
                rating.note = notesMap[area.id] ?? rating.note
                rating.timestamp = timestamp // Update all ratings to the new timestamp
            }
        }
        try? modelContext.save()
    }
}
