import SwiftUI
import SwiftData

struct RateHealthView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var ratings: [UUID: Int] = [:]
    @State private var notes: [UUID: String] = [:]
    @State private var showSavedAnimation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🏥")
                            .font(.system(size: 50))
                        
                        Text("Как вы себя чувствуете?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Оцените состояние каждой зоны от 1 (ужасно) до 5 (отлично)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical)
                    
                    // Rating Cards
                    ForEach(bodyAreas) { area in
                        RatingCard(
                            bodyArea: area,
                            rating: Binding(
                                get: { ratings[area.id] ?? area.todayRating?.rating ?? 3 },
                                set: { ratings[area.id] = $0 }
                            ),
                            note: Binding(
                                get: { notes[area.id] ?? "" },
                                set: { notes[area.id] = $0 }
                            )
                        )
                    }
                }
                .padding()
                .contentShape(Rectangle())
                .dismissKeyboardOnTap()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Оценка здоровья")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveRatings()
                    }
                    .fontWeight(.bold)
                }
            }
            .overlay {
                if showSavedAnimation {
                    savedOverlay
                }
            }
        }
    }
    
    // MARK: - Saved Overlay
    private var savedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Сохранено!")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(40)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Save
    private func saveRatings() {
        for area in bodyAreas {
            let ratingValue = ratings[area.id] ?? 3
            let note = notes[area.id] ?? ""
            
            let rating = BodyAreaRating(
                rating: ratingValue,
                note: note,
                bodyArea: area
            )
            modelContext.insert(rating)
        }
        
        try? modelContext.save()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSavedAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// MARK: - Rating Card
struct RatingCard: View {
    let bodyArea: BodyArea
    @Binding var rating: Int
    @Binding var note: String
    
    @State private var showNote = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text(bodyArea.emoji)
                    .font(.title2)
                
                Text(bodyArea.name)
                    .font(.headline)
                
                Spacer()
                
                Text(RatingLabel.emoji(for: rating))
                    .font(.title)
                    .animation(.spring(response: 0.3), value: rating)
            }
            
            // Rating Selector
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = value
                        }
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        VStack(spacing: 4) {
                            Text("\(value)")
                                .font(.headline)
                                .fontWeight(rating == value ? .bold : .regular)
                            
                            Text(RatingLabel.text(for: value))
                                .font(.system(size: 8))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(rating == value ? Color.ratingColor(value) : Color(.tertiarySystemBackground))
                        )
                        .foregroundStyle(rating == value ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Note Toggle & Field
            Button(action: { withAnimation { showNote.toggle() } }) {
                HStack {
                    Image(systemName: showNote ? "note.text" : "note.text.badge.plus")
                        .font(.caption)
                    Text(showNote ? "Скрыть заметку" : "Добавить заметку")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            if showNote {
                AppTextField(title: "Заметка...", text: $note, icon: "text.quote")
                    .font(.subheadline)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .cardStyle()
    }
}
