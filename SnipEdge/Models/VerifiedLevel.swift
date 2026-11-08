import Foundation

struct VerifiedLevel: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case support, resistance
    }

    var id = UUID()
    var kind: Kind
    var price: Double
    var yPixel: Double
    var confidence: Double
    var verified: Bool
    var deltaPercent: Double?
}
