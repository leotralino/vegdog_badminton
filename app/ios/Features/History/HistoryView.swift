import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    let service: BadmintonServiceProtocol
    let currentUserID: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.pastSessions.isEmpty && viewModel.participatedSessions.isEmpty {
                    ProgressView("history.loading")
                } else {
                    List {
                        Section("history.participated") {
                            if viewModel.participatedSessions.isEmpty {
                                Text("history.empty")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.participatedSessions) { session in
                                    NavigationLink {
                                        SessionDetailView(
                                            viewModel: SessionDetailViewModel(
                                                sessionID: session.id,
                                                currentUserID: currentUserID,
                                                service: service
                                            )
                                        )
                                    } label: {
                                        SessionCardView(session: session)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Section("history.past") {
                            if viewModel.pastSessions.isEmpty {
                                Text("history.empty")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.pastSessions) { session in
                                    NavigationLink {
                                        SessionDetailView(
                                            viewModel: SessionDetailViewModel(
                                                sessionID: session.id,
                                                currentUserID: currentUserID,
                                                service: service
                                            )
                                        )
                                    } label: {
                                        SessionCardView(session: session)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("history.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                if viewModel.pastSessions.isEmpty && viewModel.participatedSessions.isEmpty {
                    await viewModel.load()
                }
            }
            .alert(
                String(localized: "common.error_title"),
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                ),
                actions: {
                    Button(String(localized: "common.ok"), role: .cancel) {}
                },
                message: {
                    Text(viewModel.errorMessage ?? String(localized: "common.unknown_error"))
                }
            )
        }
    }
}
