import Foundation

struct Bar: Codable, Identifiable {
    var id: Date { date }
    var date: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double
}

extension Array where Element == Bar {
    func ema(_ period: Int) -> [Double] {
        guard !isEmpty, period > 0 else { return [] }
        let k = 2.0 / Double(period + 1)
        var result: [Double] = []
        var previous = self[0].close
        for bar in self {
            previous = bar.close * k + previous * (1 - k)
            result.append(previous)
        }
        return result
    }

    func rsi(_ period: Int = 14) -> Double {
        guard count > period else { return 50 }
        var gains: [Double] = []
        var losses: [Double] = []
        for index in 1 ..< count {
            let change = self[index].close - self[index - 1].close
            gains.append(Swift.max(change, 0))
            losses.append(Swift.max(-change, 0))
        }
        var averageGain = gains.prefix(period).reduce(0, +) / Double(period)
        var averageLoss = losses.prefix(period).reduce(0, +) / Double(period)
        for index in period ..< gains.count {
            averageGain = (averageGain * Double(period - 1) + gains[index]) / Double(period)
            averageLoss = (averageLoss * Double(period - 1) + losses[index]) / Double(period)
        }
        guard averageLoss > 0 else { return 100 }
        let rs = averageGain / averageLoss
        return 100 - 100 / (1 + rs)
    }

    func atr(_ period: Int = 14) -> Double {
        guard count > period else {
            guard let last = self.last else { return 0 }
            return Swift.max(last.high - last.low, last.close * 0.01)
        }
        var trueRanges: [Double] = []
        for index in 1 ..< count {
            let bar = self[index]
            let previousClose = self[index - 1].close
            let range = Swift.max(bar.high - bar.low, abs(bar.high - previousClose), abs(bar.low - previousClose))
            trueRanges.append(range)
        }
        guard !trueRanges.isEmpty else { return 0 }
        var average = trueRanges.prefix(period).reduce(0, +) / Double(period)
        for index in period ..< trueRanges.count {
            average = (average * Double(period - 1) + trueRanges[index]) / Double(period)
        }
        return average
    }

    func relativeVolume(lag: Int = 20) -> Double {
        guard count > lag + 1 else { return 1 }
        let recent = self[count - 1].volume
        let base = self.suffix(lag + 1).prefix(lag).map(\.volume)
        let average = base.reduce(0, +) / Double(Swift.max(base.count, 1))
        guard average > 0 else { return 1 }
        return recent / average
    }

    func atrExpansion(period: Int = 14) -> Double {
        guard count > period + 1 else { return 0.5 }
        let current = atr(period)
        let priorBars = Array(self.dropLast(period))
        let prior = priorBars.atr(period)
        guard prior > 0 else { return 0.5 }
        return Swift.min(current / prior, 2) / 2
    }
}
