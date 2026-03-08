import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var wechatCode: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: BadmintonServiceProtocol
    private let appState: AppState

    init(service: BadmintonServiceProtocol, appState: AppState) {
        self.service = service
        self.appState = appState
    }

    func login() async {
        let code = wechatCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            errorMessage = "Please input WeChat auth code."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let auth = try await service.wechatLogin(code: code)
            appState.setAuthenticatedUser(auth.user, token: auth.token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
