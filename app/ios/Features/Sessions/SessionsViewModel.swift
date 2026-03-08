import SwiftUI

@MainActor
final class SessionsViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: BadmintonServiceProtocol

    init(service: BadmintonServiceProtocol) {
        self.service = service
    }

    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            sessions = try await service.listSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func join(sessionID: String) async {
        do {
            _ = try await service.joinSession(sessionID: sessionID)
            await loadSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func withdraw(sessionID: String) async {
        do {
            _ = try await service.withdrawSession(sessionID: sessionID)
            await loadSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func finalize(sessionID: String) async {
        do {
            _ = try await service.finalizeSession(sessionID: sessionID)
            await loadSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
