import Foundation

final class MockBadmintonService: BadmintonServiceProtocol {
    private var currentUser: User?
    private var userDirectory: [String: User] = [:]

    private var sessions: [Session] = []
    private var participantsBySessionID: [String: [SessionParticipant]] = [:]
    private var adminsBySessionID: [String: [SessionAdmin]] = [:]
    private var paymentMethodsBySessionID: [String: [PaymentMethod]] = [:]
    private var paymentRecordsBySessionID: [String: [PaymentRecord]] = [:]

    init() {
        seedData()
    }

    func wechatLogin(code: String) async throws -> AuthResponse {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let userID = trimmed.isEmpty ? "user_me" : "user_\(trimmed.lowercased())"
        let user = User(
            id: userID,
            nickname: trimmed.isEmpty ? "Demo Player" : "Demo \(trimmed)",
            avatarURL: nil,
            wechatOpenID: "mock_openid_\(userID)",
            wechatUnionID: "mock_unionid_\(userID)"
        )
        currentUser = user
        userDirectory[user.id] = user
        return AuthResponse(token: "mock_token_123", user: user)
    }

    func listSessions() async throws -> [Session] {
        sessions.sorted { $0.startsAt < $1.startsAt }
    }

    func createSession(_ request: CreateSessionRequest) async throws -> Session {
        let initiator = ensureCurrentUser()
        let sessionID = UUID().uuidString
        let session = Session(
            id: sessionID,
            title: request.title,
            startsAt: request.startsAt,
            endsAt: request.endsAt,
            location: request.location,
            courtCount: request.courtCount,
            maxParticipants: request.maxParticipants,
            withdrawDeadline: request.withdrawDeadline,
            finalizeAt: nil,
            status: .open,
            feeRule: request.feeRule,
            initiatorUser: initiator,
            adminUserIDs: [initiator.id]
        )
        sessions.append(session)
        participantsBySessionID[session.id] = []
        adminsBySessionID[session.id] = [
            SessionAdmin(
                id: UUID().uuidString,
                userID: initiator.id,
                nickname: initiator.nickname,
                addedAt: Date()
            )
        ]
        paymentMethodsBySessionID[session.id] = []
        paymentRecordsBySessionID[session.id] = []
        return session
    }

    func getSessionDetail(sessionID: String) async throws -> SessionDetail {
        guard let session = sessions.first(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }
        let participants = participantsBySessionID[sessionID] ?? []
        let admins = adminsBySessionID[sessionID] ?? []
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
            initiatorUser: session.initiatorUser,
            admins: admins,
            participants: participants.sorted { $0.queuePosition < $1.queuePosition }
        )
    }

    func finalizeSession(sessionID: String) async throws -> Session {
        let user = ensureCurrentUser()
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }
        guard isAdmin(userID: user.id, sessionID: sessionID) else {
            throw APIError.httpError(statusCode: 403, message: "Only session admins can finalize.")
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
            feeRule: old.feeRule,
            initiatorUser: old.initiatorUser,
            adminUserIDs: old.adminUserIDs
        )
        sessions[index] = updated
        return updated
    }

    func joinSession(sessionID: String, entryName: String?) async throws -> SessionParticipant {
        guard let session = sessions.first(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }
        guard session.status != .locked else {
            throw APIError.httpError(statusCode: 403, message: "Queue is locked.")
        }
        let user = ensureCurrentUser()
        var participants = participantsBySessionID[sessionID] ?? []
        let resolvedName = normalizedEntryName(entryName, fallback: user.nickname)
        participants.removeAll {
            $0.ownerUserID == user.id &&
            ($0.status == .withdrawn || $0.status == .lateWithdraw) &&
            $0.displayName == resolvedName
        }

        let queuePosition = (participants.map(\.queuePosition).max() ?? 0) + 1
        let activeCount = participants.filter { $0.status == .joined }.count
        let status: ParticipantStatus = activeCount < session.maxParticipants ? .joined : .waitlist

        let participant = SessionParticipant(
            id: UUID().uuidString,
            sessionID: sessionID,
            user: user,
            entryName: resolvedName,
            createdByUserID: user.id,
            queuePosition: queuePosition,
            status: status,
            joinedAt: Date(),
            withdrewAt: nil,
            isReplacement: false,
            replacedParticipantID: nil,
            stayedLate: false
        )
        participants.append(participant)
        participants = recomputeQueueStatuses(participants, maxParticipants: session.maxParticipants)
        participantsBySessionID[sessionID] = participants
        return participants.first(where: { $0.id == participant.id }) ?? participant
    }

    func withdrawParticipant(sessionID: String, participantID: String) async throws -> WithdrawResult {
        let user = ensureCurrentUser()
        guard let session = sessions.first(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }
        guard session.status != .locked else {
            throw APIError.httpError(statusCode: 403, message: "Queue is locked.")
        }
        guard var participants = participantsBySessionID[sessionID] else {
            throw APIError.httpError(statusCode: 404, message: "No participants")
        }
        guard let index = participants.firstIndex(where: { $0.id == participantID && ($0.status == .joined || $0.status == .waitlist) }) else {
            throw APIError.httpError(statusCode: 404, message: "Participant not found")
        }

        let old = participants[index]
        guard old.ownerUserID == user.id else {
            throw APIError.httpError(statusCode: 403, message: "You can only remove entries you created.")
        }

        let late = Date() > session.withdrawDeadline
        let updatedStatus: ParticipantStatus = late ? .lateWithdraw : .withdrawn
        let liable = late
        let reason: WithdrawReason = late ? .lateNoReplacement : .beforeDeadline

        let updated = SessionParticipant(
            id: old.id,
            sessionID: old.sessionID,
            user: old.user,
            entryName: old.entryName,
            createdByUserID: old.ownerUserID,
            queuePosition: old.queuePosition,
            status: updatedStatus,
            joinedAt: old.joinedAt,
            withdrewAt: Date(),
            isReplacement: old.isReplacement,
            replacedParticipantID: old.replacedParticipantID,
            stayedLate: old.stayedLate
        )
        participants[index] = updated
        participants = recomputeQueueStatuses(participants, maxParticipants: session.maxParticipants)
        participantsBySessionID[sessionID] = participants

        return WithdrawResult(
            participantID: updated.id,
            status: updated.status,
            liableForBaseFee: liable,
            reason: reason
        )
    }

    func listSessionAdmins(sessionID: String) async throws -> [SessionAdmin] {
        adminsBySessionID[sessionID] ?? []
    }

    func addSessionAdmin(sessionID: String, request: AddSessionAdminRequest) async throws -> SessionAdmin {
        let actor = ensureCurrentUser()
        guard isAdmin(userID: actor.id, sessionID: sessionID) else {
            throw APIError.httpError(statusCode: 403, message: "Only session admins can add admins.")
        }

        guard let sessionIndex = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw APIError.httpError(statusCode: 404, message: "Session not found")
        }

        var admins = adminsBySessionID[sessionID] ?? []
        if let existing = admins.first(where: { $0.userID == request.userID }) {
            return existing
        }

        let targetUser = ensureUserExists(userID: request.userID, nickname: request.nickname)
        let admin = SessionAdmin(
            id: UUID().uuidString,
            userID: targetUser.id,
            nickname: targetUser.nickname,
            addedAt: Date()
        )
        admins.append(admin)
        adminsBySessionID[sessionID] = admins

        let old = sessions[sessionIndex]
        sessions[sessionIndex] = Session(
            id: old.id,
            title: old.title,
            startsAt: old.startsAt,
            endsAt: old.endsAt,
            location: old.location,
            courtCount: old.courtCount,
            maxParticipants: old.maxParticipants,
            withdrawDeadline: old.withdrawDeadline,
            finalizeAt: old.finalizeAt,
            status: old.status,
            feeRule: old.feeRule,
            initiatorUser: old.initiatorUser,
            adminUserIDs: admins.map(\.userID)
        )

        return admin
    }

    func updateParticipant(sessionID: String, participantID: String, request: UpdateParticipantRequest) async throws -> SessionParticipant {
        let actor = ensureCurrentUser()
        guard isAdmin(userID: actor.id, sessionID: sessionID) else {
            throw APIError.httpError(statusCode: 403, message: "Only session admins can update participant metadata.")
        }

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
            entryName: old.entryName,
            createdByUserID: old.ownerUserID,
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

    private func isAdmin(userID: String, sessionID: String) -> Bool {
        adminsBySessionID[sessionID]?.contains(where: { $0.userID == userID }) ?? false
    }

    private func ensureUserExists(userID: String, nickname: String?) -> User {
        if let existing = userDirectory[userID] {
            return existing
        }
        let created = User(
            id: userID,
            nickname: nickname ?? "Member \(userID)",
            avatarURL: nil,
            wechatOpenID: nil,
            wechatUnionID: nil
        )
        userDirectory[userID] = created
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
        userDirectory[fallback.id] = fallback
        return fallback
    }

    private func normalizedEntryName(_ entryName: String?, fallback: String) -> String {
        let trimmed = entryName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func recomputeQueueStatuses(_ participants: [SessionParticipant], maxParticipants: Int) -> [SessionParticipant] {
        let sorted = participants.sorted { $0.queuePosition < $1.queuePosition }
        var activeIndex = 0

        return sorted.map { participant in
            guard participant.status == .joined || participant.status == .waitlist else {
                return participant
            }

            defer { activeIndex += 1 }
            let nextStatus: ParticipantStatus = activeIndex < maxParticipants ? .joined : .waitlist
            return SessionParticipant(
                id: participant.id,
                sessionID: participant.sessionID,
                user: participant.user,
                entryName: participant.entryName,
                createdByUserID: participant.ownerUserID,
                queuePosition: participant.queuePosition,
                status: nextStatus,
                joinedAt: participant.joinedAt,
                withdrewAt: participant.withdrewAt,
                isReplacement: participant.isReplacement,
                replacedParticipantID: participant.replacedParticipantID,
                stayedLate: participant.stayedLate
            )
        }
    }

    private func seedData() {
        let now = Date()
        let fee = FeeRule(mode: .fixedPerPerson, amount: 20, lateWithdrawRatio: 1)

        let alice = User(id: "user_alice", nickname: "Alice", avatarURL: nil, wechatOpenID: nil, wechatUnionID: nil)
        let bob = User(id: "user_bob", nickname: "Bob", avatarURL: nil, wechatOpenID: nil, wechatUnionID: nil)
        userDirectory[alice.id] = alice
        userDirectory[bob.id] = bob

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
            feeRule: fee,
            initiatorUser: alice,
            adminUserIDs: [alice.id]
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
            feeRule: fee,
            initiatorUser: bob,
            adminUserIDs: [bob.id]
        )
        sessions = [s1, s2]
        adminsBySessionID[s1.id] = [SessionAdmin(id: UUID().uuidString, userID: alice.id, nickname: alice.nickname, addedAt: now)]
        adminsBySessionID[s2.id] = [SessionAdmin(id: UUID().uuidString, userID: bob.id, nickname: bob.nickname, addedAt: now)]

        participantsBySessionID[s1.id] = []
        participantsBySessionID[s2.id] = []
        paymentMethodsBySessionID[s1.id] = []
        paymentMethodsBySessionID[s2.id] = []
        paymentRecordsBySessionID[s1.id] = []
        paymentRecordsBySessionID[s2.id] = []
    }
}
