import Foundation

struct AxisCalibration {
    var pixelToPrice: Double
    var confidence: Double
    var tickCount: Int
    var intercept: Double = 0

    func price(forPixel y: Double) -> Double {
        y * pixelToPrice + intercept
    }

    static let unavailable = AxisCalibration(pixelToPrice: 0, confidence: 0, tickCount: 0)
}

enum AnalysisRefusal: Identifiable, Equatable, Error {
    case unreadableImage
    case notAChart
    case axisMissing
    case modelFailure

    var id: Int { hashValue }

    var title: String {
        switch self {
        case .unreadableImage: return "We could not read that image"
        case .notAChart: return "This does not look like a price chart"
        case .axisMissing: return "The price axis is cropped"
        case .modelFailure: return "Analysis is unavailable right now"
        }
    }

    var detail: String {
        switch self {
        case .unreadableImage:
            return "The screenshot is blurry or too small. Take a clean, full-screen screenshot of the chart."
        case .notAChart:
            return "We need at least 15 visible candles to grade a chart. Open your charting app and capture the candle area."
        case .axisMissing:
            return "Without a readable price axis we cannot give real price levels, so we refuse instead of inventing them. Include the right-hand price scale in your screenshot."
        case .modelFailure:
            return "No AI engine answered. Add your own API key in Settings, or try again in a moment."
        }
    }

    var tips: [String] {
        switch self {
        case .axisMissing:
            return [
                "Include the right-side price scale in the screenshot.",
                "Do not crop the top or bottom of the chart.",
                "Use a normal zoom level so tick labels are legible."
            ]
        default:
            return [
                "Capture the chart area only, not the whole desktop.",
                "Avoid glare, motion blur, and heavy filters.",
                "Portrait and landscape screenshots are both supported."
            ]
        }
    }
}
