import SwiftUI

struct AppRootView: View {
    @StateObject private var appState = AppState()
    private let container: AppContainer

    init(container: AppContainer = AppContainer()) {
        self.container = container
    }

    var body: some View {
        Group {
            if appState.isAuthenticated {
                SessionListView(
                    viewModel: SessionsViewModel(service: container.service),
                    onSignOut: {
                        appState.signOut()
                        container.apiClient.authToken = nil
                    }
                )
            } else {
                AuthView(
                    viewModel: AuthViewModel(service: container.service, appState: appState)
                )
            }
        }
    }
}
