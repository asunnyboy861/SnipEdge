import Foundation
import SwiftData

struct ProofStats {
    var total: Int
    var wins: Int
    var losses: Int
    var winRate: Double
    var averageR: Double
    var currentStreak: Int
    var bestStreak: Int
}

enum OutcomeTracker {
    static let resolutionDelay: TimeInterval = 72 * 3600

    static func resolvePending(context: ModelContext) async {
        let descriptor = FetchDescriptor<GradeRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let records = try? context.fetch(descriptor) else { return }
        let cutoff = Date().addingTimeInterval(-resolutionDelay)

        for record in records where record.outcome == .open && record.createdAt <= cutoff {
            guard record.symbol != "Chart" else { continue }
            let bars = await MarketDataService.shared.bars(symbol: record.symbol, timeframe: record.timeframe)
            guard !bars.isEmpty else { continue }
            let outcome = resolve(record: record, bars: bars)
            if outcome != .open {
                record.outcome = outcome
                record.resolvedAt = .now
            }
        }
        try? context.save()
    }

    static func resolve(record: GradeRecord, bars: [Bar]) -> Outcome {
        for bar in bars where bar.date > record.createdAt {
            let hitStop = bar.low <= record.stop
            let hitTarget = bar.high >= record.tp1
            if hitStop && hitTarget { return .ambiguous }
            if hitStop { return .loss }
            if hitTarget { return .win }
        }
        return .open
    }

    static func stats(from records: [GradeRecord]) -> ProofStats {
        let resolved = records.filter { $0.outcome == .win || $0.outcome == .loss }
        let wins = resolved.filter { $0.outcome == .win }.count
        let losses = resolved.filter { $0.outcome == .loss }.count
        let total = wins + losses
        let winRate = total > 0 ? Double(wins) / Double(total) : 0
        let averageR = total > 0
            ? resolved.reduce(0.0) { partial, record in
                partial + (record.outcome == .win ? 1.5 : -1.0)
            } / Double(total)
            : 0

        var currentStreak = 0
        for record in records.sorted(by: { $0.createdAt > $1.createdAt }) {
            if record.outcome == .win {
                currentStreak += 1
            } else if record.outcome == .loss {
                break
            }
        }

        var bestStreak = 0
        var running = 0
        for record in resolved.sorted(by: { $0.createdAt < $1.createdAt }) {
            if record.outcome == .win {
                running += 1
                bestStreak = Swift.max(bestStreak, running)
            } else {
                running = 0
            }
        }

        return ProofStats(total: total, wins: wins, losses: losses, winRate: winRate, averageR: averageR, currentStreak: currentStreak, bestStreak: bestStreak)
    }
}
