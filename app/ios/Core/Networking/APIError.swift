import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "error.invalid_api_url")
        case .invalidResponse:
            return String(localized: "error.invalid_server_response")
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message ?? String(localized: "error.request_failed"))"
        case .decodingError(let error):
            return "\(String(localized: "error.decode_error")): \(error.localizedDescription)"
        case .encodingError(let error):
            return "\(String(localized: "error.encode_error")): \(error.localizedDescription)"
        case .networkError(let error):
            return "\(String(localized: "error.network_error")): \(error.localizedDescription)"
        }
    }
}
