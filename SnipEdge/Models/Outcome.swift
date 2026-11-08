import Foundation

enum Outcome: String, Codable {
    case open
    case win
    case loss
    case ambiguous

    var label: String {
        switch self {
        case .open: return "OPEN"
        case .win: return "WIN"
        case .loss: return "LOSS"
        case .ambiguous: return "OPEN"
        }
    }

    var symbolName: String {
        switch self {
        case .open, .ambiguous: return "clock.fill"
        case .win: return "checkmark.circle.fill"
        case .loss: return "xmark.octagon.fill"
        }
    }
}
