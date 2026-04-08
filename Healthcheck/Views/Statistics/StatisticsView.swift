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
    
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedBodyArea: BodyArea?
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
        let cutoff = Date().daysAgo(selectedPeriod.days)
        
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
                    let ratings = allRatings.filter { r in
                        r.bodyArea?.id == area.id && r.timestamp >= cutoff
                    }
                    .sorted { $0.timestamp < $1.timestamp }
                    
                    if ratings.isEmpty {
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
                            ForEach(ratings) { rating in
                                LineMark(
                                    x: .value("Дата", rating.timestamp),
                                    y: .value("Оценка", rating.rating)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.ratingColor(rating.rating))
                                
                                AreaMark(
                                    x: .value("Дата", rating.timestamp),
                                    y: .value("Оценка", rating.rating)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.ratingColor(rating.rating).opacity(0.15),
                                            Color.ratingColor(rating.rating).opacity(0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            
                            let periodFood = foodEntries.filter { $0.timestamp >= cutoff }
                            ForEach(periodFood) { food in
                                RuleMark(x: .value("Еда", food.timestamp))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                    .foregroundStyle(.foodRed.opacity(0.4))
                                    .annotation(position: .top) {
                                        Text(food.foodItem?.emoji ?? "🍽")
                                            .font(.caption2)
                                    }
                            }
                            
                            let periodMeds = medicationEntries.filter { entry in
                                entry.timestamp >= cutoff && entry.bodyAreas.contains(where: { $0.id == area.id })
                            }
                            ForEach(periodMeds) { med in
                                RuleMark(x: .value("Лекарство", med.timestamp))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                    .foregroundStyle(.medicationBlue.opacity(0.4))
                                    .annotation(position: .bottom) {
                                        Text(med.medication?.emoji ?? "💊")
                                            .font(.caption2)
                                    }
                            }
                        }
                        .frame(height: 240)
                        .chartYScale(domain: 1...5)
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
                            AxisMarks(values: .stride(by: selectedPeriod == .week ? .day : .weekOfYear))
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Circle().fill(.foodRed.opacity(0.4)).frame(width: 8, height: 8)
                        Text("Еда")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(.medicationBlue.opacity(0.4)).frame(width: 8, height: 8)
                        Text("Лекарства")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .cardStyle()
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
