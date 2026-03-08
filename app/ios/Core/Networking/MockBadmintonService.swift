import Foundation

final class MockBadmintonService: BadmintonServiceProtocol {
    private var currentUser: User?
    private var sessions: [Session] = []
    private var participantsBySessionID: [String: [SessionParticipant]] = [:]
    private var paymentMethodsBySessionID: [String: [PaymentMethod]] = [:]
    private var paymentRecordsBySessionID: [String: [PaymentRecord]] = [:]

    init() {
        seedData()
    }

    func wechatLogin(code: String) async throws -> AuthResponse {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = User(
            id: "user_me",
            nickname: trimmed.isEmpty ? "Demo Player" : "Demo \(trimmed)",
            avatarURL: nil,
            wechatOpenID: "mock_openid",
            wechatUnionID: "mock_unionid"
        )
        currentUser = user
        return AuthResponse(token: "mock_token_123", user: user)
    }

    func listSessions() async throws -> [Session] {
        sessions.sorted { $0.startsAt < $1.startsAt }
    }

    func createSession(_ request: CreateSessionRequest) async throws -> Session {
        let session = Session(
            id: UUID().uuidString,
            title: request.title,
            startsAt: request.startsAt,
            endsAt: request.endsAt,
            location: request.location,
            courtCount: request.courtCount,
            maxParticipants: request.maxParticipants,
            withdrawDeadline: request.withdrawDeadline,
            finalizeAt: nil,
            status: .open,
            feeRule: request.feeRule
        )
        sessions.append(session)
        participantsBySessionID[session.id] = []
        paymentMethodsBySessionID[session.id] = []
        paymentRecordsBySessionID[session.id] = []
        return session
    }

    func getSessionDetail(sessionID: String) async throws -> SessionDetail {
        guard let session = sessions.first(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }
        let participants = participantsBySessionID[sessionID] ?? []
        return SessionDetail(
            id: session.id,
            title: session.title,
            startsAt: session.startsAt,
            endsAt: session.endsAt,
            location: session.location,
            courtCount: session.courtCount,
            maxParticipants: session.maxParticipants,
            withdrawDeadline: session.withdrawDeadline,
            finalizeAt: session.finalizeAt,
            status: session.status,
            feeRule: session.feeRule,
            participants: participants.sorted { $0.queuePosition < $1.queuePosition }
        )
    }

    func finalizeSession(sessionID: String) async throws -> Session {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }
        let old = sessions[index]
        let updated = Session(
            id: old.id,
            title: old.title,
            startsAt: old.startsAt,
            endsAt: old.endsAt,
            location: old.location,
            courtCount: old.courtCount,
            maxParticipants: old.maxParticipants,
            withdrawDeadline: old.withdrawDeadline,
            finalizeAt: Date(),
            status: .locked,
            feeRule: old.feeRule
        )
        sessions[index] = updated
        return updated
    }

    func joinSession(sessionID: String) async throws -> SessionParticipant {
        guard let session = sessions.first(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }
        let user = ensureCurrentUser()
        var participants = participantsBySessionID[sessionID] ?? []

        if let existing = participants.first(where: { $0.user.id == user.id && ($0.status == .joined || $0.status == .waitlist) }) {
            return existing
        }

        let queuePosition = (participants.map(\.queuePosition).max() ?? 0) + 1
        let activeCount = participants.filter { $0.status == .joined }.count
        let status: ParticipantStatus = activeCount < session.maxParticipants ? .joined : .waitlist

        let participant = SessionParticipant(
            id: UUID().uuidString,
            sessionID: sessionID,
            user: user,
            queuePosition: queuePosition,
            status: status,
            joinedAt: Date(),
            withdrewAt: nil,
            isReplacement: false,
            replacedParticipantID: nil,
            stayedLate: false
        )
        participants.append(participant)
        participantsBySessionID[sessionID] = participants
        return participant
    }

    func withdrawSession(sessionID: String) async throws -> WithdrawResult {
        let user = ensureCurrentUser()
        guard let session = sessions.first(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }
        guard var participants = participantsBySessionID[sessionID] else {
            throw APIError.httpError(statusCode: 404, message: "No participants")
        }
        guard let index = participants.firstIndex(where: { $0.user.id == user.id && ($0.status == .joined || $0.status == .waitlist) }) else {
            throw APIError.httpError(statusCode: 404, message: "Participant not found")
        }

        let old = participants[index]
        let late = Date() > session.withdrawDeadline
        let updatedStatus: ParticipantStatus = late ? .lateWithdraw : .withdrawn
        let liable = late
        let reason: WithdrawReason = late ? .lateNoReplacement : .beforeDeadline

        let updated = SessionParticipant(
            id: old.id,
            sessionID: old.sessionID,
            user: old.user,
            queuePosition: old.queuePosition,
            status: updatedStatus,
            joinedAt: old.joinedAt,
            withdrewAt: Date(),
            isReplacement: old.isReplacement,
            replacedParticipantID: old.replacedParticipantID,
            stayedLate: old.stayedLate
        )
        participants[index] = updated
        participantsBySessionID[sessionID] = participants

        return WithdrawResult(
            participantID: updated.id,
            status: updated.status,
            liableForBaseFee: liable,
            reason: reason
        )
    }

    func updateParticipant(sessionID: String, participantID: String, request: UpdateParticipantRequest) async throws -> SessionParticipant {
        guard var participants = participantsBySessionID[sessionID] else {
            throw APIError.httpError(statusCode: 404, message: "No participants")
        }
        guard let index = participants.firstIndex(where: { $0.id == participantID }) else {
            throw APIError.httpError(statusCode: 404, message: "Participant not found")
        }

        let old = participants[index]
        let updated = SessionParticipant(
            id: old.id,
            sessionID: old.sessionID,
            user: old.user,
            queuePosition: old.queuePosition,
            status: old.status,
            joinedAt: old.joinedAt,
            withdrewAt: old.withdrewAt,
            isReplacement: old.isReplacement,
            replacedParticipantID: old.replacedParticipantID,
            stayedLate: request.stayedLate ?? old.stayedLate
        )
        participants[index] = updated
        participantsBySessionID[sessionID] = participants
        return updated
    }

    func listPaymentMethods(sessionID: String) async throws -> [PaymentMethod] {
        paymentMethodsBySessionID[sessionID] ?? []
    }

    func createPaymentMethod(sessionID: String, request: CreatePaymentMethodRequest) async throws -> PaymentMethod {
        let user = ensureCurrentUser()
        let method = PaymentMethod(
            id: UUID().uuidString,
            sessionID: sessionID,
            ownerUserID: user.id,
            type: request.type,
            label: request.label,
            accountRef: request.accountRef,
            deepLink: request.deepLink
        )
        var methods = paymentMethodsBySessionID[sessionID] ?? []
        methods.append(method)
        paymentMethodsBySessionID[sessionID] = methods
        return method
    }

    func listPaymentRecords(sessionID: String) async throws -> [PaymentRecord] {
        paymentRecordsBySessionID[sessionID] ?? []
    }

    func upsertPaymentRecord(sessionID: String, request: UpsertPaymentRecordRequest) async throws -> PaymentRecord {
        var records = paymentRecordsBySessionID[sessionID] ?? []
        let lateFee = request.lateUsageFeeAmount ?? 0
        let total = request.baseFeeAmount + lateFee

        if let index = records.firstIndex(where: { $0.participantID == request.participantID }) {
            let old = records[index]
            let updated = PaymentRecord(
                id: old.id,
                sessionID: sessionID,
                participantID: request.participantID,
                baseFeeAmount: request.baseFeeAmount,
                lateUsageFeeAmount: lateFee,
                totalAmount: total,
                status: request.status,
                updatedAt: Date()
            )
            records[index] = updated
            paymentRecordsBySessionID[sessionID] = records
            return updated
        }

        let created = PaymentRecord(
            id: UUID().uuidString,
            sessionID: sessionID,
            participantID: request.participantID,
            baseFeeAmount: request.baseFeeAmount,
            lateUsageFeeAmount: lateFee,
            totalAmount: total,
            status: request.status,
            updatedAt: Date()
        )
        records.append(created)
        paymentRecordsBySessionID[sessionID] = records
        return created
    }

    private func ensureCurrentUser() -> User {
        if let currentUser { return currentUser }
        let fallback = User(
            id: "user_me",
            nickname: "Demo Player",
            avatarURL: nil,
            wechatOpenID: "mock_openid",
            wechatUnionID: "mock_unionid"
        )
        currentUser = fallback
        return fallback
    }

    private func seedData() {
        let now = Date()
        let fee = FeeRule(mode: .fixedPerPerson, amount: 20, lateWithdrawRatio: 1)

        let s1 = Session(
            id: "session_seed_1",
            title: "Saturday Evening Badminton",
            startsAt: now.addingTimeInterval(60 * 60 * 24),
            endsAt: nil,
            location: "Sunnyvale Community Center",
            courtCount: 2,
            maxParticipants: 8,
            withdrawDeadline: now.addingTimeInterval(60 * 60 * 12),
            finalizeAt: nil,
            status: .open,
            feeRule: fee
        )
        let s2 = Session(
            id: "session_seed_2",
            title: "Sunday Morning Drill",
            startsAt: now.addingTimeInterval(60 * 60 * 36),
            endsAt: nil,
            location: "Cupertino Sports Hall",
            courtCount: 1,
            maxParticipants: 4,
            withdrawDeadline: now.addingTimeInterval(60 * 60 * 20),
            finalizeAt: nil,
            status: .open,
            feeRule: fee
        )
        sessions = [s1, s2]
        participantsBySessionID[s1.id] = []
        participantsBySessionID[s2.id] = []
        paymentMethodsBySessionID[s1.id] = []
        paymentMethodsBySessionID[s2.id] = []
        paymentRecordsBySessionID[s1.id] = []
        paymentRecordsBySessionID[s2.id] = []
    }
}
