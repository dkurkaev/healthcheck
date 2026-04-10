import SwiftUI
import SwiftData
import Charts

public struct HealthChartView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    
    let selectedArea: BodyArea?
    let period: StatisticsTimePeriod
    let isLockedToArea: Bool
    
    @Query(sort: \FoodEntry.timestamp, order: .reverse)
    private var foodEntries: [FoodEntry]
    
    @Query(sort: \MedicationEntry.timestamp, order: .reverse)
    private var medicationEntries: [MedicationEntry]
    
    @Query(sort: \BodyAreaRating.timestamp)
    private var allRatings: [BodyAreaRating]
    
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @State private var selectedDate: Date?
    @State private var internalSelectedArea: BodyArea? 
    
    // Use an initializer to bridge between passed area and potential internal selection
    public init(selectedArea: BodyArea?, period: StatisticsTimePeriod, isLockedToArea: Bool = false) {
        self.selectedArea = selectedArea
        self.period = period
        self.isLockedToArea = isLockedToArea
        self._internalSelectedArea = State(initialValue: selectedArea)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Menu (if allowed)
            headerView
            
            // Chart Card
            VStack(alignment: .leading, spacing: 16) {
                let currentArea = isLockedToArea ? selectedArea : internalSelectedArea
                let ratingsForChart = prepareChartData(for: currentArea)
                
                // Dynamic Value Header
                chartValueHeader(ratingsForChart: ratingsForChart)
                
                if ratingsForChart.isEmpty && period != .day {
                    emptyChartView
                } else {
                    mainChart(ratingsForChart: ratingsForChart, currentArea: currentArea)
                }
            }
            .padding(.vertical)
            .cardStyle()
        }
    }
    
    private var headerView: some View {
        Group {
            if isLockedToArea {
                EmptyView()
            } else {
                Menu {
                    Button(action: { internalSelectedArea = nil }) {
                        Label("Общее здоровье", systemImage: "figure.walk")
                    }
                    
                    Divider()
                    
                    ForEach(bodyAreas) { area in
                        Button(action: { internalSelectedArea = area }) {
                            Label(area.name, systemImage: area.emoji)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(internalSelectedArea?.name ?? "Общее здоровье")
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
                .padding(.horizontal)
            }
        }
    }
    
    private func chartValueHeader(ratingsForChart: [ChartPoint]) -> some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                if let date = selectedDate, 
                   let point = ratingsForChart.min(by: { abs($1.date.timeIntervalSince(date)) > abs($0.date.timeIntervalSince(date)) }) {
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
            
            if let date = selectedDate, let event = findClosestEvent(to: date, area: isLockedToArea ? selectedArea : internalSelectedArea) {
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
        .frame(height: 44)
    }
    
    private var emptyChartView: some View {
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
    }
    
    private func mainChart(ratingsForChart: [ChartPoint], currentArea: BodyArea?) -> some View {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!.addingTimeInterval(-1)
        
        let cutoff: Date = {
            switch period {
            case .day: return startOfToday
            case .week: return calendar.date(byAdding: .day, value: -6, to: startOfToday)!
            case .month: return calendar.date(byAdding: .day, value: -29, to: startOfToday)!
            }
        }()
        
        let chartDomain: ClosedRange<Date> = {
            switch period {
            case .day: return startOfToday...endOfToday
            default: return cutoff...now
            }
        }()
        
        return Chart {
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
            
            if let date = selectedDate {
                RuleMark(x: .value("Selected", date))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .zIndex(-1)
            }
            
            if period == .day {
                let dayFood = foodEntries.filter { $0.timestamp >= startOfToday && $0.timestamp <= endOfToday }
                ForEach(dayFood) { food in
                    RuleMark(x: .value("Дата", food.timestamp))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.foodRed.opacity(0.4))
                }
                
                let dayMeds = medicationEntries.filter { med in
                    guard med.timestamp >= startOfToday && med.timestamp <= endOfToday else { return false }
                    if let area = currentArea {
                        return med.bodyAreas.contains { $0.name == area.name }
                    }
                    return true
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
            switch period {
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
    
    private func prepareChartData(for area: BodyArea?) -> [ChartPoint] {
        let cutoff: Date = {
            let startOfToday = Calendar.current.startOfDay(for: Date())
            switch period {
            case .day: return startOfToday
            case .week: return Calendar.current.date(byAdding: .day, value: -6, to: startOfToday)!
            case .month: return Calendar.current.date(byAdding: .day, value: -29, to: startOfToday)!
            }
        }()
        
        let ratings: [BodyAreaRating]
        if let area = area {
            ratings = allRatings.filter { r in
                r.bodyArea?.name == area.name && r.timestamp >= cutoff && r.rating > 0
            }
        } else {
            ratings = allRatings.filter { $0.timestamp >= cutoff && $0.rating > 0 }
        }
        
        if period == .day {
            if area != nil {
                // For a specific area, show all points as is
                return ratings.map { ChartPoint(date: $0.timestamp, value: Double($0.rating)) }
                    .sorted { $0.date < $1.date }
            } else {
                // For overall health, group by 5 minutes to avoid vertical spikes from "Rate All"
                let interval: TimeInterval = 300 // 5 minutes
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
            // Group by day for longer periods
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
    
    private func findClosestEvent(to date: Date, area: BodyArea?) -> (emoji: String, name: String)? {
        let threshold: TimeInterval = 600
        
        let food = foodEntries.first { abs($0.timestamp.timeIntervalSince(date)) < threshold }
        if let food { return (food.foodItem?.emoji ?? "🍽", food.foodItem?.name ?? "Еда") }
        
        let med = medicationEntries.first { med in
            guard abs(med.timestamp.timeIntervalSince(date)) < threshold else { return false }
            if let area = area {
                return med.bodyAreas.contains { $0.name == area.name }
            }
            return true
        }
        if let med { return (med.medication?.emoji ?? "💊", med.medication?.name ?? "Лекарство") }
        
        return nil
    }
}

// Common models
public struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

public enum StatisticsTimePeriod: String, CaseIterable {
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
