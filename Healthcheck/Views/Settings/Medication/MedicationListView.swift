import SwiftUI
import SwiftData

struct MedicationListView: View {
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
                ZStack {
                    NavigationLink(destination: MedicationEditorView(medication: medication)) {
                        EmptyView()
                    }
                    .opacity(0)
                    
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
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .cardStyle()
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(medication)
                        try? modelContext.save()
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: .appHorizontalPadding, bottom: 6, trailing: .appHorizontalPadding))
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
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
