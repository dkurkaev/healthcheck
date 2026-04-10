import SwiftUI
import SwiftData

struct AddRatingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var ratings: [UUID: Int] = [:]
    @State private var notes: [UUID: String] = [:]
    @State private var showSavedAnimation = false
    @State private var hasInitialized = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Rating Cards
                    ForEach(bodyAreas) { area in
                        RatingCard(
                            bodyArea: area,
                            rating: Binding(
                                get: { ratings[area.id] ?? area.latestRating?.rating ?? 3 },
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveRatings) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.blue)
                    }
                }
            }
            .overlay {
                if showSavedAnimation {
                    savedOverlay
                }
            }
            .onAppear {
                if !hasInitialized {
                    // Pre-populate with latest ratings
                    for area in bodyAreas {
                        if let lastRating = area.latestRating {
                            ratings[area.id] = lastRating.rating
                        }
                    }
                    hasInitialized = true
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
            // Pick value from state or latest rating, default to 3
            let ratingValue = ratings[area.id] ?? area.latestRating?.rating ?? 3
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
                    Image(systemName: showNote ? "bubble.left.fill" : "bubble.left")
                        .font(.caption)
                    Text(showNote ? "Скрыть комментарий" : "Добавить комментарий")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            if showNote {
                TextField("Комментарий...", text: $note)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .font(.subheadline)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .cardStyle()
    }
}
