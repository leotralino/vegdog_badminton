import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var viewModel: SessionDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                ProgressView("sessions.detail.loading")
            } else if let detail = viewModel.detail {
                List {
                    Section("sessions.detail.section_session") {
                        Text(detail.title)
                            .font(.headline)
                        Text("\(detail.location) · \(detail.startsAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(String(localized: "sessions.detail.status")): \(detail.status.rawValue)")
                            .font(.footnote)
                        Text("\(String(localized: "sessions.detail.withdraw_deadline")): \(detail.withdrawDeadline.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                        Text("\(String(localized: "sessions.detail.initiator")): \(detail.initiatorUser.nickname)")
                            .font(.footnote)
                    }

                    Section("sessions.detail.section_admins") {
                        ForEach(detail.admins) { admin in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(admin.nickname)
                                    .font(.subheadline.weight(.semibold))
                                Text(admin.userID)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if viewModel.isCurrentUserAdmin {
                            TextField("sessions.detail.new_admin_user_id", text: $viewModel.newAdminUserID)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                            TextField("sessions.detail.new_admin_nickname", text: $viewModel.newAdminNickname)
                            Button("sessions.detail.add_admin") {
                                Task { await viewModel.addAdmin() }
                            }
                        } else {
                            Text("sessions.detail.only_admin_add")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("sessions.detail.section_actions") {
                        HStack {
                            Button("sessions.join") { Task { await viewModel.join() } }
                                .buttonStyle(.borderedProminent)
                            Button("sessions.withdraw") { Task { await viewModel.withdraw() } }
                                .buttonStyle(.bordered)
                            Button("sessions.finalize") { Task { await viewModel.finalize() } }
                                .buttonStyle(.bordered)
                                .disabled(!viewModel.isCurrentUserAdmin)
                        }
                    }

                    Section("sessions.detail.section_participants") {
                        if detail.participants.isEmpty {
                            Text("sessions.detail.no_participants")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(detail.participants) { participant in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(participant.user.nickname)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(String(localized: "sessions.detail.participant_status")): \(participant.status.rawValue) · #\(participant.queuePosition)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Button {
                                        guard viewModel.isCurrentUserAdmin else { return }
                                        Task {
                                            await viewModel.updateStayedLate(
                                                participantID: participant.id,
                                                stayedLate: !participant.stayedLate
                                            )
                                        }
                                    } label: {
                                        Label(
                                            participant.stayedLate
                                                ? String(localized: "sessions.detail.stayed_late_yes")
                                                : String(localized: "sessions.detail.stayed_late_no"),
                                            systemImage: participant.stayedLate ? "checkmark.circle.fill" : "circle"
                                        )
                                        .font(.footnote)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!viewModel.isCurrentUserAdmin)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
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
}
