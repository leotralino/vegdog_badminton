import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

enum APIEndpoint {
    case wechatLogin
    case listSessions
    case createSession
    case sessionDetail(sessionID: String)
    case finalizeSession(sessionID: String)
    case joinSession(sessionID: String)
    case withdrawSession(sessionID: String)
    case updateParticipant(sessionID: String, participantID: String)
    case listPaymentMethods(sessionID: String)
    case createPaymentMethod(sessionID: String)
    case listPaymentRecords(sessionID: String)
    case upsertPaymentRecord(sessionID: String)

    var method: HTTPMethod {
        switch self {
        case .listSessions, .sessionDetail, .listPaymentMethods, .listPaymentRecords:
            return .get
        case .updateParticipant:
            return .patch
        default:
            return .post
        }
    }

    var path: String {
        switch self {
        case .wechatLogin:
            return "/auth/wechat/login"
        case .listSessions, .createSession:
            return "/sessions"
        case .sessionDetail(let sessionID):
            return "/sessions/\(sessionID)"
        case .finalizeSession(let sessionID):
            return "/sessions/\(sessionID)/finalize"
        case .joinSession(let sessionID):
            return "/sessions/\(sessionID)/join"
        case .withdrawSession(let sessionID):
            return "/sessions/\(sessionID)/withdraw"
        case .updateParticipant(let sessionID, let participantID):
            return "/sessions/\(sessionID)/participants/\(participantID)"
        case .listPaymentMethods(let sessionID), .createPaymentMethod(let sessionID):
            return "/sessions/\(sessionID)/payments/methods"
        case .listPaymentRecords(let sessionID), .upsertPaymentRecord(let sessionID):
            return "/sessions/\(sessionID)/payments/records"
        }
    }
}
