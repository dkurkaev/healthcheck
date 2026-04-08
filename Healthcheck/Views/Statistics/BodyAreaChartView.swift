import SwiftUI
import SwiftData
import Charts

struct BodyAreaChartView: View {
    let bodyArea: BodyArea
    let period: Int // days
    
    var filteredRatings: [BodyAreaRating] {
        let cutoff = Date().daysAgo(period)
        return bodyArea.ratings
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bodyArea.emoji)
                    .font(.title3)
                Text(bodyArea.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let latest = filteredRatings.last {
                    RatingBadge(rating: latest.rating)
                }
            }
            
            if filteredRatings.isEmpty {
                Text("Нет данных")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 60)
            } else {
                Chart(filteredRatings) { rating in
                    AreaMark(
                        x: .value("Дата", rating.timestamp),
                        y: .value("Оценка", rating.rating)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.ratingColor(rating.rating).opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Дата", rating.timestamp),
                        y: .value("Оценка", rating.rating)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.ratingColor(rating.rating))
                }
                .chartYScale(domain: 1...5)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 60)
            }
        }
        .padding()
        .cardStyle()
    }
}
