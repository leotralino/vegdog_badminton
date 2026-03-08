import SwiftUI

struct AppRootView: View {
    @StateObject private var appState = AppState()
    private let container: AppContainer
    @StateObject private var sessionsViewModel: SessionsViewModel
    @StateObject private var paymentsViewModel: PaymentsViewModel

    init(container: AppContainer = AppContainer()) {
        self.container = container
        _sessionsViewModel = StateObject(wrappedValue: SessionsViewModel(service: container.service))
        _paymentsViewModel = StateObject(wrappedValue: PaymentsViewModel(service: container.service))
    }

    var body: some View {
        Group {
            if appState.isAuthenticated {
                TabView {
                    SessionListView(
                        viewModel: sessionsViewModel,
                        onSignOut: signOut
                    )
                    .tabItem {
                        Label("Sessions", systemImage: "calendar")
                    }

                    PaymentsView(viewModel: paymentsViewModel)
                        .tabItem {
                            Label("Payments", systemImage: "creditcard")
                        }
                }
            } else {
                AuthView(
                    viewModel: AuthViewModel(service: container.service, appState: appState)
                )
            }
        }
    }

    private func signOut() {
        appState.signOut()
        container.apiClient.authToken = nil
    }
}
