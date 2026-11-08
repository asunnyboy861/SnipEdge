import Foundation

struct ChartReading: Codable {
    enum Trend: String, Codable {
        case up, down, range
    }

    struct LevelItem: Codable, Identifiable, Hashable {
        enum Kind: String, Codable {
            case support, resistance
        }

        var id = UUID()
        var kind: Kind
        var yPixel: Double
        var confidence: Double
    }

    var chartType: String
    var instrumentGuess: String?
    var timeframeGuess: String?
    var patternName: String?
    var patternConfidence: Double
    var trend: Trend
    var levels: [LevelItem]
    var notes: String

    var axisMissing: Bool { notes.uppercased().contains("AXIS_MISSING") }

    static func empty(trend: Trend = .range) -> ChartReading {
        ChartReading(chartType: "candles", instrumentGuess: nil, timeframeGuess: nil, patternName: nil, patternConfidence: 0, trend: trend, levels: [], notes: "")
    }
}
