import SwiftUI

struct AppRootView: View {
    @StateObject private var appState = AppState()
    @StateObject private var languageSettings = LanguageSettings()
    private let container: AppContainer
    @StateObject private var sessionsViewModel: SessionsViewModel
    @StateObject private var historyViewModel: HistoryViewModel

    init(container: AppContainer = AppContainer()) {
        self.container = container
        _sessionsViewModel = StateObject(wrappedValue: SessionsViewModel(service: container.service))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(service: container.service, currentUserID: nil))
    }

    var body: some View {
        Group {
            if appState.isAuthenticated {
                TabView {
                    SessionListView(
                        viewModel: sessionsViewModel,
                        service: container.service,
                        currentUserID: appState.currentUser?.id
                    )
                    .tabItem {
                        Label("sessions.title", systemImage: "calendar")
                    }

                    HistoryView(viewModel: historyViewModel)
                    .tabItem {
                        Label("history.title", systemImage: "clock.arrow.circlepath")
                    }

                    SettingsView(
                        currentUser: appState.currentUser,
                        onSignOut: signOut
                    )
                        .tabItem {
                            Label("settings.title", systemImage: "gearshape")
                        }
                }
            } else {
                AuthView(
                    viewModel: AuthViewModel(service: container.service, appState: appState)
                )
            }
        }
        .task(id: appState.currentUser?.id) {
            historyViewModel.setCurrentUserID(appState.currentUser?.id)
        }
        .environmentObject(languageSettings)
        .environment(\.locale, languageSettings.locale)
    }

    private func signOut() {
        appState.signOut()
        container.apiClient.authToken = nil
    }
}
