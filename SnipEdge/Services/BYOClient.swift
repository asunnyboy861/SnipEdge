import Foundation
import UIKit

enum BYOEngineStore {
    private static let profilesKey = "snipedge.byo.profiles"
    private static let keyService = "com.zzoutuo.SnipEdge.byo"

    static func loadProfiles() -> [BYOProfile] {
        guard let data = UserDefaults.standard.data(forKey: profilesKey) else { return [] }
        return (try? JSONDecoder().decode([BYOProfile].self, from: data)) ?? []
    }

    static func saveProfiles(_ profiles: [BYOProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: profilesKey)
    }

    static func key(for id: UUID) -> String? {
        KeychainHelper.readString(service: keyService, account: id.uuidString)
    }

    static func saveKey(_ key: String, for id: UUID) {
        KeychainHelper.saveString(key, service: keyService, account: id.uuidString)
    }

    static func deleteKey(for id: UUID) {
        KeychainHelper.delete(service: keyService, account: id.uuidString)
    }

    static var activeProfile: BYOProfile? {
        loadProfiles().first { $0.isActive && $0.supportsVision }
    }
}

struct OpenAICompatibleClient: ChartVisionClient {
    let baseURL: String
    let apiKey: String
    let model: String

    func analyze(image: UIImage, calibration: AxisCalibration) async throws -> ChartReading {
        guard let url = chatURL else { throw ChartVisionError.invalidResponse }
        guard let jpeg = image.jpegData(compressionQuality: 0.8) else { throw ChartVisionError.invalidResponse }
        let dataURL = "data:image/jpeg;base64,\(jpeg.base64EncodedString())"

        let body: [String: Any] = [
            "model": model,
            "temperature": 0,
            "messages": [
                ["role": "system", "content": ChartPrompt.system],
                ["role": "user", "content": [
                    ["type": "image_url", "image_url": ["url": dataURL]],
                    ["type": "text", "text": ChartPrompt.user]
                ]]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChartVisionError.transport }
        if http.statusCode == 401 || http.statusCode == 403 { throw ChartVisionError.unauthorized }
        guard (200 ..< 300).contains(http.statusCode) else { throw ChartVisionError.transport }

        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = root["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw ChartVisionError.invalidResponse }

        guard let reading = ReadingParser.decode(from: content) else { throw ChartVisionError.invalidResponse }
        return reading
    }

    private var chatURL: URL? {
        guard var base = URL(string: baseURL) else { return nil }
        if base.path.contains("/chat/completions") { return base }
        if base.path.hasSuffix("/") {
            base = base.appendingPathComponent("chat/completions")
        } else {
            base = base.appendingPathComponent("chat/completions")
        }
        return base
    }
}

struct AnthropicClient: ChartVisionClient {
    let baseURL: String
    let apiKey: String
    let model: String

    func analyze(image: UIImage, calibration: AxisCalibration) async throws -> ChartReading {
        guard let url = URL(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/messages") else {
            throw ChartVisionError.invalidResponse
        }
        guard let jpeg = image.jpegData(compressionQuality: 0.8) else { throw ChartVisionError.invalidResponse }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "temperature": 0,
            "system": ChartPrompt.system,
            "messages": [
                ["role": "user", "content": [
                    ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": jpeg.base64EncodedString()]],
                    ["type": "text", "text": ChartPrompt.user]
                ]]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChartVisionError.transport }
        if http.statusCode == 401 { throw ChartVisionError.unauthorized }
        guard (200 ..< 300).contains(http.statusCode) else { throw ChartVisionError.transport }

        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = root["content"] as? [[String: Any]],
            let text = content.first?["text"] as? String
        else { throw ChartVisionError.invalidResponse }

        guard let reading = ReadingParser.decode(from: text) else { throw ChartVisionError.invalidResponse }
        return reading
    }
}

enum VisionClientFactory {
    static func client(for profile: BYOProfile) -> ChartVisionClient? {
        guard let key = BYOEngineStore.key(for: profile.id), !key.isEmpty else { return nil }
        switch profile.provider {
        case .claude:
            return AnthropicClient(baseURL: profile.baseURL, apiKey: key, model: profile.model)
        default:
            return OpenAICompatibleClient(baseURL: profile.baseURL, apiKey: key, model: profile.model)
        }
    }
}
