import SwiftUI
import SwiftData

struct MedicationListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Medication.sortOrder)
    private var medications: [Medication]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var showAddMedication = false
    
    var body: some View {
        AppEditableList(items: medications, emptyView: {
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
        }) { medication in
            NavigationLink(destination: MedicationEditorView(medication: medication)) {
                HStack(spacing: 12) {
                    Text(medication.emoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.medicationBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        let templateCount = medication.templates.count
                        let entryCount = medication.entries.count
                        Text("\(templateCount) шаблонов · \(entryCount) применений")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Лекарства")
        .navigationBarTitleDisplayMode(.inline)
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
            MedicationEditorView()
        }
    }
}
