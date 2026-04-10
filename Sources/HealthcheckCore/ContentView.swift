import SwiftUI

public struct ContentView: View {
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            MainView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
            .tag(0)
            
            BodyAreasView()
                .tabItem {
                    Label("Тело", systemImage: "figure.stand")
                }
            .tag(1)
            
            StatisticsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.xyaxis.line")
                }
            .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
            .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            BodyArea.self, BodyAreaRating.self,
            FoodItem.self, FoodEntry.self,
            Medication.self, MedicationTemplate.self, MedicationEntry.self
        ], inMemory: true)
}
