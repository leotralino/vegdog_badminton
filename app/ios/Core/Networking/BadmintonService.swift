import Foundation

protocol BadmintonServiceProtocol {
    func wechatLogin(code: String) async throws -> AuthResponse
    func listSessions() async throws -> [Session]
    func createSession(_ request: CreateSessionRequest) async throws -> Session
    func getSessionDetail(sessionID: String) async throws -> SessionDetail
    func finalizeSession(sessionID: String) async throws -> Session
    func joinSession(sessionID: String) async throws -> SessionParticipant
    func withdrawSession(sessionID: String) async throws -> WithdrawResult
    func listSessionAdmins(sessionID: String) async throws -> [SessionAdmin]
    func addSessionAdmin(sessionID: String, request: AddSessionAdminRequest) async throws -> SessionAdmin
    func updateParticipant(sessionID: String, participantID: String, request: UpdateParticipantRequest) async throws -> SessionParticipant
    func listPaymentMethods(sessionID: String) async throws -> [PaymentMethod]
    func createPaymentMethod(sessionID: String, request: CreatePaymentMethodRequest) async throws -> PaymentMethod
    func listPaymentRecords(sessionID: String) async throws -> [PaymentRecord]
    func upsertPaymentRecord(sessionID: String, request: UpsertPaymentRecordRequest) async throws -> PaymentRecord
}

final class BadmintonService: BadmintonServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func wechatLogin(code: String) async throws -> AuthResponse {
        let response = try await client.request(.wechatLogin, body: WeChatLoginRequest(code: code), responseType: AuthResponse.self)
        client.authToken = response.token
        return response
    }

    func listSessions() async throws -> [Session] {
        let response = try await client.requestWithoutBody(.listSessions, responseType: SessionListResponse.self)
        return response.items
    }

    func createSession(_ request: CreateSessionRequest) async throws -> Session {
        try await client.request(.createSession, body: request, responseType: Session.self)
    }

    func getSessionDetail(sessionID: String) async throws -> SessionDetail {
        try await client.requestWithoutBody(.sessionDetail(sessionID: sessionID), responseType: SessionDetail.self)
    }

    func finalizeSession(sessionID: String) async throws -> Session {
        try await client.requestWithoutBody(.finalizeSession(sessionID: sessionID), responseType: Session.self)
    }

    func joinSession(sessionID: String) async throws -> SessionParticipant {
        try await client.requestWithoutBody(.joinSession(sessionID: sessionID), responseType: SessionParticipant.self)
    }

    func withdrawSession(sessionID: String) async throws -> WithdrawResult {
        try await client.requestWithoutBody(.withdrawSession(sessionID: sessionID), responseType: WithdrawResult.self)
    }

    func listSessionAdmins(sessionID: String) async throws -> [SessionAdmin] {
        let response = try await client.requestWithoutBody(.listSessionAdmins(sessionID: sessionID), responseType: SessionAdminsResponse.self)
        return response.items
    }

    func addSessionAdmin(sessionID: String, request: AddSessionAdminRequest) async throws -> SessionAdmin {
        try await client.request(.addSessionAdmin(sessionID: sessionID), body: request, responseType: SessionAdmin.self)
    }

    func updateParticipant(sessionID: String, participantID: String, request: UpdateParticipantRequest) async throws -> SessionParticipant {
        try await client.request(.updateParticipant(sessionID: sessionID, participantID: participantID), body: request, responseType: SessionParticipant.self)
    }

    func listPaymentMethods(sessionID: String) async throws -> [PaymentMethod] {
        let response = try await client.requestWithoutBody(.listPaymentMethods(sessionID: sessionID), responseType: PaymentMethodsResponse.self)
        return response.items
    }

    func createPaymentMethod(sessionID: String, request: CreatePaymentMethodRequest) async throws -> PaymentMethod {
        try await client.request(.createPaymentMethod(sessionID: sessionID), body: request, responseType: PaymentMethod.self)
    }

    func listPaymentRecords(sessionID: String) async throws -> [PaymentRecord] {
        let response = try await client.requestWithoutBody(.listPaymentRecords(sessionID: sessionID), responseType: PaymentRecordsResponse.self)
        return response.items
    }

    func upsertPaymentRecord(sessionID: String, request: UpsertPaymentRecordRequest) async throws -> PaymentRecord {
        try await client.request(.upsertPaymentRecord(sessionID: sessionID), body: request, responseType: PaymentRecord.self)
    }
}
