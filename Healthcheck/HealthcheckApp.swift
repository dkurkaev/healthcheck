import HealthcheckCore

@main
public struct HealthcheckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationService.shared.requestPermission()
                }
        }
        .modelContainer(for: [
            BodyArea.self,
            BodyAreaRating.self,
            FoodItem.self,
            FoodEntry.self,
            Medication.self,
            MedicationTemplate.self,
            MedicationEntry.self
        ]) { result in
            switch result {
            case .success(let container):
                let context = container.mainContext
                DataSeeder.seedDefaultBodyAreas(context: context)
            case .failure(let error):
                print("Failed to create model container: \(error)")
            }
        }
    }
}
