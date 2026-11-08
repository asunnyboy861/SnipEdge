import Foundation

enum PatternStatsStore {
    struct Estimate {
        var rate: Double
        var sampleSize: Int
        var averageR: Double
    }

    static func estimate(bars: [Bar], pattern: String?, trend: ChartReading.Trend) -> Estimate {
        guard bars.count >= 90 else { return Estimate(rate: 0, sampleSize: 0, averageR: 0) }
        let ema20 = bars.ema(20)
        let ema50 = bars.ema(50)

        var wins = 0
        var losses = 0
        var rTotal = 0.0
        var index = 60
        while index < bars.count - 20 {
            let close = bars[index].close
            let atrValue = Array(bars[0 ... index]).atr(14)
            guard atrValue > 0 else { index += 1; continue }

            let bullish = ema20[index] > ema50[index] && close > bars[index].open
            let bearish = ema20[index] < ema50[index] && close < bars[index].open
            let matchesTrend: Bool
            switch trend {
            case .up: matchesTrend = bullish
            case .down: matchesTrend = bearish
            case .range: matchesTrend = false
            }

            if matchesTrend {
                let priorHigh = bars[(index - 10) ..< index].map(\.high).max() ?? close
                let priorLow = bars[(index - 10) ..< index].map(\.low).min() ?? close
                let brokeOut = bullish ? close > priorHigh : close < priorLow
                if brokeOut {
                    let risk = 1.5 * atrValue
                    let entry = close
                    let stop = bullish ? entry - risk : entry + risk
                    let target = bullish ? entry + 2.25 * atrValue : entry - 2.25 * atrValue
                    var result = false
                    var hitStop = false
                    for offset in 1 ... 20 where index + offset < bars.count {
                        let bar = bars[index + offset]
                        if bullish {
                            if bar.low <= stop { hitStop = true; break }
                            if bar.high >= target { result = true; break }
                        } else {
                            if bar.high >= stop { hitStop = true; break }
                            if bar.low <= target { result = true; break }
                        }
                    }
                    if result { wins += 1; rTotal += 1.5 } else if hitStop { losses += 1; rTotal -= 1.0 }
                }
            }
            index += 1
        }

        let sample = wins + losses
        let rate = sample > 0 ? Double(wins) / Double(sample) : 0
        let averageR = sample > 0 ? rTotal / Double(sample) : 0
        return Estimate(rate: rate, sampleSize: sample, averageR: averageR)
    }
}
