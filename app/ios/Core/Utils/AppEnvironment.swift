import Foundation

enum AppEnvironment {
    static let defaultBaseURLString = "https://api.example.com"

    static var baseURL: URL {
        if
            let override = ProcessInfo.processInfo.environment["API_BASE_URL"],
            let url = URL(string: override) {
            return url
        }
        return URL(string: defaultBaseURLString)!
    }
}
