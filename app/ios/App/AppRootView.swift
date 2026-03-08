import SwiftUI

struct AppRootView: View {
    @StateObject private var appState = AppState()
    @StateObject private var languageSettings = LanguageSettings()
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
                        service: container.service,
                        currentUserID: appState.currentUser?.id,
                        onSignOut: signOut
                    )
                    .tabItem {
                        Label("sessions.title", systemImage: "calendar")
                    }

                    PaymentsView(viewModel: paymentsViewModel)
                        .tabItem {
                            Label("payments.title", systemImage: "creditcard")
                        }
                }
            } else {
                AuthView(
                    viewModel: AuthViewModel(service: container.service, appState: appState)
                )
            }
        }
        .environmentObject(languageSettings)
        .environment(\.locale, languageSettings.locale)
    }

    private func signOut() {
        appState.signOut()
        container.apiClient.authToken = nil
    }
}
