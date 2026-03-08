import SwiftUI

struct PaymentsView: View {
    @ObservedObject var viewModel: PaymentsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("Session ID", text: $viewModel.sessionID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    Button {
                        Task { await viewModel.loadSessionPayments() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Load Payments")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }

                Section("Add Payment Method") {
                    Picker("Type", selection: $viewModel.newMethodType) {
                        Text("Venmo").tag(PaymentMethodType.venmo)
                        Text("Zelle").tag(PaymentMethodType.zelle)
                        Text("Other").tag(PaymentMethodType.other)
                    }
                    TextField("Label (e.g. Kevin Venmo)", text: $viewModel.newMethodLabel)
                    TextField("Account Ref (e.g. @kevin)", text: $viewModel.newMethodAccountRef)
                    TextField("Deep Link (optional)", text: $viewModel.newMethodDeepLink)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    Button("Save Method") {
                        Task { await viewModel.addPaymentMethod() }
                    }
                }

                Section("Upsert Payment Record") {
                    TextField("Participant ID", text: $viewModel.recordParticipantID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("Base Fee", text: $viewModel.recordBaseFeeAmount)
                        .keyboardType(.decimalPad)
                    TextField("Late Usage Fee (optional)", text: $viewModel.recordLateUsageFeeAmount)
                        .keyboardType(.decimalPad)
                    Picker("Status", selection: $viewModel.recordStatus) {
                        Text("Unpaid").tag(PaymentStatus.unpaid)
                        Text("Paid").tag(PaymentStatus.paid)
                        Text("Waived").tag(PaymentStatus.waived)
                    }
                    TextField("Note (optional)", text: $viewModel.recordNote)

                    Button("Save Record") {
                        Task { await viewModel.upsertPaymentRecord() }
                    }
                }

                Section("Methods") {
                    if viewModel.paymentMethods.isEmpty {
                        Text("No payment methods")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.paymentMethods) { method in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(method.type.rawValue.uppercased()) · \(method.label)")
                                    .font(.subheadline.weight(.semibold))
                                Text(method.accountRef)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                if let deepLink = method.deepLink, !deepLink.isEmpty {
                                    Text(deepLink)
                                        .font(.footnote)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section("Records") {
                    if viewModel.paymentRecords.isEmpty {
                        Text("No payment records")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.paymentRecords) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Participant: \(record.participantID)")
                                    .font(.subheadline.weight(.semibold))
                                Text("Status: \(record.status.rawValue)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("Base: \(record.baseFeeAmount.formatted(.currency(code: "USD"))), Late: \(record.lateUsageFeeAmount.formatted(.currency(code: "USD")))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("Total: \(record.totalAmount.formatted(.currency(code: "USD")))")
                                    .font(.footnote)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Payments")
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
