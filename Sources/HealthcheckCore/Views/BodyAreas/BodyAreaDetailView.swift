import SwiftUI
import SwiftData
import Charts

public struct BodyAreaDetailView: View { public init() {}
    @Environment(\.modelContext) private var modelContext
    let bodyArea: BodyArea
    
    @State private var selectedPeriod: StatisticsTimePeriod = .day
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Unified Interactive Chart (Locked to this area)
                HealthChartView(selectedArea: bodyArea, period: selectedPeriod, isLockedToArea: true)
                    .padding(.horizontal)
                
                // Period Selector
                Picker("Период", selection: $selectedPeriod) {
                    ForEach(StatisticsTimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // History List
                historySection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(bodyArea.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("История оценок")
                .font(.headline)
                .padding(.horizontal)
            
            let sortedRatings = bodyArea.ratings.sorted { $0.timestamp > $1.timestamp }
            
            if sortedRatings.isEmpty {
                Text("Нет записей")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedRatings.prefix(30)) { rating in
                        HStack(spacing: 12) {
                            RatingBadge(rating: rating.rating)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rating.timestamp.relativeString)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if !rating.note.isEmpty {
                                    Text(rating.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
                        if rating.id != sortedRatings.prefix(30).last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .cardStyle()
                .padding(.horizontal)
            }
        }
    }
}
