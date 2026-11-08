import Foundation
import SwiftData

@Model
final class GradeRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var imageHash: String
    var imageFileName: String
    var symbol: String
    var timeframe: String
    var patternName: String
    var letter: String
    var verdict: String
    var confluenceScore: Double
    var winRate: Double
    var hasWinRate: Bool
    var sampleSize: Int
    var entry: Double
    var stop: Double
    var tp1: Double
    var tp2: Double
    var riskReward: Double
    var isVerified: Bool
    var verifiedRatio: Double
    var trendRaw: String
    var levelsData: Data
    var readingData: Data
    var outcomeRaw: String
    var resolvedAt: Date?

    init(id: UUID = UUID(), createdAt: Date = .now, imageHash: String, imageFileName: String, card: GradeCard) {
        self.id = id
        self.createdAt = createdAt
        self.imageHash = imageHash
        self.imageFileName = imageFileName
        self.symbol = card.symbol
        self.timeframe = card.timeframe
        self.patternName = card.patternName
        self.letter = card.letter
        self.verdict = card.verdict
        self.confluenceScore = card.confluenceScore
        self.winRate = card.winRate ?? 0
        self.hasWinRate = card.winRate != nil
        self.sampleSize = card.sampleSize
        self.entry = card.entry
        self.stop = card.stop
        self.tp1 = card.tp1
        self.tp2 = card.tp2
        self.riskReward = card.riskReward
        self.isVerified = card.isVerified
        self.verifiedRatio = card.verifiedRatio
        self.trendRaw = card.trend.rawValue
        self.levelsData = (try? JSONEncoder().encode(card.levels)) ?? Data()
        self.readingData = (try? JSONEncoder().encode(card.reading)) ?? Data()
        self.outcomeRaw = Outcome.open.rawValue
        self.resolvedAt = nil
    }

    var outcome: Outcome {
        get { Outcome(rawValue: outcomeRaw) ?? .open }
        set { outcomeRaw = newValue.rawValue }
    }

    var levels: [VerifiedLevel] {
        (try? JSONDecoder().decode([VerifiedLevel].self, from: levelsData)) ?? []
    }

    var reading: ChartReading {
        (try? JSONDecoder().decode(ChartReading.self, from: readingData)) ?? .empty()
    }

    var card: GradeCard {
        GradeCard(
            letter: letter,
            verdict: verdict,
            confluenceScore: confluenceScore,
            winRate: hasWinRate ? winRate : nil,
            sampleSize: sampleSize,
            entry: entry,
            stop: stop,
            tp1: tp1,
            tp2: tp2,
            riskReward: riskReward,
            isVerified: isVerified,
            verifiedRatio: verifiedRatio,
            symbol: symbol,
            timeframe: timeframe,
            patternName: patternName,
            trend: ChartReading.Trend(rawValue: trendRaw) ?? .range,
            levels: levels,
            reading: reading,
            createdAt: createdAt
        )
    }
}
