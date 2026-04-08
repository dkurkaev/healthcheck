import SwiftUI
import SwiftData

struct RatingHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \BodyAreaRating.timestamp, order: .reverse)
    private var allRatings: [BodyAreaRating]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var expandedTransactions: Set<String> = []
    @State private var showDeleteConfirmation = false
    @State private var transactionToDelete: String?
    @State private var transactionToEdit: RatingTransaction?
    @State private var showEditSheet = false
    
    /// Group ratings into "transactions" — ratings made within the same minute
    var transactions: [RatingTransaction] {
        let grouped = Dictionary(grouping: allRatings) { rating in
            transactionKey(for: rating.timestamp)
        }
        
        return grouped.map { key, ratings in
            let sorted = ratings.sorted { ($0.bodyArea?.sortOrder ?? 0) < ($1.bodyArea?.sortOrder ?? 0) }
            return RatingTransaction(
                id: key,
                timestamp: sorted.first?.timestamp ?? Date(),
                ratings: sorted
            )
        }
        .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        List {
            if transactions.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("Нет записей")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Оценки здоровья появятся здесь")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }
            }
            
            ForEach(transactions) { transaction in
                Section {
                    // Transaction header — tappable to expand
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            if expandedTransactions.contains(transaction.id) {
                                expandedTransactions.remove(transaction.id)
                            } else {
                                expandedTransactions.insert(transaction.id)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.timestamp.fullDateString)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("\(transaction.timestamp.timeString) · \(transaction.ratingCount) зон")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // Average rating
                            let avg = transaction.averageRating
                            HStack(spacing: 6) {
                                Text(RatingLabel.emoji(for: Int(avg.rounded())))
                                    .font(.title3)
                                Text(String(format: "%.1f", avg))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.ratingColor(Int(avg.rounded())))
                                    .monospacedDigit()
                            }
                            
                            Image(systemName: expandedTransactions.contains(transaction.id) ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    
                    // Expanded: individual ratings
                    if expandedTransactions.contains(transaction.id) {
                        ForEach(transaction.ratings) { rating in
                            HStack(spacing: 12) {
                                Text(rating.bodyArea?.emoji ?? "❓")
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rating.bodyArea?.name ?? "—")
                                        .font(.subheadline)
                                    
                                    if !rating.note.isEmpty {
                                        Text(rating.note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text(RatingLabel.emoji(for: rating.rating))
                                        .font(.subheadline)
                                    
                                    Text("\(rating.rating)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.ratingColor(rating.rating))
                                        .monospacedDigit()
                                }
                            }
                            .padding(.vertical, 2)
                            .padding(.leading, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        transactionToDelete = transaction.id
                        showDeleteConfirmation = true
                    } label: {
                        Label("Удалить", systemImage: "trash.fill")
                    }
                    .tint(.red)
                    
                    Button {
                        transactionToEdit = transaction
                        showEditSheet = true
                    } label: {
                        Label("Изменить", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle("История оценок")
        .alert("Удалить оценку?", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                if let key = transactionToDelete,
                   let transaction = transactions.first(where: { $0.id == key }) {
                    deleteTransaction(transaction)
                }
            }
            Button("Отмена", role: .cancel) {
                transactionToDelete = nil
            }
        } message: {
            if let key = transactionToDelete,
               let transaction = transactions.first(where: { $0.id == key }) {
                Text("Будут удалены \(transaction.ratings.count) оценок от \(transaction.timestamp.relativeString)")
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let transaction = transactionToEdit {
                EditRatingView(transaction: transaction)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func transactionKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)-\(components.minute ?? 0)"
    }
    
    private func deleteTransaction(_ transaction: RatingTransaction) {
        for rating in transaction.ratings {
            modelContext.delete(rating)
        }
        try? modelContext.save()
        transactionToDelete = nil
    }
}

// MARK: - Edit Rating View
struct EditRatingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let transaction: RatingTransaction
    @State private var editedRatings: [UUID: Int] = [:]
    @State private var editedNotes: [UUID: String] = [:]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("✏️")
                            .font(.system(size: 40))
                        Text("Изменить оценки")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(transaction.timestamp.relativeString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical)
                    
                    ForEach(transaction.ratings) { rating in
                        VStack(spacing: 10) {
                            HStack {
                                Text(rating.bodyArea?.emoji ?? "❓")
                                    .font(.title2)
                                Text(rating.bodyArea?.name ?? "—")
                                    .font(.headline)
                                Spacer()
                                let current = editedRatings[rating.id] ?? rating.rating
                                Text(RatingLabel.emoji(for: current))
                                    .font(.title)
                            }
                            
                            // Rating selector
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { value in
                                    let currentValue = editedRatings[rating.id] ?? rating.rating
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            editedRatings[rating.id] = value
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Text("\(value)")
                                                .font(.headline)
                                                .fontWeight(currentValue == value ? .bold : .regular)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(currentValue == value ? Color.ratingColor(value) : Color(.tertiarySystemBackground))
                                        )
                                        .foregroundStyle(currentValue == value ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Note
                            TextField("Заметка...", text: Binding(
                                get: { editedNotes[rating.id] ?? rating.note },
                                set: { editedNotes[rating.id] = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                        }
                        .padding()
                        .cardStyle()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Изменить оценки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveEdits()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveEdits() {
        for rating in transaction.ratings {
            if let newValue = editedRatings[rating.id] {
                rating.rating = min(max(newValue, 1), 5)
            }
            if let newNote = editedNotes[rating.id] {
                rating.note = newNote
            }
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Rating Transaction Model
struct RatingTransaction: Identifiable {
    let id: String
    let timestamp: Date
    let ratings: [BodyAreaRating]
    
    var averageRating: Double {
        guard !ratings.isEmpty else { return 0 }
        let sum = ratings.map(\.rating).reduce(0, +)
        return Double(sum) / Double(ratings.count)
    }
    
    var ratingCount: Int { ratings.count }
}

#Preview {
    NavigationStack {
        RatingHistoryView()
    }
    .modelContainer(for: [BodyArea.self, BodyAreaRating.self], inMemory: true)
}
