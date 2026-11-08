import Foundation
import Combine

@MainActor
final class BYOEngineViewModel: ObservableObject {
    struct ConnectionState: Equatable {
        var message: String
        var success: Bool
    }

    @Published var profiles: [BYOProfile] = []
    @Published var provider: AIProvider = .glm
    @Published var baseURL: String = AIProvider.glm.defaultBaseURL
    @Published var model: String = AIProvider.glm.defaultModel
    @Published var supportsVision: Bool = true
    @Published var apiKeyInput: String = ""
    @Published var connection: ConnectionState?
    @Published var isTesting = false
    @Published var editingID: UUID?

    init() {
        reload()
    }

    func reload() {
        profiles = BYOEngineStore.loadProfiles()
    }

    func applyProviderDefaults() {
        baseURL = provider.defaultBaseURL
        model = provider.defaultModel
        supportsVision = provider.supportsVisionByDefault
    }

    var canSave: Bool {
        guard !baseURL.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard URL(string: baseURL) != nil else { return false }
        guard !model.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if editingID != nil, apiKeyInput.isEmpty { return true }
        return !apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func saveProfile() {
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespaces)
        let trimmedModel = model.trimmingCharacters(in: .whitespaces)
        let id = editingID ?? UUID()

        var profile = profiles.first(where: { $0.id == id }) ?? BYOProfile(
            id: id,
            provider: provider,
            baseURL: trimmedURL,
            model: trimmedModel,
            supportsVision: supportsVision,
            isActive: profiles.isEmpty
        )
        profile.provider = provider
        profile.baseURL = trimmedURL
        profile.model = trimmedModel
        profile.supportsVision = supportsVision

        if !apiKeyInput.isEmpty {
            BYOEngineStore.saveKey(apiKeyInput, for: id)
            profile.keySuffix = String(apiKeyInput.suffix(4))
        }

        var updated = profiles.filter { $0.id != id }
        updated.append(profile)
        if profile.isActive {
            updated = updated.map { item in
                var copy = item
                copy.isActive = item.id == id
                return copy
            }
        }
        BYOEngineStore.saveProfiles(updated)
        profiles = updated
        resetEditor()
    }

    func activate(_ profile: BYOProfile) {
        var updated = profiles.map { item -> BYOProfile in
            var copy = item
            copy.isActive = copy.id == profile.id
            return copy
        }
        if profile.supportsVision == false {
            updated = updated.map { item in
                var copy = item
                if copy.id == profile.id { copy.isActive = false }
                return copy
            }
        }
        BYOEngineStore.saveProfiles(updated)
        profiles = updated
    }

    func delete(_ profile: BYOProfile) {
        BYOEngineStore.deleteKey(for: profile.id)
        let updated = profiles.filter { $0.id != profile.id }
        BYOEngineStore.saveProfiles(updated)
        profiles = updated
        if editingID == profile.id { resetEditor() }
    }

    func beginEditing(_ profile: BYOProfile) {
        editingID = profile.id
        provider = profile.provider
        baseURL = profile.baseURL
        model = profile.model
        supportsVision = profile.supportsVision
        apiKeyInput = ""
    }

    func resetEditor() {
        editingID = nil
        apiKeyInput = ""
        connection = nil
        provider = .glm
        applyProviderDefaults()
    }

    func testConnection() async {
        isTesting = true
        connection = nil

        let candidate = BYOProfile(
            id: editingID ?? UUID(),
            provider: provider,
            baseURL: baseURL.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            supportsVision: supportsVision,
            isActive: false
        )
        let key = apiKeyInput.isEmpty ? BYOEngineStore.key(for: candidate.id) : apiKeyInput
        guard let key, !key.isEmpty else {
            connection = ConnectionState(message: "Enter an API key first.", success: false)
            isTesting = false
            return
        }

        do {
            try await BYOConnectionTester.test(profile: candidate, key: key)
            connection = ConnectionState(message: "Connected. Your key works.", success: true)
        } catch {
            connection = ConnectionState(message: "Connection failed. Check the key, URL, and model name.", success: false)
        }
        isTesting = false
    }
}

enum BYOConnectionTester {
    static func test(profile: BYOProfile, key: String) async throws {
        var request: URLRequest
        let body: [String: Any]
        if profile.provider == .claude {
            guard let url = URL(string: profile.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/messages") else {
                throw ChartVisionError.invalidResponse
            }
            request = URLRequest(url: url)
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            body = [
                "model": profile.model,
                "max_tokens": 8,
                "messages": [["role": "user", "content": "ping"]]
            ]
        } else {
            let trimmed = profile.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard let url = URL(string: trimmed + "/chat/completions") else {
                throw ChartVisionError.invalidResponse
            }
            request = URLRequest(url: url)
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            body = [
                "model": profile.model,
                "max_tokens": 8,
                "messages": [["role": "user", "content": "ping"]]
            ]
        }

        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChartVisionError.transport }
        guard (200 ..< 300).contains(http.statusCode) else { throw ChartVisionError.transport }
    }
}
