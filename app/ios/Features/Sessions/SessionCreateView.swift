import SwiftUI

struct SessionCreateView: View {
    @ObservedObject var viewModel: SessionCreateViewModel
    let onCancel: () -> Void
    let onCreated: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("sessions.create.basic") {
                    TextField("sessions.create.title_placeholder", text: $viewModel.title)
                    TextField("sessions.create.location_placeholder", text: $viewModel.location)
                }

                Section("sessions.create.schedule") {
                    DatePicker(
                        "sessions.create.starts_at",
                        selection: Binding(
                            get: { viewModel.startsAt },
                            set: { newValue in
                                viewModel.startsAt = newValue
                                viewModel.normalizeStartTime()
                            }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    Text(DateDisplay.session(viewModel.startsAt))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "sessions.create.withdraw_deadline",
                        selection: Binding(
                            get: { viewModel.withdrawDeadline },
                            set: { newValue in
                                viewModel.withdrawDeadline = newValue
                                viewModel.normalizeWithdrawDeadline()
                            }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    Text(DateDisplay.session(viewModel.withdrawDeadline))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("sessions.create.capacity") {
                    TextField("sessions.create.court_count", text: $viewModel.courtCount)
                        .keyboardType(.numberPad)
                    TextField("sessions.create.max_participants", text: $viewModel.maxParticipants)
                        .keyboardType(.numberPad)
                }

                Section("sessions.create.fee_rule") {
                    Picker("sessions.create.mode", selection: $viewModel.feeMode) {
                        Text("sessions.create.fixed_per_person").tag(FeeMode.fixedPerPerson)
                        Text("sessions.create.split_by_attendance").tag(FeeMode.splitByAttendance)
                    }
                    if viewModel.feeMode == .fixedPerPerson {
                        TextField("sessions.create.amount_usd", text: $viewModel.fixedAmount)
                            .keyboardType(.decimalPad)
                    }
                    TextField("sessions.create.late_ratio", text: $viewModel.lateWithdrawRatio)
                        .keyboardType(.decimalPad)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("sessions.create.title")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let success = await viewModel.submit()
                            guard success else { return }
                            await onCreated()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("sessions.create.submit")
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
    }
}
