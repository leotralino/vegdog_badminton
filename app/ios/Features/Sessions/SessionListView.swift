import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: SessionsViewModel
    let onSignOut: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    ProgressView("Loading sessions...")
                } else if viewModel.sessions.isEmpty {
                    ContentUnavailableView("No sessions", systemImage: "calendar")
                } else {
                    List(viewModel.sessions) { session in
                        SessionRowView(
                            session: session,
                            onJoin: { Task { await viewModel.join(sessionID: session.id) } },
                            onWithdraw: { Task { await viewModel.withdraw(sessionID: session.id) } },
                            onFinalize: { Task { await viewModel.finalize(sessionID: session.id) } }
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out", action: onSignOut)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadSessions() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                if viewModel.sessions.isEmpty {
                    await viewModel.loadSessions()
                }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                ),
                actions: {
                    Button("OK", role: .cancel) {}
                },
                message: {
                    Text(viewModel.errorMessage ?? "Unknown error")
                }
            )
        }
    }
}

private struct SessionRowView: View {
    let session: Session
    let onJoin: () -> Void
    let onWithdraw: () -> Void
    let onFinalize: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.title)
                .font(.headline)

            Text("\(session.location) · \(session.startsAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Courts: \(session.courtCount)  Max: \(session.maxParticipants)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Withdraw by: \(session.withdrawDeadline.formatted(date: .abbreviated, time: .shortened))")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Button("Join", action: onJoin)
                    .buttonStyle(.borderedProminent)
                Button("Withdraw", action: onWithdraw)
                    .buttonStyle(.bordered)
                Button("Finalize", action: onFinalize)
                    .buttonStyle(.bordered)
            }
            .font(.footnote)
        }
        .padding(.vertical, 4)
    }
}
