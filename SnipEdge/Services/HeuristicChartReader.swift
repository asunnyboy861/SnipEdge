import Foundation
import UIKit

enum ChartVisionError: Error {
    case noEngine
    case invalidResponse
    case transport
    case unauthorized
}

protocol ChartVisionClient {
    func analyze(image: UIImage, calibration: AxisCalibration) async throws -> ChartReading
}

enum ChartPrompt {
    static let system = """
    You are a chart-reading instrument, NOT an advisor. Output ONLY JSON matching:
    {"chart_type":"candles|line","instrument_guess":"string|null","timeframe_guess":"string|null",
     "pattern":{"name":"string|null","confidence":0-1},
     "trend":"up|down|range",
     "levels":[{"kind":"support|resistance","y_pixel":int,"confidence":0-1}],
     "notes":"string"}
    Rules: y_pixel = pixel row measured from the TOP of the image. If you cannot see the price axis,
    still report y_pixel values and set notes="AXIS_MISSING". Never invent absolute prices.
    """

    static let user = "Read this trading chart. Return JSON only."
}

enum ReadingParser {
    static func decode(from content: String) -> ChartReading? {
        guard let payload = extractJSON(from: content) else { return nil }
        guard let data = payload.data(using: .utf8) else { return nil }
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let chartType = raw["chart_type"] as? String ?? "candles"
        let instrument = raw["instrument_guess"] as? String
        let timeframe = raw["timeframe_guess"] as? String
        let pattern = raw["pattern"] as? [String: Any]
        let patternName = pattern?["name"] as? String
        let patternConfidence = pattern?["confidence"] as? Double ?? 0
        let trendRaw = raw["trend"] as? String ?? "range"
        let trend = ChartReading.Trend(rawValue: trendRaw) ?? .range
        let notes = raw["notes"] as? String ?? ""

        var levels: [ChartReading.LevelItem] = []
        if let levelArray = raw["levels"] as? [[String: Any]] {
            for item in levelArray {
                let kindRaw = item["kind"] as? String ?? "support"
                let kind: ChartReading.LevelItem.Kind = kindRaw == "resistance" ? .resistance : .support
                let y = item["y_pixel"] as? Double ?? (item["y_pixel"] as? Int).map(Double.init) ?? 0
                let confidence = item["confidence"] as? Double ?? 0.5
                levels.append(ChartReading.LevelItem(kind: kind, yPixel: y, confidence: confidence))
            }
        }

        return ChartReading(
            chartType: chartType,
            instrumentGuess: instrument,
            timeframeGuess: timeframe,
            patternName: patternName,
            patternConfidence: patternConfidence,
            trend: trend,
            levels: levels.sorted { $0.yPixel < $1.yPixel },
            notes: notes
        )
    }

    static func extractJSON(from content: String) -> String? {
        if let start = content.firstIndex(of: "{"), let end = content.lastIndex(of: "}") {
            return String(content[start ... end])
        }
        return nil
    }
}

struct HeuristicChartReader: ChartVisionClient {
    func analyze(image: UIImage, calibration: AxisCalibration) async throws -> ChartReading {
        guard let cgImage = image.cgImage else { throw ChartVisionError.invalidResponse }
        let width = 120
        let scale = Double(width) / Double(cgImage.width)
        let height = max(Int(Double(cgImage.height) * scale), 60)
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { throw ChartVisionError.invalidResponse }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var topRows: [Double] = []
        var bottomRows: [Double] = []
        var centroids: [Double] = []

        for x in 2 ..< width - 2 {
            var columnValues: [Int] = []
            for y in 2 ..< height - 2 {
                columnValues.append(Int(pixels[y * width + x]))
            }
            guard !columnValues.isEmpty else { continue }
            let sorted = columnValues.sorted()
            let median = sorted[sorted.count / 2]
            var top: Int?
            var bottom: Int?
            var sum = 0.0
            var count = 0.0
            for (offset, value) in columnValues.enumerated() {
                if abs(value - median) > 30 {
                    let row = Double(offset + 2)
                    if top == nil { top = Int(row) }
                    bottom = Int(row)
                    sum += row
                    count += 1
                }
            }
            if let top, let bottom, Double(bottom - top) >= 4 {
                topRows.append(Double(top))
                bottomRows.append(Double(bottom))
                centroids.append(sum / max(count, 1))
            }
        }

        guard !topRows.isEmpty, !bottomRows.isEmpty else { throw ChartVisionError.invalidResponse }

        let supportY = median(bottomRows)
        let resistanceY = median(topRows)

        let third = max(centroids.count / 3, 1)
        let firstAvg = centroids.prefix(third).reduce(0, +) / Double(third)
        let lastAvg = centroids.suffix(third).reduce(0, +) / Double(third)
        let threshold = Double(height) * 0.04

        let trend: ChartReading.Trend
        if firstAvg - lastAvg > threshold {
            trend = .up
        } else if lastAvg - firstAvg > threshold {
            trend = .down
        } else {
            trend = .range
        }

        let patternName: String
        switch trend {
        case .up: patternName = "Ascending structure"
        case .down: patternName = "Descending structure"
        case .range: patternName = "Range consolidation"
        }

        let levels = [
            ChartReading.LevelItem(kind: .support, yPixel: supportY, confidence: 0.6),
            ChartReading.LevelItem(kind: .resistance, yPixel: resistanceY, confidence: 0.6)
        ]

        return ChartReading(
            chartType: "candles",
            instrumentGuess: nil,
            timeframeGuess: nil,
            patternName: patternName,
            patternConfidence: 0.6,
            trend: trend,
            levels: levels,
            notes: "On-device read"
        )
    }

    private func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }
}
