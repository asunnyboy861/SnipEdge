import Foundation

enum AIProvider: String, CaseIterable, Codable, Identifiable {
    case glm, openai, claude, gemini, deepseek, custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glm: return "GLM"
        case .openai: return "GPT"
        case .claude: return "Claude"
        case .gemini: return "Gemini"
        case .deepseek: return "DeepSeek"
        case .custom: return "Custom"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .glm: return "https://api.z.ai/api/paas/v4"
        case .openai: return "https://api.openai.com/v1"
        case .claude: return "https://api.anthropic.com"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .deepseek: return "https://api.deepseek.com/v1"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .glm: return "glm-4.6v"
        case .openai: return "gpt-4o"
        case .claude: return "claude-sonnet-4-5"
        case .gemini: return "gemini-2.0-flash"
        case .deepseek: return "deepseek-chat"
        case .custom: return ""
        }
    }

    var supportsVisionByDefault: Bool {
        self != .deepseek
    }
}

struct BYOProfile: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var provider: AIProvider
    var baseURL: String
    var model: String
    var supportsVision: Bool
    var isActive: Bool
    var keySuffix: String = ""
}
