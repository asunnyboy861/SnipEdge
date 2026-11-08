import Foundation

struct GradeCard: Codable {
    var letter: String
    var verdict: String
    var confluenceScore: Double
    var winRate: Double?
    var sampleSize: Int
    var entry: Double
    var stop: Double
    var tp1: Double
    var tp2: Double
    var riskReward: Double
    var isVerified: Bool
    var verifiedRatio: Double
    var symbol: String
    var timeframe: String
    var patternName: String
    var trend: ChartReading.Trend
    var levels: [VerifiedLevel]
    var reading: ChartReading
    var createdAt: Date

    var disclaimer: String { "Educational analysis only. Not financial advice." }

    var riskPercent: Double {
        guard entry > 0 else { return 0 }
        return abs(entry - stop) / entry * 100
    }
}
