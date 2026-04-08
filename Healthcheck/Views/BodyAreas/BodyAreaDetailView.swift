import SwiftUI
import SwiftData
import Charts

struct BodyAreaDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let bodyArea: BodyArea
    
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Неделя"
        case month = "Месяц"
        case threeMonths = "3 месяца"
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
    
    var filteredRatings: [BodyAreaRating] {
        let cutoff = Date().daysAgo(selectedPeriod.days)
        return bodyArea.ratings
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Status
                currentStatusCard
                
                // Period Selector
                Picker("Период", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Chart
                if !filteredRatings.isEmpty {
                    chartCard
                }
                
                // History
                historySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(bodyArea.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Current Status Card
    private var currentStatusCard: some View {
        VStack(spacing: 12) {
            Text(bodyArea.emoji)
                .font(.system(size: 60))
            
            if let rating = bodyArea.latestRating {
                HStack(spacing: 8) {
                    Text(RatingLabel.emoji(for: rating.rating))
                        .font(.title)
                    Text(RatingLabel.text(for: rating.rating))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.ratingColor(rating.rating))
                }
                
                Text("Последняя оценка: \(rating.timestamp.relativeString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Нет оценок")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }
    
    // MARK: - Chart
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Динамика")
                .font(.headline)
            
            Chart(filteredRatings) { rating in
                LineMark(
                    x: .value("Дата", rating.timestamp),
                    y: .value("Оценка", rating.rating)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.ratingColor(rating.rating))
                
                PointMark(
                    x: .value("Дата", rating.timestamp),
                    y: .value("Оценка", rating.rating)
                )
                .foregroundStyle(Color.ratingColor(rating.rating))
                .symbolSize(40)
            }
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
            .frame(height: 200)
        }
        .padding()
        .cardStyle()
    }
    
    // MARK: - History
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("История")
                .font(.headline)
            
            let sortedRatings = bodyArea.ratings.sorted { $0.timestamp > $1.timestamp }
            
            if sortedRatings.isEmpty {
                Text("Нет записей")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(sortedRatings.prefix(20)) { rating in
                    HStack {
                        RatingBadge(rating: rating.rating)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RatingLabel.text(for: rating.rating))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(rating.timestamp.relativeString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if !rating.note.isEmpty {
                            Text(rating.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if rating.id != sortedRatings.prefix(20).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}
