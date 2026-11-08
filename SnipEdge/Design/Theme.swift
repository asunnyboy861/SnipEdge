import SwiftUI

enum Theme {
    static let background = Color(red: 0.055, green: 0.067, blue: 0.086)
    static let surface = Color(red: 0.086, green: 0.106, blue: 0.133)
    static let surfaceElevated = Color(red: 0.118, green: 0.145, blue: 0.180)
    static let brand = Color(red: 0.078, green: 0.722, blue: 0.651)
    static let up = Color(red: 0.133, green: 0.773, blue: 0.369)
    static let down = Color(red: 0.937, green: 0.267, blue: 0.267)
    static let warning = Color(red: 0.961, green: 0.620, blue: 0.043)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.62, green: 0.66, blue: 0.71)
    static let separator = Color.white.opacity(0.12)

    static func gradeColor(_ letter: String) -> Color {
        switch letter.uppercased() {
        case "A": return up
        case "B": return brand
        case "C": return warning
        case "D": return Color(red: 0.98, green: 0.45, blue: 0.20)
        default: return down
        }
    }

    static func price(_ value: Double) -> String {
        if value >= 1000 { return String(format: "%.2f", value) }
        if value >= 1 { return String(format: "%.2f", value) }
        return String(format: "%.4f", value)
    }
}
