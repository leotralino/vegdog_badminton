import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: SessionsViewModel
    let service: BadmintonServiceProtocol
    let onSignOut: () -> Void
    @State private var isPresentingCreate = false
    @State private var selectedSessionID: String?

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
                            onOpenDetail: { selectedSessionID = session.id },
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
                    HStack {
                        Button {
                            isPresentingCreate = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        Button {
                            Task { await viewModel.loadSessions() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
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
            .sheet(isPresented: $isPresentingCreate) {
                SessionCreateSheetContainer(
                    service: service,
                    onCreated: { await viewModel.loadSessions() }
                )
            }
            .sheet(
                isPresented: Binding(
                    get: { selectedSessionID != nil },
                    set: { if !$0 { selectedSessionID = nil } }
                )
            ) {
                if let selectedSessionID {
                    NavigationStack {
                        SessionDetailView(
                            viewModel: SessionDetailViewModel(
                                sessionID: selectedSessionID,
                                service: service
                            )
                        )
                    }
                }
            }
        }
    }
}

private struct SessionRowView: View {
    let session: Session
    let onOpenDetail: () -> Void
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
                Button("Details", action: onOpenDetail)
                    .buttonStyle(.bordered)
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

private struct SessionCreateSheetContainer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SessionCreateViewModel
    let onCreated: () async -> Void

    init(service: BadmintonServiceProtocol, onCreated: @escaping () async -> Void) {
        _viewModel = StateObject(wrappedValue: SessionCreateViewModel(service: service))
        self.onCreated = onCreated
    }

    var body: some View {
        SessionCreateView(
            viewModel: viewModel,
            onCancel: { dismiss() },
            onCreated: {
                await onCreated()
                dismiss()
            }
        )
    }
}
