import Foundation

enum AppEnvironment {
    static let defaultBaseURLString = "https://api.example.com"
    static let defaultUseMockService = true

    static var baseURL: URL {
        if
            let override = ProcessInfo.processInfo.environment["API_BASE_URL"],
            let url = URL(string: override) {
            return url
        }
        return URL(string: defaultBaseURLString)!
    }

    static var useMockService: Bool {
        if let override = ProcessInfo.processInfo.environment["USE_MOCK_SERVICE"] {
            return override == "1" || override.lowercased() == "true"
        }
        return defaultUseMockService
    }
}
