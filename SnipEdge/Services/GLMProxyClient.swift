import Foundation
import StoreKit
import UIKit

enum GLMError: LocalizedError {
    case proxyNotConfigured
    case rateLimited
    case badResponse
    case emptyContent
    case receiptRejected

    var errorDescription: String? {
        switch self {
        case .proxyNotConfigured: return "Cloud AI unavailable. Add your own API key in Settings."
        case .rateLimited: return "Too many cloud requests right now. Please try again later."
        case .badResponse: return "Cloud service error. Try again later."
        case .emptyContent: return "Cloud returned no result. Try again."
        case .receiptRejected: return "This is a Pro feature. Restore your purchase or subscribe to continue."
        }
    }
}

struct GLMProxyClient: ChartVisionClient {
    static let shared = GLMProxyClient()

    private let proxyURL = URL(string: "https://cramjam-api.calcs.top")!
    private let proxyFallbackURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!
    private let model = "glm-5.3-flash"
    private let appId = "snipedge"
    private let keychainService = "com.zzoutuo.SnipEdge"

    private var proxyDevKey: String? {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }

    var cloudAvailable: Bool { proxyDevKey != nil }

    private var userId: String {
        if let id = KeychainHelper.readString(service: keychainService, account: "proxy_user_id") { return id }
        let id = UUID().uuidString
        KeychainHelper.saveString(id, service: keychainService, account: "proxy_user_id")
        return id
    }

    func analyze(image: UIImage, calibration: AxisCalibration) async throws -> ChartReading {
        guard let jpeg = image.jpegData(compressionQuality: 0.8) else { throw ChartVisionError.invalidResponse }
        let content = try await chatWithImage(base64JPEG: jpeg.base64EncodedString())
        guard let reading = ReadingParser.decode(from: content) else { throw ChartVisionError.invalidResponse }
        return reading
    }

    func chatWithImage(base64JPEG: String, maxTokens: Int = 8192) async throws -> String {
        let messages: [[String: Any]] = [[
            "role": "user",
            "content": [
                ["type": "text", "text": ChartPrompt.system + "\n" + ChartPrompt.user],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64JPEG)"]]
            ]
        ]]
        var payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "thinking": ["level": "low"],
            "max_tokens": maxTokens,
            "temperature": 0,
            "response_format": ["type": "json_object"]
        ]
        var body: [String: Any] = [
            "appId": appId,
            "userId": userId,
            "payload": payload
        ]
        if let jws = await currentEntitlementJWS() {
            body["appTransaction"] = jws
        } else if let devKey = proxyDevKey {
            body["devKey"] = devKey
        } else {
            throw GLMError.proxyNotConfigured
        }
        payload = [:]
        return try await sendWithFallback(payload: body)
    }

    private func currentEntitlementJWS() async -> String? {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  transaction.productType == .autoRenewable
            else { continue }
            let jws = result.jwsRepresentation
            if !jws.isEmpty { return jws }
        }
        return nil
    }

    private func sendWithFallback(payload: [String: Any]) async throws -> String {
        do {
            return try await send(url: proxyURL, payload: payload)
        } catch GLMError.badResponse, GLMError.emptyContent {
            return try await send(url: proxyFallbackURL, payload: payload)
        }
    }

    private func send(url: URL, payload: [String: Any]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GLMError.badResponse }
        switch http.statusCode {
        case 200:
            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let content = message["content"] as? String,
                !content.isEmpty
            else { throw GLMError.emptyContent }
            return content
        case 401:
            throw GLMError.receiptRejected
        case 429:
            throw GLMError.rateLimited
        default:
            throw GLMError.badResponse
        }
    }
}
