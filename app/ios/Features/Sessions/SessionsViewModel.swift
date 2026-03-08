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
            _ = try await service.joinSession(sessionID: sessionID, entryName: nil)
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

    func createSession(request: CreateSessionRequest) async {
        do {
            _ = try await service.createSession(request)
            await loadSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
