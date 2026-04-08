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
    
    @Query(sort: \BodyAreaRating.timestamp)
    private var allRatings: [BodyAreaRating]
    
    @State private var selectedPeriod: TimePeriod = .day
    @State private var selectedBodyArea: BodyArea?
    @State private var showExportSheet = false
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    
    enum TimePeriod: String, CaseIterable {
        case day = "День"
        case week = "Неделя"
        case month = "Месяц"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    overviewCard
                    
                    areaTrendChart
                    
                    ratingHistoryLink
                }
                .padding(.vertical)
            }
            .onAppear {
                if selectedBodyArea == nil && !bodyAreas.isEmpty {
                    selectedBodyArea = bodyAreas.first
                }
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
    
    // MARK: - Area Trend Chart
    private var areaTrendChart: some View {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!.addingTimeInterval(-1)
        
        let cutoff: Date = {
            switch selectedPeriod {
            case .day: return startOfToday
            case .week: return calendar.date(byAdding: .day, value: -6, to: startOfToday)!
            case .month: return calendar.date(byAdding: .day, value: -29, to: startOfToday)!
            }
        }()
        
        let chartDomain: ClosedRange<Date> = {
            switch selectedPeriod {
            case .day: return startOfToday...endOfToday
            default: return cutoff...now
            }
        }()
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header copied EXACTLY from HomeView
            Menu {
                ForEach(bodyAreas) { area in
                    Button(action: {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            selectedBodyArea = area
                        }
                    }) {
                        Label(area.name, systemImage: area.emoji)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedBodyArea?.name ?? "Выберите зону")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.body)
                        .foregroundStyle(.blue)
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, .appHorizontalPadding)
            
            // The Chart Card
            VStack(alignment: .leading, spacing: 12) {
                if let area = selectedBodyArea {
                    let ratingsForChart: [ChartPoint] = prepareChartData(for: area, since: cutoff)
                    
                    if ratingsForChart.isEmpty && selectedPeriod != .day {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                            Text("Нет данных за этот период")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                    } else {
                        Chart {
                            ForEach(ratingsForChart) { point in
                                LineMark(
                                    x: .value("Дата", point.date),
                                    y: .value("Оценка", point.value)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.ratingColor(Int(point.value.rounded())))
                                
                                PointMark(
                                    x: .value("Дата", point.date),
                                    y: .value("Оценка", point.value)
                                )
                                .foregroundStyle(Color.ratingColor(Int(point.value.rounded())))
                                .symbolSize(selectedPeriod == .day ? 40 : 20)
                                
                                AreaMark(
                                    x: .value("Дата", point.date),
                                    y: .value("Оценка", point.value)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.ratingColor(Int(point.value.rounded())).opacity(0.15),
                                            Color.ratingColor(Int(point.value.rounded())).opacity(0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            
                            // Markers ONLY for 'Day' period
                            if selectedPeriod == .day {
                                let dayFood = foodEntries.filter { $0.timestamp >= startOfToday && $0.timestamp <= endOfToday }
                                ForEach(dayFood) { food in
                                    RuleMark(x: .value("Еда", food.timestamp))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                        .foregroundStyle(.foodRed.opacity(0.8))
                                        .annotation(position: .top, spacing: 0) {
                                            Text(food.foodItem?.emoji ?? "🍽")
                                                .font(.caption2)
                                                .padding(4)
                                                .background(Circle().fill(Color(.systemBackground)).shadow(radius: 1))
                                        }
                                }
                                
                                let currentAreaName = area.name
                                // Simplified medication filter to ensure visibility
                                let dayMeds = medicationEntries.filter { med in
                                    guard med.timestamp >= startOfToday && med.timestamp <= endOfToday else { return false }
                                    // Robust area check
                                    return med.bodyAreas.contains { $0.name.localizedStandardContains(currentAreaName) }
                                }
                                
                                ForEach(dayMeds) { med in
                                    RuleMark(x: .value("Лекарство", med.timestamp))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4])) // Slightly thicker
                                        .foregroundStyle(.medicationBlue.opacity(0.8))
                                        .annotation(position: .bottom, spacing: 0) {
                                            Text(med.medication?.emoji ?? "💊")
                                                .font(.caption2)
                                                .padding(4)
                                                .background(Circle().fill(Color(.systemBackground)).shadow(radius: 1))
                                        }
                                }
                            }
                        }
                        .frame(height: 240)
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                        .chartXScale(domain: chartDomain)
                        .chartYScale(domain: 0.8...5.5)
                        .chartYAxis {
                            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text(RatingLabel.emoji(for: intValue))
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .chartXAxis {
                            switch selectedPeriod {
                            case .day:
                                AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.hour(), anchor: .top)
                                }
                            case .week:
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.day().month(), anchor: .top)
                                }
                            case .month:
                                AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                                    AxisGridLine()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
            .cardStyle()
            .padding(.horizontal)
        }
    }
    
    // MARK: - Data Preparation Methods
    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    private func prepareChartData(for area: BodyArea, since date: Date) -> [ChartPoint] {
        let areaRatings = allRatings.filter { $0.bodyArea?.name == area.name && $0.timestamp >= date }
        
        if selectedPeriod == .day {
            // Return raw data for day view
            return areaRatings.map { ChartPoint(date: $0.timestamp, value: Double($0.rating)) }
                .sorted { $0.date < $1.date }
        } else {
            // Group by day and average for Week/Month
            let grouped = Dictionary(grouping: areaRatings) { rating in
                Calendar.current.startOfDay(for: rating.timestamp)
            }
            
            return grouped.map { (date, ratings) in
                let avg = Double(ratings.map(\.rating).reduce(0, +)) / Double(ratings.count)
                return ChartPoint(date: date, value: avg)
            }
            .sorted { $0.date < $1.date }
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
    
    // MARK: - Export Data
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let data = ExcelExportService.generateWorkbook(
                bodyAreas: Array(bodyAreas),
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
