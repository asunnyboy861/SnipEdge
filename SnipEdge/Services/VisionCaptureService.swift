import Foundation
import UIKit
import Vision

struct AxisScanResult {
    var calibration: AxisCalibration
    var timeframeGuess: String?
    var symbolGuess: String?
    var rawTexts: [String]
    var tickValues: [Double]
}

enum VisionCaptureService {
    static func normalize(_ image: UIImage) -> UIImage {
        let maxEdge: CGFloat = 1440
        let longest = max(image.size.width, image.size.height)
        guard longest > maxEdge else { return image }
        let scale = maxEdge / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    static func scan(_ image: UIImage) async -> AxisScanResult {
        guard let cgImage = image.cgImage else {
            return AxisScanResult(calibration: .unavailable, timeframeGuess: nil, symbolGuess: nil, rawTexts: [], tickValues: [])
        }
        let height = Double(cgImage.height)

        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])

            let observations = request.results ?? []
            var texts: [String] = []
            var rightTicks: [(pixel: Double, value: Double)] = []
            var leftTicks: [(pixel: Double, value: Double)] = []

            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let text = candidate.string
                texts.append(text)
                let box = observation.boundingBox
                let midY = 1 - (box.origin.y + box.height / 2)
                let midX = box.origin.x + box.width / 2
                if midX > 0.72 {
                    if let value = parseNumber(text) {
                        rightTicks.append((midY * height, value))
                    }
                } else if midX < 0.28 {
                    if let value = parseNumber(text) {
                        leftTicks.append((midY * height, value))
                    }
                }
            }

            let ticks = rightTicks.count >= leftTicks.count ? rightTicks : leftTicks
            let timeframe = guessTimeframe(texts)
            let symbol = guessSymbol(texts)
            let calibration = calibrate(ticks: ticks, imageHeight: height)
            let values = ticks.sorted { $0.pixel < $1.pixel }.map(\.value)
            return AxisScanResult(calibration: calibration, timeframeGuess: timeframe, symbolGuess: symbol, rawTexts: texts, tickValues: values)
        }.value
    }

    static func parseNumber(_ text: String) -> Double? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        cleaned = cleaned.replacingOccurrences(of: "%", with: "")
        cleaned = cleaned.replacingOccurrences(of: "$", with: "")
        cleaned = cleaned.replacingOccurrences(of: "-", with: "")
        cleaned = cleaned.replacingOccurrences(of: "k", with: "000", options: .caseInsensitive)
        var digits = ""
        for character in cleaned {
            if character.isNumber || character == "." {
                digits.append(character)
            }
        }
        guard let value = Double(digits), value > 0 else { return nil }
        return value
    }

    static func guessTimeframe(_ texts: [String]) -> String? {
        let patterns: [(String, String)] = [
            ("1W", "1W"), ("Weekly", "1W"),
            ("1D", "1D"), ("Daily", "1D"),
            ("4H", "4H"), ("4h", "4H"),
            ("1H", "1H"), ("1h", "1H"), ("60m", "1H"),
            ("15m", "15m"), ("15M", "15m"),
            ("5m", "5m"), ("5M", "5m"),
            ("1m", "1m"), ("1M", "1m")
        ]
        for text in texts {
            for (needle, value) in patterns where text.contains(needle) {
                return value
            }
        }
        return nil
    }

    static func guessSymbol(_ texts: [String]) -> String? {
        for text in texts {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 1, trimmed.count <= 6 else { continue }
            guard trimmed.allSatisfy({ $0.isUppercase || $0.isNumber || $0 == "." }) else { continue }
            guard trimmed.contains(where: { $0.isLetter }) else { continue }
            let lowercaseWords: Set<String> = ["BUY", "SELL", "OPEN", "HIGH", "LOW", "CLOSE", "VOL", "RSI"]
            if lowercaseWords.contains(trimmed) { continue }
            return trimmed
        }
        return nil
    }

    static func calibrate(ticks: [(pixel: Double, value: Double)], imageHeight: Double) -> AxisCalibration {
        guard ticks.count >= 2 else { return .unavailable }
        let sortedValues = ticks.map(\.value).sorted()
        let medianValue = sortedValues[sortedValues.count / 2]
        guard medianValue > 0 else { return .unavailable }
        let filtered = ticks.filter { abs($0.value - medianValue) / medianValue < 0.6 }
        guard filtered.count >= 2 else { return .unavailable }
        let uniqueValues = Set(filtered.map { String(format: "%.2f", $0.value) })
        guard uniqueValues.count >= 2 else { return .unavailable }

        let xs = filtered.map(\.pixel)
        let ys = filtered.map(\.value)
        let meanX = xs.reduce(0, +) / Double(xs.count)
        let meanY = ys.reduce(0, +) / Double(ys.count)
        var numerator = 0.0
        var denominator = 0.0
        for index in 0 ..< filtered.count {
            numerator += (xs[index] - meanX) * (ys[index] - meanY)
            denominator += (xs[index] - meanX) * (xs[index] - meanX)
        }
        guard denominator > 0 else { return .unavailable }
        let slope = numerator / denominator
        let intercept = meanY - slope * meanX
        guard abs(slope) > 0 else { return .unavailable }

        var totalVariation = 0.0
        var residual = 0.0
        for index in 0 ..< filtered.count {
            totalVariation += (ys[index] - meanY) * (ys[index] - meanY)
            let predicted = slope * xs[index] + intercept
            residual += (ys[index] - predicted) * (ys[index] - predicted)
        }
        let rSquared = totalVariation > 0 ? max(0, 1 - residual / totalVariation) : 0
        let confidence = min(max(rSquared, 0), 1)
        guard confidence > 0.2 else { return .unavailable }

        return AxisCalibration(pixelToPrice: slope, confidence: confidence, tickCount: filtered.count, intercept: intercept)
    }
}
