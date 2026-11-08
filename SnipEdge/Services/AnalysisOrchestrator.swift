import Foundation
import CryptoKit
import UIKit

struct AnalysisResult {
    var card: GradeCard
    var imageHash: String
    var imageFileName: String
    var image: UIImage
    var usedOfficialEngine: Bool
    var usedBYOEngine: Bool
}

enum AnalysisEngine {
    case byo(BYOProfile)
    case official
    case onDevice
}

enum AnalysisOrchestrator {
    static func analyze(image: UIImage, engine: AnalysisEngine) async throws -> AnalysisResult {
        let normalized = VisionCaptureService.normalize(image)

        if let refusal = ImageQualityGate.evaluate(normalized) {
            throw refusal
        }

        let scan = await VisionCaptureService.scan(normalized)
        guard scan.calibration.confidence > 0.2, scan.calibration.tickCount >= 2 else {
            throw AnalysisRefusal.axisMissing
        }

        var bars: [Bar] = []
        if let symbol = scan.symbolGuess {
            bars = await MarketDataService.shared.bars(symbol: symbol, timeframe: scan.timeframeGuess)
        }

        var reading: ChartReading
        var usedOfficial = false
        var usedBYO = false

        switch engine {
        case .byo(let profile):
            guard let client = VisionClientFactory.client(for: profile) else {
                throw AnalysisRefusal.modelFailure
            }
            do {
                reading = try await client.analyze(image: normalized, calibration: scan.calibration)
                usedBYO = true
            } catch {
                throw AnalysisRefusal.modelFailure
            }
        case .official:
            do {
                reading = try await GLMProxyClient.shared.analyze(image: normalized, calibration: scan.calibration)
                usedOfficial = true
            } catch {
                reading = try await HeuristicChartReader().analyze(image: normalized, calibration: scan.calibration)
            }
        case .onDevice:
            reading = try await HeuristicChartReader().analyze(image: normalized, calibration: scan.calibration)
        }

        if scan.timeframeGuess != nil, reading.timeframeGuess == nil {
            reading.timeframeGuess = scan.timeframeGuess
        }
        if scan.symbolGuess != nil, reading.instrumentGuess == nil {
            reading.instrumentGuess = scan.symbolGuess
        }

        let levels = ReconciliationService.reconcile(reading: reading, calibration: scan.calibration, bars: bars)
        let card = ConfluenceEngine.grade(bars: bars, reading: reading, levels: levels, calibration: scan.calibration)

        let jpeg = normalized.jpegData(compressionQuality: 0.85) ?? Data()
        let hash = SHA256.hash(data: jpeg).map { String(format: "%02x", $0) }.joined()
        let fileName = "\(hash.prefix(24)).jpg"
        try? jpeg.write(to: imageDirectory().appendingPathComponent(fileName), options: .atomic)

        return AnalysisResult(
            card: card,
            imageHash: hash,
            imageFileName: fileName,
            image: normalized,
            usedOfficialEngine: usedOfficial,
            usedBYOEngine: usedBYO
        )
    }

    static func imageDirectory() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("Charts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    static func image(named fileName: String) -> UIImage? {
        UIImage(contentsOfFile: imageDirectory().appendingPathComponent(fileName).path)
    }
}
