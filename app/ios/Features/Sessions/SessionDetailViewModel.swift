import SwiftUI

@MainActor
final class SessionDetailViewModel: ObservableObject {
    @Published var detail: SessionDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let sessionID: String
    private let service: BadmintonServiceProtocol

    init(sessionID: String, service: BadmintonServiceProtocol) {
        self.sessionID = sessionID
        self.service = service
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
}
