import Foundation
import SwiftData

/// Generates XML Spreadsheet 2003 format (.xls) with multiple sheets
/// This format is natively supported by Excel, Numbers, and Google Sheets
struct ExcelExportService {
    
    static func generateWorkbook(
        bodyAreas: [BodyArea],
        foodEntries: [FoodEntry],
        medicationEntries: [MedicationEntry]
    ) -> Data? {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <?mso-application progid="Excel.Sheet"?>
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
         xmlns:o="urn:schemas-microsoft-com:office:office"
         xmlns:x="urn:schemas-microsoft-com:office:excel"
         xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
         <Styles>
          <Style ss:ID="Header">
           <Font ss:Bold="1"/>
          </Style>
         </Styles>
        
        """
        
        // Sheet 1: Body Area Ratings
        xml += bodyAreaRatingsSheet(bodyAreas: bodyAreas)
        // Sheet 2: Food History
        xml += foodHistorySheet(foodEntries: foodEntries)
        // Sheet 3: Medication History
        xml += medicationHistorySheet(medicationEntries: medicationEntries)
        
        xml += "</Workbook>"
        return xml.data(using: .utf8)
    }
    
    private static func bodyAreaRatingsSheet(bodyAreas: [BodyArea]) -> String {
        let allRatings = bodyAreas
            .flatMap { area in area.ratings.map { (area: area, rating: $0) } }
            .sorted { $0.rating.timestamp > $1.rating.timestamp }
        
        var sheet = " <Worksheet ss:Name=\"Состояние тела\"><Table>"
        sheet += "<Row ss:StyleID=\"Header\">"
        + "<Cell><Data ss:Type=\"String\">Дата</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Зона</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Оценка</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Заметка</Data></Cell>"
        + "</Row>"
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        
        for item in allRatings {
            sheet += "<Row>"
            + "<Cell><Data ss:Type=\"String\">\(df.string(from: item.rating.timestamp))</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(item.area.emoji) \(escapeXML(item.area.name))</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(item.rating.rating) (\(RatingLabel.text(for: item.rating.rating)))</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(escapeXML(item.rating.note))</Data></Cell>"
            + "</Row>"
        }
        sheet += "</Table></Worksheet>"
        return sheet
    }
    
    private static func foodHistorySheet(foodEntries: [FoodEntry]) -> String {
        var sheet = " <Worksheet ss:Name=\"История еды\"><Table>"
        sheet += "<Row ss:StyleID=\"Header\">"
        + "<Cell><Data ss:Type=\"String\">Дата</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Продукт</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Опасность</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Заметка</Data></Cell>"
        + "</Row>"
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        
        for entry in foodEntries.sorted(by: { $0.timestamp > $1.timestamp }) {
            sheet += "<Row>"
            + "<Cell><Data ss:Type=\"String\">\(df.string(from: entry.timestamp))</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(entry.foodItem?.emoji ?? "") \(escapeXML(entry.foodItem?.name ?? ""))</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(entry.foodItem?.dangerLevel ?? 0)</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(escapeXML(entry.note))</Data></Cell>"
            + "</Row>"
        }
        sheet += "</Table></Worksheet>"
        return sheet
    }
    
    private static func medicationHistorySheet(medicationEntries: [MedicationEntry]) -> String {
        var sheet = " <Worksheet ss:Name=\"История лекарств\"><Table>"
        sheet += "<Row ss:StyleID=\"Header\">"
        + "<Cell><Data ss:Type=\"String\">Дата</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Лекарство</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Зоны</Data></Cell>"
        + "<Cell><Data ss:Type=\"String\">Заметка</Data></Cell>"
        + "</Row>"
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        
        for entry in medicationEntries.sorted(by: { $0.timestamp > $1.timestamp }) {
            let areas = entry.bodyAreas.map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")
            sheet += "<Row>"
            + "<Cell><Data ss:Type=\"String\">\(df.string(from: entry.timestamp))</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(entry.medication?.emoji ?? "") \(escapeXML(entry.medication?.name ?? ""))</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(escapeXML(areas))</Data></Cell>"
            + "<Cell><Data ss:Type=\"String\">\(escapeXML(entry.note))</Data></Cell>"
            + "</Row>"
        }
        sheet += "</Table></Worksheet>"
        return sheet
    }
    
    private static func escapeXML(_ str: String) -> String {
        str.replacingOccurrences(of: "&", with: "&amp;")
           .replacingOccurrences(of: "<", with: "&lt;")
           .replacingOccurrences(of: ">", with: "&gt;")
           .replacingOccurrences(of: "\"", with: "&quot;")
           .replacingOccurrences(of: "'", with: "&apos;")
    }
}
