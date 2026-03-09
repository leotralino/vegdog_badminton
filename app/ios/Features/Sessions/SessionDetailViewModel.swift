import SwiftUI

@MainActor
final class SessionDetailViewModel: ObservableObject {
    @Published var detail: SessionDetail?
    @Published var paymentRecords: [PaymentRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newAdminUserID: String = ""
    @Published var newAdminNickname: String = ""

    let sessionID: String
    let currentUserID: String?
    private let service: BadmintonServiceProtocol

    init(sessionID: String, currentUserID: String?, service: BadmintonServiceProtocol) {
        self.sessionID = sessionID
        self.currentUserID = currentUserID
        self.service = service
    }

    var isCurrentUserAdmin: Bool {
        guard let currentUserID, let detail else { return false }
        return detail.admins.contains(where: { $0.userID == currentUserID })
    }

    var currentUserNickname: String {
        let profileNickname = UserDefaults.standard.string(forKey: "profile.nickname")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !profileNickname.isEmpty {
            return profileNickname
        }
        guard let currentUserID, let detail else { return "Me" }
        if detail.initiatorUser.id == currentUserID {
            return detail.initiatorUser.nickname
        }
        if let participant = detail.participants.first(where: { $0.ownerUserID == currentUserID }) {
            return participant.user.nickname
        }
        if let admin = detail.admins.first(where: { $0.userID == currentUserID }) {
            return admin.nickname
        }
        return "Me"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let detailTask = service.getSessionDetail(sessionID: sessionID)
            async let paymentTask = service.listPaymentRecords(sessionID: sessionID)
            detail = try await detailTask
            paymentRecords = try await paymentTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinEntry() async {
        guard let currentUserID else { return }
        let activeCount = detail?.participants.filter { $0.ownerUserID == currentUserID && ($0.status == .joined || $0.status == .waitlist) }.count ?? 0
        let defaultName = activeCount == 0 ? currentUserNickname : "\(currentUserNickname) +\(activeCount)"
        do {
            _ = try await service.joinSession(sessionID: sessionID, entryName: defaultName)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeEntry(participantID: String) async {
        do {
            _ = try await service.withdrawParticipant(sessionID: sessionID, participantID: participantID)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func finalize() async {
        do {
            _ = try await service.finalizeSession(sessionID: sessionID)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateStayedLate(participantID: String, stayedLate: Bool) async {
        do {
            let request = UpdateParticipantRequest(stayedLate: stayedLate, adminNote: nil)
            _ = try await service.updateParticipant(sessionID: sessionID, participantID: participantID, request: request)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addAdmin() async {
        let userID = newAdminUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userID.isEmpty else {
            errorMessage = String(localized: "error.admin_user_id_required")
            return
        }
        do {
            let request = AddSessionAdminRequest(
                userID: userID,
                nickname: trimmedOrNil(newAdminNickname)
            )
            _ = try await service.addSessionAdmin(sessionID: sessionID, request: request)
            newAdminUserID = ""
            newAdminNickname = ""
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func trimmedOrNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
