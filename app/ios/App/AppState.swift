import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var authToken: String?

    var isAuthenticated: Bool {
        currentUser != nil && authToken != nil
    }

    func setAuthenticatedUser(_ user: User, token: String) {
        currentUser = user
        authToken = token
    }

    func signOut() {
        currentUser = nil
        authToken = nil
    }
}
