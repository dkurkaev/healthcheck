import SwiftUI
import SwiftData

public struct CorrelationView: View { public init() {}
    @Query(sort: \BodyArea.sortOrder)
    private var bodyAreas: [BodyArea]
    
    @Query(sort: \FoodItem.createdAt, order: .reverse)
    private var foodItems: [FoodItem]
    
    @Query(sort: \Medication.createdAt, order: .reverse)
    private var medications: [Medication]
    
    @State private var selectedBodyArea: BodyArea?
    @State private var analysisType: AnalysisType = .food
    
    enum AnalysisType: String, CaseIterable {
        case food = "Еда"
        case medication = "Лекарства"
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Analysis Type
                Picker("Тип", selection: $analysisType) {
                    ForEach(AnalysisType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Body Area Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Зона тела")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(bodyAreas) { area in
                                Button(action: { selectedBodyArea = area }) {
                                    HStack(spacing: 4) {
                                        Text(area.emoji)
                                        Text(area.name)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedBodyArea?.id == area.id
                                            ? Color.blue.opacity(0.2)
                                            : Color(.tertiarySystemBackground)
                                    )
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Results
                if let area = selectedBodyArea {
                    switch analysisType {
                    case .food:
                        foodCorrelation(for: area)
                    case .medication:
                        medicationCorrelation(for: area)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("Выберите зону тела для анализа")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Корреляции")
    }
    
    // MARK: - Food Correlation
    private func foodCorrelation(for area: BodyArea) -> some View {
        let ratings = area.ratings.sorted { $0.timestamp < $1.timestamp }
        
        let correlations: [(FoodItem, Double, Int)] = foodItems.compactMap { food in
            let foodDates = food.entries.map { $0.timestamp }
            guard !foodDates.isEmpty else { return nil }
            
            // Simple correlation: average rating in 3 days after eating vs overall average
            let overallAvg = ratings.isEmpty ? 3.0 : Double(ratings.map(\.rating).reduce(0, +)) / Double(ratings.count)
            
            var afterFoodRatings: [Int] = []
            for entry in food.entries {
                let after = ratings.filter {
                    $0.timestamp > entry.timestamp &&
                    $0.timestamp <= Calendar.current.date(byAdding: .day, value: 3, to: entry.timestamp)!
                }
                afterFoodRatings.append(contentsOf: after.map(\.rating))
            }
            
            guard !afterFoodRatings.isEmpty else { return nil }
            
            let afterAvg = Double(afterFoodRatings.reduce(0, +)) / Double(afterFoodRatings.count)
            let impact = afterAvg - overallAvg // positive = better (higher rating = better health)
            
            return (food, impact, afterFoodRatings.count)
        }
        .sorted { abs($0.1) > abs($1.1) }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Влияние еды на: \(area.emoji) \(area.name)")
                .font(.headline)
                .padding(.horizontal)
            
            if correlations.isEmpty {
                Text("Недостаточно данных. Продолжайте вести записи!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                Text("Разница среднего рейтинга после употребления vs общий средний\n(↑ = лучше, ↓ = хуже, шкала 1-5 где 5 = отлично)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                ForEach(correlations, id: \.0.id) { food, impact, count in
                    CorrelationRow(
                        emoji: food.emoji,
                        name: food.name,
                        impact: impact,
                        count: count
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Medication Correlation
    private func medicationCorrelation(for area: BodyArea) -> some View {
        let ratings = area.ratings.sorted { $0.timestamp < $1.timestamp }
        
        let correlations: [(Medication, Double, Int)] = medications.compactMap { med in
            let medEntries = med.entries.filter { entry in
                entry.bodyAreas.contains(where: { $0.id == area.id })
            }
            guard !medEntries.isEmpty else { return nil }
            
            let overallAvg = ratings.isEmpty ? 3.0 : Double(ratings.map(\.rating).reduce(0, +)) / Double(ratings.count)
            
            var afterMedRatings: [Int] = []
            for entry in medEntries {
                let after = ratings.filter {
                    $0.timestamp > entry.timestamp &&
                    $0.timestamp <= Calendar.current.date(byAdding: .day, value: 3, to: entry.timestamp)!
                }
                afterMedRatings.append(contentsOf: after.map(\.rating))
            }
            
            guard !afterMedRatings.isEmpty else { return nil }
            
            let afterAvg = Double(afterMedRatings.reduce(0, +)) / Double(afterMedRatings.count)
            let impact = afterAvg - overallAvg
            
            return (med, impact, afterMedRatings.count)
        }
        .sorted { abs($0.1) > abs($1.1) }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Влияние лекарств на: \(area.emoji) \(area.name)")
                .font(.headline)
                .padding(.horizontal)
            
            if correlations.isEmpty {
                Text("Недостаточно данных. Продолжайте вести записи!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                Text("Разница среднего рейтинга после применения vs общий средний\n(↑ = лучше, ↓ = хуже)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                ForEach(correlations, id: \.0.id) { med, impact, count in
                    CorrelationRow(
                        emoji: med.emoji,
                        name: med.name,
                        impact: impact,
                        count: count
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Correlation Row
public struct CorrelationRow: View { public init() {}
    let emoji: String
    let name: String
    let impact: Double
    let count: Int
    
    var impactColor: Color {
        if impact > 0.3 { return .green }        // Improvement (higher = better)
        if impact < -0.3 { return .red }          // Worsening
        return .orange                            // Neutral
    }
    
    var impactText: String {
        if impact > 0.3 { return "Улучшает" }
        if impact < -0.3 { return "Ухудшает" }
        return "Нейтрально"
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(impactColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(count) измерений")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(impactText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(impactColor)
                
                Text(String(format: "%+.1f", impact))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            
            // Impact bar
            RoundedRectangle(cornerRadius: 4)
                .fill(impactColor)
                .frame(width: 4, height: 30)
        }
        .padding()
        .cardStyle()
    }
}
