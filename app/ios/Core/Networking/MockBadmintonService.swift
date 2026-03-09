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

        let alice = User(id: "user_alice", nickname: "Alice", avatarURL: "https://i.pravatar.cc/120?img=11", wechatOpenID: nil, wechatUnionID: nil)
        let bob = User(id: "user_bob", nickname: "Bob", avatarURL: "https://i.pravatar.cc/120?img=12", wechatOpenID: nil, wechatUnionID: nil)
        let cathy = User(id: "user_cathy", nickname: "Cathy", avatarURL: "https://i.pravatar.cc/120?img=13", wechatOpenID: nil, wechatUnionID: nil)
        let david = User(id: "user_david", nickname: "David", avatarURL: "https://i.pravatar.cc/120?img=14", wechatOpenID: nil, wechatUnionID: nil)
        let emma = User(id: "user_emma", nickname: "Emma", avatarURL: "https://i.pravatar.cc/120?img=15", wechatOpenID: nil, wechatUnionID: nil)
        [alice, bob, cathy, david, emma].forEach { userDirectory[$0.id] = $0 }

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
        let s3 = Session(
            id: "session_seed_3",
            title: "Weekday Ladder Match",
            startsAt: now.addingTimeInterval(60 * 60 * 60),
            endsAt: nil,
            location: "Palo Alto Indoor Court A",
            courtCount: 2,
            maxParticipants: 6,
            withdrawDeadline: now.addingTimeInterval(60 * 60 * 40),
            finalizeAt: nil,
            status: .open,
            feeRule: fee,
            initiatorUser: cathy,
            adminUserIDs: [cathy.id]
        )
        let s4 = Session(
            id: "session_seed_4",
            title: "Last Week Friendly (Ended)",
            startsAt: now.addingTimeInterval(-60 * 60 * 48),
            endsAt: now.addingTimeInterval(-60 * 60 * 45),
            location: "Mountain View Sports Center Court 3",
            courtCount: 2,
            maxParticipants: 8,
            withdrawDeadline: now.addingTimeInterval(-60 * 60 * 72),
            finalizeAt: now.addingTimeInterval(-60 * 60 * 50),
            status: .locked,
            feeRule: fee,
            initiatorUser: alice,
            adminUserIDs: [alice.id]
        )
        sessions = [s1, s2, s3, s4]
        adminsBySessionID[s1.id] = [SessionAdmin(id: UUID().uuidString, userID: alice.id, nickname: alice.nickname, addedAt: now)]
        adminsBySessionID[s2.id] = [SessionAdmin(id: UUID().uuidString, userID: bob.id, nickname: bob.nickname, addedAt: now)]
        adminsBySessionID[s3.id] = [SessionAdmin(id: UUID().uuidString, userID: cathy.id, nickname: cathy.nickname, addedAt: now)]
        adminsBySessionID[s4.id] = [SessionAdmin(id: UUID().uuidString, userID: alice.id, nickname: alice.nickname, addedAt: now)]

        participantsBySessionID[s1.id] = [
            SessionParticipant(id: "p_s1_1", sessionID: s1.id, user: alice, entryName: "Alice", createdByUserID: alice.id, queuePosition: 1, status: .joined, joinedAt: now.addingTimeInterval(-3600), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false),
            SessionParticipant(id: "p_s1_2", sessionID: s1.id, user: bob, entryName: "Bob", createdByUserID: bob.id, queuePosition: 2, status: .joined, joinedAt: now.addingTimeInterval(-3400), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false),
            SessionParticipant(id: "p_s1_3", sessionID: s1.id, user: emma, entryName: "Emma +1", createdByUserID: emma.id, queuePosition: 3, status: .joined, joinedAt: now.addingTimeInterval(-3200), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false),
            SessionParticipant(id: "p_s1_4", sessionID: s1.id, user: david, entryName: "David", createdByUserID: david.id, queuePosition: 4, status: .waitlist, joinedAt: now.addingTimeInterval(-3000), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false)
        ]
        participantsBySessionID[s2.id] = [
            SessionParticipant(id: "p_s2_1", sessionID: s2.id, user: bob, entryName: "Bob", createdByUserID: bob.id, queuePosition: 1, status: .joined, joinedAt: now.addingTimeInterval(-2600), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false),
            SessionParticipant(id: "p_s2_2", sessionID: s2.id, user: cathy, entryName: "Cathy", createdByUserID: cathy.id, queuePosition: 2, status: .joined, joinedAt: now.addingTimeInterval(-2500), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false)
        ]
        participantsBySessionID[s3.id] = [
            SessionParticipant(id: "p_s3_1", sessionID: s3.id, user: cathy, entryName: "Cathy", createdByUserID: cathy.id, queuePosition: 1, status: .joined, joinedAt: now.addingTimeInterval(-2300), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false),
            SessionParticipant(id: "p_s3_2", sessionID: s3.id, user: david, entryName: "David", createdByUserID: david.id, queuePosition: 2, status: .joined, joinedAt: now.addingTimeInterval(-2200), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false),
            SessionParticipant(id: "p_s3_3", sessionID: s3.id, user: emma, entryName: "Emma", createdByUserID: emma.id, queuePosition: 3, status: .joined, joinedAt: now.addingTimeInterval(-2100), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false)
        ]
        participantsBySessionID[s4.id] = [
            SessionParticipant(id: "p_s4_1", sessionID: s4.id, user: alice, entryName: "Alice", createdByUserID: alice.id, queuePosition: 1, status: .joined, joinedAt: now.addingTimeInterval(-60 * 60 * 60), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: true),
            SessionParticipant(id: "p_s4_2", sessionID: s4.id, user: bob, entryName: "Bob", createdByUserID: bob.id, queuePosition: 2, status: .joined, joinedAt: now.addingTimeInterval(-60 * 60 * 59), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: false),
            SessionParticipant(id: "p_s4_3", sessionID: s4.id, user: cathy, entryName: "Cathy", createdByUserID: cathy.id, queuePosition: 3, status: .joined, joinedAt: now.addingTimeInterval(-60 * 60 * 58), withdrewAt: nil, isReplacement: false, replacedParticipantID: nil, stayedLate: true),
            SessionParticipant(id: "p_s4_4", sessionID: s4.id, user: david, entryName: "David", createdByUserID: david.id, queuePosition: 4, status: .lateWithdraw, joinedAt: now.addingTimeInterval(-60 * 60 * 57), withdrewAt: now.addingTimeInterval(-60 * 60 * 49), isReplacement: false, replacedParticipantID: nil, stayedLate: false)
        ]
        paymentMethodsBySessionID[s1.id] = []
        paymentMethodsBySessionID[s2.id] = []
        paymentMethodsBySessionID[s3.id] = []
        paymentMethodsBySessionID[s4.id] = []
        paymentRecordsBySessionID[s1.id] = [
            PaymentRecord(id: "pay_s1_1", sessionID: s1.id, participantID: "p_s1_1", baseFeeAmount: 20, lateUsageFeeAmount: 0, totalAmount: 20, status: .paid, updatedAt: now),
            PaymentRecord(id: "pay_s1_2", sessionID: s1.id, participantID: "p_s1_2", baseFeeAmount: 20, lateUsageFeeAmount: 0, totalAmount: 20, status: .unpaid, updatedAt: now)
        ]
        paymentRecordsBySessionID[s2.id] = []
        paymentRecordsBySessionID[s3.id] = []
        paymentRecordsBySessionID[s4.id] = [
            PaymentRecord(id: "pay_s4_1", sessionID: s4.id, participantID: "p_s4_1", baseFeeAmount: 20, lateUsageFeeAmount: 6, totalAmount: 26, status: .paid, updatedAt: now),
            PaymentRecord(id: "pay_s4_2", sessionID: s4.id, participantID: "p_s4_2", baseFeeAmount: 20, lateUsageFeeAmount: 0, totalAmount: 20, status: .paid, updatedAt: now),
            PaymentRecord(id: "pay_s4_3", sessionID: s4.id, participantID: "p_s4_3", baseFeeAmount: 20, lateUsageFeeAmount: 6, totalAmount: 26, status: .unpaid, updatedAt: now),
            PaymentRecord(id: "pay_s4_4", sessionID: s4.id, participantID: "p_s4_4", baseFeeAmount: 20, lateUsageFeeAmount: 0, totalAmount: 20, status: .waived, updatedAt: now)
        ]
    }
}
