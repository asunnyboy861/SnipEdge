import Foundation

enum ReconciliationService {
    static let tolerance: Double = 0.015

    static func reconcile(reading: ChartReading, calibration: AxisCalibration, bars: [Bar]) -> [VerifiedLevel] {
        let recent = Array(bars.suffix(120))
        return reading.levels.map { level in
            let price = calibration.price(forPixel: level.yPixel)
            var matched = false
            var delta: Double?
            if !recent.isEmpty, price > 0 {
                for bar in recent {
                    let highDelta = abs(bar.high - price) / price
                    let lowDelta = abs(bar.low - price) / price
                    let closeDelta = abs(bar.close - price) / price
                    let best = min(highDelta, lowDelta, closeDelta)
                    if best <= tolerance {
                        matched = true
                        delta = best
                        break
                    }
                }
            }
            return VerifiedLevel(
                kind: level.kind == .support ? .support : .resistance,
                price: price,
                yPixel: level.yPixel,
                confidence: level.confidence,
                verified: matched,
                deltaPercent: delta
            )
        }
    }

    static func ratio(of levels: [VerifiedLevel]) -> Double {
        guard !levels.isEmpty else { return 0 }
        let verified = levels.filter(\.verified).count
        return Double(verified) / Double(levels.count)
    }
}
