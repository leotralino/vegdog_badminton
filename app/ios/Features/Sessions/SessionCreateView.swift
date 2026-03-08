import SwiftUI

struct SessionCreateView: View {
    @ObservedObject var viewModel: SessionCreateViewModel
    let onCancel: () -> Void
    let onCreated: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic") {
                    TextField("Title", text: $viewModel.title)
                    TextField("Location", text: $viewModel.location)
                }

                Section("Schedule") {
                    DatePicker("Starts At", selection: $viewModel.startsAt)
                    DatePicker("Withdraw Deadline", selection: $viewModel.withdrawDeadline)
                }

                Section("Capacity") {
                    TextField("Court Count", text: $viewModel.courtCount)
                        .keyboardType(.numberPad)
                    TextField("Max Participants", text: $viewModel.maxParticipants)
                        .keyboardType(.numberPad)
                }

                Section("Fee Rule") {
                    Picker("Mode", selection: $viewModel.feeMode) {
                        Text("Fixed Per Person").tag(FeeMode.fixedPerPerson)
                        Text("Split By Attendance").tag(FeeMode.splitByAttendance)
                    }
                    if viewModel.feeMode == .fixedPerPerson {
                        TextField("Amount (USD)", text: $viewModel.fixedAmount)
                            .keyboardType(.decimalPad)
                    }
                    TextField("Late Withdraw Ratio (0~1)", text: $viewModel.lateWithdrawRatio)
                        .keyboardType(.decimalPad)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create Session")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
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
                            Text("Create")
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
    }
}
