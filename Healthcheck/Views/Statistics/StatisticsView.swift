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
    @State private var selectedDate: Date?
    
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
                value: "\(totalRatings(since: cutoff))",
                icon: "heart.text.square.fill",
                color: .blue
            )
        }
        .padding(.horizontal)
    }
    
    private func totalRatings(since date: Date) -> Int {
        allRatings.filter { $0.timestamp >= date }.count
    }
    
    // MARK: - Area Trend Chart
    private var areaTrendChart: some View {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!.addingTimeInterval(-1)
        
        let cutoffDay: Date = startOfToday
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
            // Header
            Menu {
                Button(action: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        selectedBodyArea = nil
                    }
                }) {
                    Label("Общее здоровье", systemImage: "figure.walk")
                }
                
                Divider()
                
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
                    Text(selectedBodyArea?.name ?? "Общее здоровье")
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
            
            // The Stocks Style Chart Card
            VStack(alignment: .leading, spacing: 16) {
                let ratingsForChart: [ChartPoint] = prepareChartData(for: selectedBodyArea, since: cutoff)
                
                // Header with dynamic values
                HStack(alignment: .center, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        if let selectedDate, 
                           let point = ratingsForChart.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }) {
                            Text(String(format: "%.1f", point.value))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text(point.date.timeString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if let last = ratingsForChart.last {
                            Text(String(format: "%.1f", last.value))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("Сейчас")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Event info on the right
                    if let selectedDate, let event = findClosestEvent(to: selectedDate) {
                        HStack(spacing: 4) {
                            Text(event.emoji)
                            Text(event.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .frame(height: 48)
                
                if ratingsForChart.isEmpty && selectedPeriod != .day {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("Нет данных")
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
                            .interpolationMethod(.linear)
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            AreaMark(
                                x: .value("Дата", point.date),
                                y: .value("Оценка", point.value)
                            )
                            .interpolationMethod(.linear)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.15), .blue.opacity(0)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            PointMark(
                                x: .value("Дата", point.date),
                                y: .value("Оценка", point.value)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(20)
                        }
                        
                        if let selectedDate {
                            RuleMark(x: .value("Selected", selectedDate))
                                .foregroundStyle(.secondary.opacity(0.3))
                                .zIndex(-1)
                        }
                        
                        // Markers
                        if selectedPeriod == .day {
                            let dayFood = foodEntries.filter { $0.timestamp >= startOfToday && $0.timestamp <= endOfToday }
                            ForEach(dayFood) { food in
                                RuleMark(x: .value("Дата", food.timestamp))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .foregroundStyle(.foodRed.opacity(0.4))
                            }
                            
                            let dayMeds = medicationEntries.filter { med in
                                guard med.timestamp >= startOfToday && med.timestamp <= endOfToday else { return false }
                                if let area = selectedBodyArea {
                                    return med.bodyAreas.contains { $0.name == area.name }
                                }
                                return true // Show overall meds
                            }
                            ForEach(dayMeds) { med in
                                RuleMark(x: .value("Дата", med.timestamp))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .foregroundStyle(.medicationBlue.opacity(0.4))
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.trailing, 10)
                    .chartXScale(domain: chartDomain)
                    .chartYScale(domain: 0.8...5.2)
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        switch selectedPeriod {
                        case .day:
                            AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.tertiary.opacity(0.5))
                                AxisValueLabel(format: .dateTime.hour(), anchor: .top)
                            }
                        case .week:
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.tertiary.opacity(0.5))
                                AxisValueLabel(format: .dateTime.day().month(), anchor: .top)
                            }
                        case .month:
                            AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.tertiary.opacity(0.5))
                            }
                        }
                    }
                    .chartXSelection(value: $selectedDate)
                }
            }
            .padding(.vertical)
            .cardStyle()
            .padding(.horizontal)
        }
    }
    
    // MARK: - Data Preparation
    private func prepareChartData(for area: BodyArea?, since date: Date) -> [ChartPoint] {
        let ratings: [BodyAreaRating]
        if let area = area {
            ratings = allRatings.filter { r in
                r.bodyArea?.name == area.name && r.timestamp >= date && r.rating > 0
            }
        } else {
            ratings = allRatings.filter { $0.timestamp >= date && $0.rating > 0 }
        }
        
        if selectedPeriod == .day {
            if area != nil {
                return ratings.map { ChartPoint(date: $0.timestamp, value: Double($0.rating)) }
                    .sorted { $0.date < $1.date }
            } else {
                let interval: TimeInterval = 300 // 5 minutes grouping
                let grouped = Dictionary(grouping: ratings) { rating in
                    Date(timeIntervalSince1970: floor(rating.timestamp.timeIntervalSince1970 / interval) * interval)
                }
                return grouped.map { (date, ratings) in
                    let avg = Double(ratings.map(\.rating).reduce(0, +)) / Double(ratings.count)
                    return ChartPoint(date: date, value: avg)
                }
                .sorted { $0.date < $1.date }
            }
        } else {
            let grouped = Dictionary(grouping: ratings) { 
                Calendar.current.startOfDay(for: $0.timestamp)
            }
            return grouped.map { (date, ratings) in
                let avg = Double(ratings.map(\.rating).reduce(0, +)) / Double(ratings.count)
                return ChartPoint(date: date, value: avg)
            }
            .sorted { $0.date < $1.date }
        }
    }
    
    private func findClosestEvent(to date: Date) -> (emoji: String, name: String)? {
        let threshold: TimeInterval = 600 // 10 minutes
        
        let food = foodEntries.first { abs($0.timestamp.timeIntervalSince(date)) < threshold }
        if let food { return (food.foodItem?.emoji ?? "🍽", food.foodItem?.name ?? "Еда") }
        
        let med = medicationEntries.first { med in
            guard abs(med.timestamp.timeIntervalSince(date)) < threshold else { return false }
            if let area = selectedBodyArea {
                return med.bodyAreas.contains { $0.name == area.name }
            }
            return true
        }
        if let med { return (med.medication?.emoji ?? "💊", med.medication?.name ?? "Лекарство") }
        
        return nil
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

// MARK: - Supporting Views & Models
struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

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
