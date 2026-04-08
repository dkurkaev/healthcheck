import Foundation
import XLKit

struct ExcelExportService {
    
    static func generateXLSX(
        bodyAreas: [BodyArea],
        foodEntries: [FoodEntry],
        medicationEntries: [MedicationEntry]
    ) async -> Data? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        
        // 1. Create Workbook
        let workbook = Workbook()
        let headerFormat = CellFormat.header()
        
        // --- Sheet 1: Health State (Состояние) ---
        let s1 = workbook.addSheet(name: "Состояние")
        s1.setCell(row: 1, column: 1, cell: Cell.string("Дата", format: headerFormat))
        s1.setCell(row: 1, column: 2, cell: Cell.string("Зона", format: headerFormat))
        s1.setCell(row: 1, column: 3, cell: Cell.string("Оценка (балл)", format: headerFormat))
        s1.setCell(row: 1, column: 4, cell: Cell.string("Заметка", format: headerFormat))
        
        let allRatings = bodyAreas
            .flatMap { area in area.ratings.map { (area: area, rating: $0) } }
            .sorted { $0.rating.timestamp > $1.rating.timestamp }
        
        for (i, item) in allRatings.enumerated() {
            let row = i + 2
            s1.setCell(row: row, column: 1, cell: Cell.string(df.string(from: item.rating.timestamp)))
            s1.setCell(row: row, column: 2, cell: Cell.string(item.area.name))
            s1.setCell(row: row, column: 3, cell: Cell.integer(item.rating.rating))
            s1.setCell(row: row, column: 4, cell: Cell.string(item.rating.note))
        }
        
        // --- Sheet 2: Food (Еда) ---
        let s2 = workbook.addSheet(name: "Еда")
        s2.setCell(row: 1, column: 1, cell: Cell.string("Дата", format: headerFormat))
        s2.setCell(row: 1, column: 2, cell: Cell.string("Продукт", format: headerFormat))
        s2.setCell(row: 1, column: 3, cell: Cell.string("Опасность", format: headerFormat))
        s2.setCell(row: 1, column: 4, cell: Cell.string("Заметка", format: headerFormat))
        
        let sortedFood = foodEntries.sorted(by: { $0.timestamp > $1.timestamp })
        for (i, entry) in sortedFood.enumerated() {
            let row = i + 2
            s2.setCell(row: row, column: 1, cell: Cell.string(df.string(from: entry.timestamp)))
            s2.setCell(row: row, column: 2, cell: Cell.string(entry.foodItem?.name ?? ""))
            s2.setCell(row: row, column: 3, cell: Cell.integer(entry.foodItem?.dangerLevel ?? 0))
            s2.setCell(row: row, column: 4, cell: Cell.string(entry.note))
        }
        
        // --- Sheet 3: Medication (Лекарства) ---
        let s3 = workbook.addSheet(name: "Лекарства")
        s3.setCell(row: 1, column: 1, cell: Cell.string("Дата", format: headerFormat))
        s3.setCell(row: 1, column: 2, cell: Cell.string("Лекарство", format: headerFormat))
        s3.setCell(row: 1, column: 3, cell: Cell.string("Зоны", format: headerFormat))
        s3.setCell(row: 1, column: 4, cell: Cell.string("Заметка", format: headerFormat))
        
        let sortedMeds = medicationEntries.sorted(by: { $0.timestamp > $1.timestamp })
        for (i, entry) in sortedMeds.enumerated() {
            let row = i + 2
            let areas = entry.bodyAreas.map { $0.name }.joined(separator: ", ")
            s3.setCell(row: row, column: 1, cell: Cell.string(df.string(from: entry.timestamp)))
            s3.setCell(row: row, column: 2, cell: Cell.string(entry.medication?.name ?? ""))
            s3.setCell(row: row, column: 3, cell: Cell.string(areas))
            s3.setCell(row: row, column: 4, cell: Cell.string(entry.note))
        }
        
        // 2. Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Healthcheck_Export.xlsx")
        try? FileManager.default.removeItem(at: tempURL)
        
        do {
            try await workbook.save(to: tempURL)
            return try Data(contentsOf: tempURL)
        } catch {
            print("XLKit save error: \(error)")
            return nil
        }
    }
}
