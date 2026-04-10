import SwiftUI
import SwiftData

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var medications: [Medication]
    @Query private var medicationEntries: [MedicationEntry]
    @Query private var foodItems: [FoodItem]
    @Query private var foodEntries: [FoodEntry]
    @Query private var bodyAreas: [BodyArea]
    @Query private var bodyAreaRatings: [BodyAreaRating]
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            Section("Опасная зона") {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Стереть все данные", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Данные")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Удалить все данные?", isPresented: $showDeleteConfirmation) {
            Button("Удалить все", role: .destructive) {
                deleteAllData()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Это действие безвозвратно удалит все записи, лекарства, продукты и зоны тела. Приложение станет пустым.")
        }
    }
    
    private func deleteAllData() {
        medicationEntries.forEach { modelContext.delete($0) }
        medications.forEach { modelContext.delete($0) }
        foodEntries.forEach { modelContext.delete($0) }
        foodItems.forEach { modelContext.delete($0) }
        bodyAreaRatings.forEach { modelContext.delete($0) }
        bodyAreas.forEach { modelContext.delete($0) }
        
        try? modelContext.save()
    }
}
