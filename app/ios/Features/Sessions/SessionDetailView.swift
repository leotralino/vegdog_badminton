import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var viewModel: SessionDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                ProgressView("Loading session...")
            } else if let detail = viewModel.detail {
                List {
                    Section("Session") {
                        Text(detail.title)
                            .font(.headline)
                        Text("\(detail.location) · \(detail.startsAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Status: \(detail.status.rawValue)")
                            .font(.footnote)
                        Text("Withdraw deadline: \(detail.withdrawDeadline.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                    }

                    Section("Actions") {
                        HStack {
                            Button("Join") { Task { await viewModel.join() } }
                                .buttonStyle(.borderedProminent)
                            Button("Withdraw") { Task { await viewModel.withdraw() } }
                                .buttonStyle(.bordered)
                            Button("Finalize") { Task { await viewModel.finalize() } }
                                .buttonStyle(.bordered)
                        }
                    }

                    Section("Participants") {
                        if detail.participants.isEmpty {
                            Text("No participants")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(detail.participants) { participant in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(participant.user.nickname)
                                        .font(.subheadline.weight(.semibold))
                                    Text("Status: \(participant.status.rawValue) · Queue #\(participant.queuePosition)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Button {
                                        Task {
                                            await viewModel.updateStayedLate(
                                                participantID: participant.id,
                                                stayedLate: !participant.stayedLate
                                            )
                                        }
                                    } label: {
                                        Label(
                                            participant.stayedLate ? "Stayed Late: Yes" : "Stayed Late: No",
                                            systemImage: participant.stayedLate ? "checkmark.circle.fill" : "circle"
                                        )
                                        .font(.footnote)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView("Session unavailable", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.detail == nil {
                await viewModel.load()
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
