import SwiftUI

@MainActor
final class SessionDetailViewModel: ObservableObject {
    @Published var detail: SessionDetail?
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

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await service.getSessionDetail(sessionID: sessionID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func join() async {
        do {
            _ = try await service.joinSession(sessionID: sessionID)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func withdraw() async {
        do {
            _ = try await service.withdrawSession(sessionID: sessionID)
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
            errorMessage = "Admin user ID is required."
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
