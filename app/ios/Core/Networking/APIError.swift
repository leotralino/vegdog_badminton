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
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid server response."
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message ?? "Request failed.")"
        case .decodingError(let error):
            return "Decode error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encode error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
