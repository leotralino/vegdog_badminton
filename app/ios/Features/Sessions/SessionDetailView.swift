import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    @AppStorage("profile.avatar_url") private var currentUserAvatarURL: String = ""
    @AppStorage("profile.gender") private var currentUserGender: String = ""
    @AppStorage("profile.level") private var currentUserLevel: String = ""

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                ProgressView("sessions.detail.loading")
            } else if let detail = viewModel.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SessionMetaCard(
                            detail: detail,
                            canLock: viewModel.isCurrentUserAdmin && detail.status != .locked,
                            onLock: { Task { await viewModel.finalize() } }
                        )

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
                                        avatarURL: avatarURL(for: participant),
                                        showLateControl: showLateControl(detail: detail),
                                        canRecordLate: canToggleLate(detail: detail),
                                        metadataText: metadataText(for: participant),
                                        onToggleLate: {
                                            Task {
                                                await viewModel.updateStayedLate(
                                                    participantID: participant.id,
                                                    stayedLate: !participant.stayedLate
                                                )
                                            }
                                        },
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
                                            avatarURL: avatarURL(for: participant),
                                            showLateControl: showLateControl(detail: detail),
                                            canRecordLate: canToggleLate(detail: detail),
                                            metadataText: metadataText(for: participant),
                                            onToggleLate: {
                                                Task {
                                                    await viewModel.updateStayedLate(
                                                        participantID: participant.id,
                                                        stayedLate: !participant.stayedLate
                                                    )
                                                }
                                            },
                                            onRemove: {
                                                Task { await viewModel.removeEntry(participantID: participant.id) }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .notionCard()

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
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .notionCard()
                        }

                        if detail.status == .locked {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("sessions.detail.payment_status")
                                    .font(.headline)
                                ForEach(liableParticipants(detail)) { participant in
                                    HStack {
                                        Text(participant.displayName)
                                        Spacer()
                                        Text(paymentStatusText(for: participant.id))
                                            .font(.footnote.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(paymentStatusColor(for: participant.id).opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .notionCard()
                        }

                        if detail.status != .locked {
                            Button("sessions.join") {
                                Task { await viewModel.joinEntry() }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Text("sessions.detail.locked_notice")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            } else {
                ContentUnavailableView("sessions.detail.unavailable", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("sessions.detail.title")
        .navigationBarTitleDisplayMode(.inline)
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

    private func liableParticipants(_ detail: SessionDetail) -> [SessionParticipant] {
        detail.participants
            .filter { $0.status == .joined || $0.status == .lateWithdraw }
            .sorted { $0.queuePosition < $1.queuePosition }
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
        guard let detail = viewModel.detail, detail.status != .locked else { return false }
        return participant.ownerUserID == viewModel.currentUserID
    }

    private func showLateControl(detail: SessionDetail) -> Bool {
        viewModel.isCurrentUserAdmin && detail.status == .locked
    }

    private func canToggleLate(detail: SessionDetail) -> Bool {
        showLateControl(detail: detail) && Date() >= detail.startsAt
    }

    private func avatarURL(for participant: SessionParticipant) -> String? {
        if participant.ownerUserID == viewModel.currentUserID, !currentUserAvatarURL.isEmpty {
            return currentUserAvatarURL
        }
        return participant.user.avatarURL
    }

    private func metadataText(for participant: SessionParticipant) -> String? {
        if participant.ownerUserID == viewModel.currentUserID {
            let items = [localizedGender(currentUserGender), currentUserLevel.trimmingCharacters(in: .whitespacesAndNewlines)]
                .filter { !$0.isEmpty }
            return items.isEmpty ? nil : items.joined(separator: " · ")
        }
        return nil
    }

    private func localizedGender(_ raw: String) -> String {
        switch raw {
        case "male":
            return String(localized: "settings.gender_male")
        case "female":
            return String(localized: "settings.gender_female")
        case "other":
            return String(localized: "settings.gender_other")
        default:
            return ""
        }
    }

    private func paymentStatus(for participantID: String) -> PaymentStatus? {
        viewModel.paymentRecords.first(where: { $0.participantID == participantID })?.status
    }

    private func paymentStatusText(for participantID: String) -> String {
        switch paymentStatus(for: participantID) {
        case .paid:
            return String(localized: "payments.status_paid")
        case .waived:
            return String(localized: "payments.status_waived")
        case .unpaid:
            return String(localized: "payments.status_unpaid")
        case nil:
            return String(localized: "payments.status_unpaid")
        }
    }

    private func paymentStatusColor(for participantID: String) -> Color {
        switch paymentStatus(for: participantID) {
        case .paid:
            return .green
        case .waived:
            return .orange
        case .unpaid, nil:
            return .red
        }
    }
}

private struct SessionMetaCard: View {
    let detail: SessionDetail
    let canLock: Bool
    let onLock: () -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detail.title)
                .font(.title3.weight(.semibold))
            VStack(alignment: .leading, spacing: 8) {
                metaRow(systemIcon: "calendar", value: DateDisplay.session(detail.startsAt), expanded: true)
                metaRow(systemIcon: "mappin.and.ellipse", value: detail.location, expanded: isExpanded)
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle")
                    AvatarView(avatarURL: detail.initiatorUser.avatarURL, size: 22)
                    Text("\(String(localized: "sessions.initiator")): \(detail.initiatorUser.nickname)")
                }
                .font(.subheadline.weight(.semibold))
                metaRow(systemIcon: "person.3", value: "\(String(localized: "sessions.max_people_label")): \(detail.maxParticipants)", expanded: true)
            }
            Button(isExpanded ? "sessions.detail.collapse" : "sessions.detail.expand") {
                isExpanded.toggle()
            }
            .font(.footnote)
            if canLock {
                Button("sessions.finalize", action: onLock)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .notionCard()
    }

    private func metaRow(systemIcon: String, value: String, expanded: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemIcon)
            Text(value)
                .lineLimit(expanded ? nil : 1)
                .fixedSize(horizontal: false, vertical: expanded)
                .multilineTextAlignment(.leading)
        }
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct QueueParticipantRow: View {
    let participant: SessionParticipant
    let isAdmin: Bool
    let canRemove: Bool
    let avatarURL: String?
    let showLateControl: Bool
    let canRecordLate: Bool
    let metadataText: String?
    let onToggleLate: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            AvatarView(avatarURL: avatarURL, size: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(isAdmin ? "\(participant.displayName) (admin)" : participant.displayName)
                    .font(.subheadline.weight(.semibold))
                if let metadataText, !metadataText.isEmpty {
                    Text(metadataText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("#\(participant.queuePosition)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                if showLateControl {
                    Button {
                        onToggleLate()
                    } label: {
                        Image(systemName: participant.stayedLate ? "checkmark.square.fill" : "square")
                            .foregroundStyle(canRecordLate ? .green : .gray)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canRecordLate)
                }
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 88, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}
