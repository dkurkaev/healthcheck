import SwiftUI
import SwiftData

struct MedicationLogView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Medication.createdAt, order: .reverse)
    private var medications: [Medication]
    
    @Query(sort: \MedicationTemplate.createdAt, order: .reverse)
    private var templates: [MedicationTemplate]
    
    @Query(sort: \MedicationEntry.timestamp, order: .reverse)
    private var entries: [MedicationEntry]
    
    @State private var showAddMedication = false
    @State private var showAddTemplate = false
    @State private var showApplyMedication = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment control
                Picker("Вид", selection: $selectedTab) {
                    Text("Лекарства").tag(0)
                    Text("Шаблоны").tag(1)
                    Text("История").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    switch selectedTab {
                    case 0:
                        medicationsSection
                    case 1:
                        templatesSection
                    case 2:
                        historySection
                    default:
                        EmptyView()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Лекарства")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showAddMedication = true }) {
                            Label("Новое лекарство", systemImage: "pills.fill")
                        }
                        Button(action: { showAddTemplate = true }) {
                            Label("Новый шаблон", systemImage: "rectangle.stack.fill")
                        }
                        Button(action: { showApplyMedication = true }) {
                            Label("Записать применение", systemImage: "plus.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.medicationBlue)
                    }
                }
            }
            .sheet(isPresented: $showAddMedication) {
                AddMedicationView()
            }
            .sheet(isPresented: $showAddTemplate) {
                MedicationTemplateView()
            }
            .sheet(isPresented: $showApplyMedication) {
                ApplyMedicationView()
            }
        }
    }
    
    // MARK: - Medications Section
    private var medicationsSection: some View {
        LazyVStack(spacing: 10) {
            if medications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pills.circle")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("Нет лекарств")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Добавьте первое лекарство")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(medications) { med in
                    MedicationRow(medication: med)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Templates Section
    private var templatesSection: some View {
        LazyVStack(spacing: 10) {
            if templates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("Нет шаблонов")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Шаблоны связывают лекарство с зонами тела")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(templates) { template in
                    TemplateRow(template: template)
                }
            }
        }
        .padding()
    }
    
    // MARK: - History Section
    private var historySection: some View {
        LazyVStack(spacing: 10) {
            if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("Нет записей")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(entries) { entry in
                    HStack(spacing: 12) {
                        Text(entry.medication?.emoji ?? "💊")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color.medicationBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.medication?.name ?? "—")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if !entry.bodyAreas.isEmpty {
                                Text(entry.bodyAreas.map { "\($0.emoji) \($0.name)" }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        Text(entry.timestamp.relativeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .cardStyle()
                }
            }
        }
        .padding()
    }
}

// MARK: - Medication Row
struct MedicationRow: View {
    @Environment(\.modelContext) private var modelContext
    let medication: Medication
    
    var body: some View {
        HStack(spacing: 14) {
            Text(medication.emoji)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(Color.medicationBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("\(medication.entries.count) применений")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !medication.templates.isEmpty {
                        Text("\(medication.templates.count) шаблонов")
                            .font(.caption)
                            .foregroundStyle(.medicationBlue)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .cardStyle()
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(medication)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}

// MARK: - Template Row
struct TemplateRow: View {
    let template: MedicationTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(.medicationBlue)
                
                Text(template.name)
                    .font(.headline)
            }
            
            HStack(spacing: 4) {
                if let med = template.medication {
                    Text(med.emoji)
                    Text(med.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text("→")
                    .foregroundStyle(.tertiary)
            }
            
            // Body areas tags
            FlowLayout(spacing: 6) {
                ForEach(template.bodyAreas) { area in
                    Text("\(area.emoji) \(area.name)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.medicationBlue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
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

#Preview {
    MedicationLogView()
        .modelContainer(for: [
            Medication.self, MedicationTemplate.self, MedicationEntry.self, BodyArea.self
        ], inMemory: true)
}
