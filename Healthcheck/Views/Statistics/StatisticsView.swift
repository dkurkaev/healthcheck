import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @Query(sort: \FoodEntry.timestamp, order: .reverse)
    private var foodEntries: [FoodEntry]
    
    @Query(sort: \MedicationEntry.timestamp, order: .reverse)
    private var medicationEntries: [MedicationEntry]
    
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedBodyArea: BodyArea?
    @State private var showCorrelation = false
    @State private var showExportSheet = false
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    
    enum TimePeriod: String, CaseIterable {
        case week = "Неделя"
        case month = "Месяц"
        case threeMonths = "3 мес"
        case year = "Год"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Overview Card
                    overviewCard
                    
                    // All Body Areas Chart
                    allAreasChart
                    
                    // Individual Area Selector
                    bodyAreaSelector
                    
                    // Selected Area Detail Chart
                    if let area = selectedBodyArea {
                        selectedAreaChart(area: area)
                    }
                    
                    // Rating History
                    ratingHistoryLink
                    
                    // Correlation Section
                    correlationSection
                    
                    // Export Section
                    exportSection
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
        let cutoff = Date().daysAgo(selectedPeriod.days)
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
                value: "\(totalRatings(since: cutoff))",
                icon: "heart.text.square.fill",
                color: .blue
            )
        }
        .padding(.horizontal)
    }
    
    private func totalRatings(since date: Date) -> Int {
        bodyAreas.flatMap { $0.ratings.filter { $0.timestamp >= date } }.count
    }
    
    // MARK: - All Areas Chart
    private var allAreasChart: some View {
        let cutoff = Date().daysAgo(selectedPeriod.days)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Динамика всех зон")
                .font(.headline)
                .padding(.horizontal)
            
            let chartData = bodyAreas.flatMap { area in
                area.ratings
                    .filter { $0.timestamp >= cutoff }
                    .sorted { $0.timestamp < $1.timestamp }
                    .map { rating in
                        ChartDataPoint(
                            date: rating.timestamp,
                            value: Double(rating.rating),
                            category: area.name
                        )
                    }
            }
            
            if chartData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Нет данных за выбранный период")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                Chart(chartData, id: \.id) { point in
                    LineMark(
                        x: .value("Дата", point.date),
                        y: .value("Оценка", point.value)
                    )
                    .foregroundStyle(by: .value("Зона", point.category))
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(RatingLabel.emoji(for: intValue))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartLegend(.visible)
                .frame(height: 250)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .cardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - Body Area Selector
    private var bodyAreaSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Детальный анализ")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(bodyAreas) { area in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedBodyArea = selectedBodyArea?.id == area.id ? nil : area
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(area.emoji)
                                    .font(.title3)
                                Text(area.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .frame(width: 70, height: 60)
                            .background(
                                selectedBodyArea?.id == area.id
                                    ? Color.blue.opacity(0.2)
                                    : Color(.tertiarySystemBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedBodyArea?.id == area.id ? Color.blue : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Selected Area Chart
    private func selectedAreaChart(area: BodyArea) -> some View {
        let cutoff = Date().daysAgo(selectedPeriod.days)
        let ratings = area.ratings
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
        
        // Related food entries
        let foodInPeriod = foodEntries.filter { $0.timestamp >= cutoff }
        
        // Related medication entries
        let medsForArea = medicationEntries.filter { entry in
            entry.timestamp >= cutoff && entry.bodyAreas.contains(where: { $0.id == area.id })
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(area.emoji)
                    .font(.title2)
                Text(area.name)
                    .font(.headline)
            }
            
            if ratings.isEmpty {
                Text("Нет данных за выбранный период")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Chart {
                    ForEach(ratings) { rating in
                        LineMark(
                            x: .value("Дата", rating.timestamp),
                            y: .value("Оценка", rating.rating)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("Дата", rating.timestamp),
                            y: .value("Оценка", rating.rating)
                        )
                        .foregroundStyle(Color.ratingColor(rating.rating))
                        .symbolSize(50)
                    }
                    
                    // Food markers
                    ForEach(foodInPeriod) { entry in
                        RuleMark(x: .value("Дата", entry.timestamp))
                            .foregroundStyle(.foodRed.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            .annotation(position: .top) {
                                Text(entry.foodItem?.emoji ?? "🍽")
                                    .font(.caption2)
                            }
                    }
                    
                    // Medication markers for this area
                    ForEach(medsForArea) { entry in
                        RuleMark(x: .value("Дата", entry.timestamp))
                            .foregroundStyle(.medicationBlue.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            .annotation(position: .bottom) {
                                Text(entry.medication?.emoji ?? "💊")
                                    .font(.caption2)
                            }
                    }
                }
                .chartYScale(domain: 1...5)
                .frame(height: 220)
            }
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(.foodRed).frame(width: 8, height: 8)
                    Text("Еда")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(.medicationBlue).frame(width: 8, height: 8)
                    Text("Лекарства")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Correlation Section
    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Корреляции")
                .font(.headline)
                .padding(.horizontal)
            
            NavigationLink(destination: CorrelationView()) {
                HStack {
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Анализ влияния")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Как еда и лекарства влияют на здоровье")
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
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Экспорт")
                .font(.headline)
                .padding(.horizontal)
            
            Button(action: { exportData() }) {
                HStack {
                    Image(systemName: "doc.richtext")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Экспорт в Excel")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Выгрузить все данные в формате .xls")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
                .cardStyle()
            }
            .buttonStyle(.plain)
            .disabled(isExporting)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Export Data
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let data = ExcelExportService.generateWorkbook(
                bodyAreas: bodyAreas,
                foodEntries: Array(foodEntries),
                medicationEntries: Array(medicationEntries)
            )
            
            DispatchQueue.main.async {
                isExporting = false
                
                guard let data = data else { return }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
                let dateString = dateFormatter.string(from: Date())
                let fileName = "Healthcheck_\(dateString).xls"
                
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

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
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

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
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

// MARK: - Chart Data Point
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let category: String
}

#Preview {
    StatisticsView()
        .modelContainer(for: [
            BodyArea.self, BodyAreaRating.self,
            FoodItem.self, FoodEntry.self,
            Medication.self, MedicationTemplate.self, MedicationEntry.self
        ], inMemory: true)
}
