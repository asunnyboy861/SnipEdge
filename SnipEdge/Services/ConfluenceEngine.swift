import Foundation

struct ConfluenceEngine {
    struct WinRateStats {
        var rate: Double
        var sampleSize: Int
        var averageR: Double
    }

    static func grade(
        bars: [Bar],
        reading: ChartReading,
        levels: [VerifiedLevel],
        calibration: AxisCalibration
    ) -> GradeCard {
        let lastClose = bars.last?.close
        let verifiedRatio = ReconciliationService.ratio(of: levels)
        let allVerified = !levels.isEmpty && verifiedRatio == 1

        let score: Double
        var winRate: Double?
        var sampleSize = 0
        let atr: Double
        let entry: Double

        let supports = levels.filter { $0.kind == .support && $0.price > 0 }.sorted { $0.price > $1.price }
        let fallbackEntry = lastClose ?? (calibration.price(forPixel: 0) > 0 ? calibration.price(forPixel: 0) : 0)

        if bars.count >= 60 {
            let ema20 = bars.ema(20)
            let ema50 = bars.ema(50)
            let ema200 = bars.ema(200)
            let rsi = bars.rsi(14)
            let atrValue = bars.atr(14)
            let rvol = bars.relativeVolume(lag: 20)
            let latest = bars.last?.close ?? 0

            var total = 0.0
            total += trendAlignment(price: latest, ema20: ema20, ema50: ema50, ema200: ema200, trend: reading.trend)
            total += min(rvol / 2.5, 1) * 0.2
            total += rsiPosition(rsi: rsi, trend: reading.trend) * 0.2
            total += bars.atrExpansion(period: 14) * 0.2
            score = min(max(total, 0), 1)
            atr = atrValue > 0 ? atrValue : latest * 0.02
            entry = supports.first?.price ?? latest

            let stats = PatternStatsStore.estimate(bars: bars, pattern: reading.patternName, trend: reading.trend)
            if stats.sampleSize >= 30 {
                winRate = stats.rate
                sampleSize = stats.sampleSize
            }
        } else {
            let trendScore: Double
            switch reading.trend {
            case .up, .down: trendScore = 0.6
            case .range: trendScore = 0.3
            }
            let levelScore = min(Double(levels.count) / 3, 1)
            score = min(max(trendScore * 0.45 + levelScore * 0.25 + verifiedRatio * 0.30, 0), 1)
            atr = fallbackEntry > 0 ? fallbackEntry * 0.02 : 0
            entry = supports.first?.price ?? fallbackEntry
        }

        guard entry > 0, atr > 0 else {
            return GradeCard(
                letter: "F", verdict: "Not enough data for a plan", confluenceScore: 0, winRate: nil, sampleSize: 0,
                entry: 0, stop: 0, tp1: 0, tp2: 0, riskReward: 0, isVerified: false, verifiedRatio: verifiedRatio,
                symbol: reading.instrumentGuess ?? "Chart", timeframe: reading.timeframeGuess ?? "Unknown",
                patternName: reading.patternName ?? "No clear pattern", trend: reading.trend, levels: levels,
                reading: reading, createdAt: .now
            )
        }

        let stop = max(entry - 1.5 * atr, entry * 0.001)
        let risk = max(entry - stop, entry * 0.001)
        let tp1 = entry + 1.5 * risk
        let tp2 = entry + 3.0 * risk
        let rr = (tp2 - entry) / risk

        let letter = gradeLetter(score: score, verifiedRatio: verifiedRatio, hasLevels: !levels.isEmpty, winRate: winRate)
        return GradeCard(
            letter: letter,
            verdict: verdictText(letter: letter, verified: allVerified),
            confluenceScore: score,
            winRate: winRate,
            sampleSize: sampleSize,
            entry: entry,
            stop: stop,
            tp1: tp1,
            tp2: tp2,
            riskReward: rr,
            isVerified: allVerified,
            verifiedRatio: verifiedRatio,
            symbol: reading.instrumentGuess ?? "Chart",
            timeframe: reading.timeframeGuess ?? "Unknown",
            patternName: reading.patternName ?? "No clear pattern",
            trend: reading.trend,
            levels: levels,
            reading: reading,
            createdAt: .now
        )
    }

    private static func trendAlignment(price: Double, ema20: [Double], ema50: [Double], ema200: [Double], trend: ChartReading.Trend) -> Double {
        guard let e20 = ema20.last, let e50 = ema50.last, let e200 = ema200.last else { return 0 }
        let bullish = price > e20 && e20 > e50 && e50 > e200
        let bearish = price < e20 && e20 < e50 && e50 < e200
        switch trend {
        case .up: return bullish ? 0.4 : 0.2
        case .down: return bearish ? 0.4 : 0.2
        case .range: return (bullish || bearish) ? 0.15 : 0.3
        }
    }

    private static func rsiPosition(rsi: Double, trend: ChartReading.Trend) -> Double {
        switch trend {
        case .up:
            if rsi >= 50 && rsi < 70 { return 1 }
            if rsi >= 70 { return 0.4 }
            return 0.3
        case .down:
            if rsi <= 50 && rsi > 30 { return 1 }
            if rsi <= 30 { return 0.4 }
            return 0.3
        case .range:
            return rsi > 40 && rsi < 60 ? 1 : 0.4
        }
    }

    private static func gradeLetter(score: Double, verifiedRatio: Double, hasLevels: Bool, winRate: Double?) -> String {
        var letter: String
        switch score {
        case 0.8...1.0: letter = "A"
        case 0.65 ..< 0.8: letter = "B"
        case 0.5 ..< 0.65: letter = "C"
        case 0.35 ..< 0.5: letter = "D"
        default: letter = "F"
        }
        if !hasLevels || verifiedRatio < 0.5 {
            if ["A", "B"].contains(letter) { letter = "C" }
            if verifiedRatio == 0 && letter == "C" { letter = "D" }
        }
        if let winRate, winRate < 0.4, ["A", "B"].contains(letter) { letter = "C" }
        return letter
    }

    private static func verdictText(letter: String, verified: Bool) -> String {
        switch letter {
        case "A": return verified ? "High-confluence setup on verified levels" : "Strong structure, levels unverified"
        case "B": return verified ? "Solid setup with confirmed levels" : "Decent structure, verify levels"
        case "C": return "Mixed signals — manage risk carefully"
        case "D": return "Weak confluence — stay cautious"
        default: return "Structure does not support a plan"
        }
    }
}
