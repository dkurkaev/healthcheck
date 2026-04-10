import SwiftUI
import SwiftData
import Charts

public struct StatisticsView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    
    public init() {}
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @Query(sort: \FoodEntry.timestamp, order: .reverse)
    private var foodEntries: [FoodEntry]
    
    @Query(sort: \MedicationEntry.timestamp, order: .reverse)
    private var medicationEntries: [MedicationEntry]
    
    @Query(sort: \BodyAreaRating.timestamp)
    private var allRatings: [BodyAreaRating]
    
    @State private var selectedPeriod: StatisticsTimePeriod = .day
    @State private var showExportSheet = false
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(StatisticsTimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    overviewCard
                    
                    // Unified Interactive Chart
                    HealthChartView(selectedArea: nil, period: selectedPeriod)
                        .padding(.horizontal)
                    
                    ratingHistoryLink
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Статистика")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { exportData() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(isExporting)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // MARK: - Overview Card
    private var overviewCard: some View {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        let periodFood = foodEntries.filter { $0.timestamp >= cutoff }
        let periodMeds = medicationEntries.filter { $0.timestamp >= cutoff }
        
        return HStack(spacing: 16) {
            StatBox(
                title: "Еда",
                value: "\(periodFood.count)",
                icon: "fork.knife",
                color: .foodRed
            )
            
            StatBox(
                title: "Лекарства",
                value: "\(periodMeds.count)",
                icon: "pills.fill",
                color: .medicationBlue
            )
            
            StatBox(
                title: "Оценок",
                value: "\(allRatings.filter { $0.timestamp >= cutoff }.count)",
                icon: "heart.text.square.fill",
                color: .blue
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Rating History Link
    private var ratingHistoryLink: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("История")
                .font(.headline)
                .padding(.horizontal)
            
            NavigationLink(destination: RatingHistoryView()) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("История оценок")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Просмотр и удаление записей")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .cardStyle()
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Export Data
    private func exportData() {
        isExporting = true
        
        Task {
            let data = await ExcelExportService.generateXLSX(
                bodyAreas: Array(bodyAreas),
                foodEntries: Array(foodEntries),
                medicationEntries: Array(medicationEntries)
            )
            
            await MainActor.run {
                isExporting = false
                
                guard let data = data else { return }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
                let dateString = dateFormatter.string(from: Date())
                let fileName = "Healthcheck_\(dateString).xlsx"
                
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                do {
                    try data.write(to: fileURL)
                    exportFileURL = fileURL
                    showExportSheet = true
                } catch {
                    print("Export error: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Views
public struct StatBox: View { public init() {}
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .monospacedDigit()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

