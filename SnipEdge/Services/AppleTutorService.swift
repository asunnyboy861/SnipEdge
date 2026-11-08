import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleTutorService {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return true }
        #endif
        return false
    }

    static func explain(card: GradeCard) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession(instructions: """
                You are a patient trading tutor. Explain in at most two short sentences, in plain English, \
                why this setup received this grade. Never give financial advice and never predict prices.
                """)
                let response = try await session.respond(to: prompt(card))
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { return text }
            } catch {}
        }
        #endif
        return fallback(card)
    }

    static func prompt(_ card: GradeCard) -> String {
        "Pattern: \(card.patternName); Grade: \(card.letter); Confluence: \(String(format: "%.2f", card.confluenceScore)); R:R: \(String(format: "%.1f", card.riskReward)); Market: \(card.symbol) \(card.timeframe)."
    }

    static func fallback(_ card: GradeCard) -> String {
        switch card.letter {
        case "A":
            return "Trend, momentum, and volume line up, and every level was confirmed against real market data. That combination is why this setup earns the top grade."
        case "B":
            return "Most signals agree and the structure is clean. One factor is softer than ideal, so position sizing still matters."
        case "C":
            return "Signals disagree or the levels could not be fully verified. Treat this as context, not a green light."
        case "D":
            return "The trend and momentum are not aligned, so the risk of a false move is high. Waiting for a clearer structure is the safer read."
        default:
            return "There is not enough structure here to build a plan around. Re-capture the chart with a readable price axis and clear candles."
        }
    }

    static func levelNote(for level: VerifiedLevel) -> String {
        if level.verified {
            return "This level was matched against a real high or low in the recent price history, so it is a level traders actually reacted to."
        }
        return "This level could not be matched to real price data within 1.5%. Treat it as an approximate area, not a precise entry."
    }

    static func riskNote(for card: GradeCard) -> String {
        "The stop sits \(String(format: "%.1f", card.riskPercent))% away from entry, which is 1.5 ATR. That keeps risk proportional to the chart's own volatility."
    }

    static func trendNote(for card: GradeCard) -> String {
        switch card.trend {
        case .up: return "Price structure is making higher lows, so the path of least resistance is upward."
        case .down: return "Price structure is making lower highs, so rallies are more likely to be sold."
        case .range: return "Price is contained between the same boundaries, so a breakout is the event to watch."
        }
    }
}
