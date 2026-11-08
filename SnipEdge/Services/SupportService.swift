import Foundation

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

enum SupportService {
    static let backendURL = "https://msg.calcs.top/api/feedback"

    static func submit(name: String, email: String, subject: String, message: String) async throws {
        guard let url = URL(string: backendURL) else { throw SupportError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = FeedbackRequest(name: name, email: email, subject: subject, message: message, app_name: "SnipEdge")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SupportError.server }
        guard (200 ..< 300).contains(http.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["error"] as? String {
                throw SupportError.message(message)
            }
            throw SupportError.server
        }
    }
}

enum SupportError: LocalizedError {
    case invalidURL
    case server
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The support service is misconfigured."
        case .server: return "Something went wrong. Please try again."
        case .message(let text): return text
        }
    }
}
