import SwiftUI
import SwiftData

public struct DataManagementView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var medications: [Medication]
    @Query private var medicationEntries: [MedicationEntry]
    @Query private var foodItems: [FoodItem]
    @Query private var foodEntries: [FoodEntry]
    @Query private var bodyAreas: [BodyArea]
    @Query private var bodyAreaRatings: [BodyAreaRating]
    
    @State private var showDeleteConfirmation = false
    
    public var body: some View {
        List {
            Section {
                StandardHeader(title: "Статистика базы")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
                
                VStack(spacing: 0) {
                    statRow(title: "Лекарства", count: medications.count, icon: "pills.fill", color: .blue)
                    Divider().padding(.leading, 50)
                    statRow(title: "Записи лекарств", count: medicationEntries.count, icon: "list.clipboard.fill", color: .blue)
                    Divider().padding(.leading, 50)
                    statRow(title: "Продукты", count: foodItems.count, icon: "apple.logo", color: .green)
                    Divider().padding(.leading, 50)
                    statRow(title: "Записи продуктов", count: foodEntries.count, icon: "fork.knife", color: .green)
                    Divider().padding(.leading, 50)
                    statRow(title: "Зоны тела", count: bodyAreas.count, icon: "figure.walk", color: .orange)
                    Divider().padding(.leading, 50)
                    statRow(title: "Оценки здоровья", count: bodyAreaRatings.count, icon: "heart.text.square.fill", color: .red)
                }
                .cardStyle()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: .appHorizontalPadding, bottom: 20, trailing: .appHorizontalPadding))
            }
            
            Section {
                StandardHeader(title: "Опасная зона")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
                
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Label("Стереть все данные", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: .appHorizontalPadding, bottom: 40, trailing: .appHorizontalPadding))
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
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
    
    private func statRow(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding()
    }
    
    private func deleteAllData() {
        // Delete all entities
        medicationEntries.forEach { modelContext.delete($0) }
        medications.forEach { modelContext.delete($0) }
        foodEntries.forEach { modelContext.delete($0) }
        foodItems.forEach { modelContext.delete($0) }
        bodyAreaRatings.forEach { modelContext.delete($0) }
        bodyAreas.forEach { modelContext.delete($0) }
        
        try? modelContext.save()
    }
}
