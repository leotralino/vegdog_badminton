import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var pastSessions: [Session] = []
    @Published var participatedSessions: [Session] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: BadmintonServiceProtocol
    private var currentUserID: String?

    init(service: BadmintonServiceProtocol, currentUserID: String?) {
        self.service = service
        self.currentUserID = currentUserID
    }

    func setCurrentUserID(_ userID: String?) {
        currentUserID = userID
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let sessions = try await service.listSessions()
            pastSessions = sessions
                .filter { DateDisplay.shouldMoveToHistory($0) }
                .sorted { $0.startsAt > $1.startsAt }

            guard let currentUserID else {
                participatedSessions = []
                return
            }

            var participatedIDs = Set<String>()
            for session in sessions {
                let detail = try await service.getSessionDetail(sessionID: session.id)
                if detail.participants.contains(where: { $0.ownerUserID == currentUserID && $0.status == .joined }) {
                    participatedIDs.insert(session.id)
                }
            }
            participatedSessions = sessions
                .filter { participatedIDs.contains($0.id) && DateDisplay.shouldMoveToHistory($0) }
                .sorted { $0.startsAt > $1.startsAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
