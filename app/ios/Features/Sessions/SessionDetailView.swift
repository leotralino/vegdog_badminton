import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var viewModel: SessionDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                ProgressView("sessions.detail.loading")
            } else if let detail = viewModel.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SessionMetaCard(detail: detail)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("sessions.detail.section_participants")
                                .font(.headline)

                            if activeParticipants(detail).isEmpty {
                                Text("sessions.detail.no_participants")
                                    .foregroundStyle(.secondary)
                            } else {
                                let joined = joinedParticipants(detail)
                                let waitlist = waitlistParticipants(detail)

                                ForEach(joined) { participant in
                                    QueueParticipantRow(
                                        participant: participant,
                                        isAdmin: isAdminEntry(detail: detail, participant: participant),
                                        canRemove: canRemove(participant),
                                        onRemove: {
                                            Task { await viewModel.removeEntry(participantID: participant.id) }
                                        }
                                    )
                                }

                                if !waitlist.isEmpty {
                                    Divider()
                                    Text("sessions.detail.waitlist")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    ForEach(waitlist) { participant in
                                        QueueParticipantRow(
                                            participant: participant,
                                            isAdmin: isAdminEntry(detail: detail, participant: participant),
                                            canRemove: canRemove(participant),
                                            onRemove: {
                                                Task { await viewModel.removeEntry(participantID: participant.id) }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        if !withdrawnParticipants(detail).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("sessions.detail.withdrawn")
                                    .font(.headline)
                                ForEach(withdrawnParticipants(detail)) { participant in
                                    HStack {
                                        Text(participant.displayName)
                                        Spacer()
                                        Text(
                                            participant.status == .lateWithdraw
                                                ? String(localized: "sessions.detail.withdrawn_late")
                                                : String(localized: "sessions.detail.withdrawn_normal")
                                        )
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(14)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        Button("sessions.join") {
                            Task { await viewModel.joinEntry() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("sessions.detail.unavailable", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("sessions.detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LanguageToggleButton()
            }
        }
        .task {
            if viewModel.detail == nil {
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

    private func activeParticipants(_ detail: SessionDetail) -> [SessionParticipant] {
        detail.participants
            .filter { $0.status == .joined || $0.status == .waitlist }
            .sorted { $0.queuePosition < $1.queuePosition }
    }

    private func joinedParticipants(_ detail: SessionDetail) -> [SessionParticipant] {
        activeParticipants(detail).filter { $0.status == .joined }
    }

    private func waitlistParticipants(_ detail: SessionDetail) -> [SessionParticipant] {
        activeParticipants(detail).filter { $0.status == .waitlist }
    }

    private func withdrawnParticipants(_ detail: SessionDetail) -> [SessionParticipant] {
        detail.participants
            .filter { $0.status == .withdrawn || $0.status == .lateWithdraw }
            .sorted { lhs, rhs in
                (lhs.withdrewAt ?? lhs.joinedAt) > (rhs.withdrewAt ?? rhs.joinedAt)
            }
    }

    private func isAdminEntry(detail: SessionDetail, participant: SessionParticipant) -> Bool {
        detail.admins.contains(where: { $0.userID == participant.ownerUserID })
    }

    private func canRemove(_ participant: SessionParticipant) -> Bool {
        participant.ownerUserID == viewModel.currentUserID
    }
}

private struct SessionMetaCard: View {
    let detail: SessionDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.title)
                .font(.title3.weight(.semibold))
            Text("\(detail.startsAt.formatted(date: .abbreviated, time: .shortened)) · \(detail.location)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(String(localized: "sessions.initiator")): \(detail.initiatorUser.nickname)")
                .font(.footnote)
            Text("\(String(localized: "sessions.max")): \(detail.maxParticipants)")
                .font(.footnote)
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct QueueParticipantRow: View {
    let participant: SessionParticipant
    let isAdmin: Bool
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isAdmin ? "\(participant.displayName) (admin)" : participant.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("#\(participant.queuePosition)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
