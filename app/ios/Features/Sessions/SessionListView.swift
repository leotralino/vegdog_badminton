import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: SessionsViewModel
    let service: BadmintonServiceProtocol
    let currentUserID: String?
    @State private var isPresentingCreate = false
    @State private var selectedSessionID: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    ProgressView("sessions.loading")
                } else if visibleSessions.isEmpty {
                    ContentUnavailableView("sessions.empty_title", systemImage: "calendar")
                } else {
                    List(visibleSessions) { session in
                        SessionCardView(session: session)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSessionID = session.id
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(CuteTheme.mint.opacity(0.12))
            .navigationTitle("sessions.title")
            .toolbar {
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
                                currentUserID: currentUserID,
                                service: service
                            )
                        )
                    }
                }
            }
        }
    }

    private var visibleSessions: [Session] {
        viewModel.sessions.filter { !DateDisplay.shouldMoveToHistory($0) }
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
