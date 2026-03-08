import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

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
                                    SessionHistoryRow(session: session)
                                }
                            }
                        }

                        Section("history.past") {
                            if viewModel.pastSessions.isEmpty {
                                Text("history.empty")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.pastSessions) { session in
                                    SessionHistoryRow(session: session)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("history.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageToggleButton()
                }
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

private struct SessionHistoryRow: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.headline)
            Text(session.startsAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(session.location)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
