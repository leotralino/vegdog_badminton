import SwiftUI

struct PaymentsView: View {
    @ObservedObject var viewModel: PaymentsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("payments.section_session") {
                    TextField("payments.session_id", text: $viewModel.sessionID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    Button {
                        Task { await viewModel.loadSessionPayments() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("payments.load")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }

                Section("payments.section_add_method") {
                    Picker("payments.method_type", selection: $viewModel.newMethodType) {
                        Text("payments.type_venmo").tag(PaymentMethodType.venmo)
                        Text("payments.type_zelle").tag(PaymentMethodType.zelle)
                        Text("payments.type_other").tag(PaymentMethodType.other)
                    }
                    TextField("payments.method_label", text: $viewModel.newMethodLabel)
                    TextField("payments.method_account_ref", text: $viewModel.newMethodAccountRef)
                    TextField("payments.method_deep_link", text: $viewModel.newMethodDeepLink)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    Button("payments.save_method") {
                        Task { await viewModel.addPaymentMethod() }
                    }
                }

                Section("payments.section_upsert_record") {
                    TextField("payments.participant_id", text: $viewModel.recordParticipantID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("payments.base_fee", text: $viewModel.recordBaseFeeAmount)
                        .keyboardType(.decimalPad)
                    TextField("payments.late_fee", text: $viewModel.recordLateUsageFeeAmount)
                        .keyboardType(.decimalPad)
                    Picker("payments.status", selection: $viewModel.recordStatus) {
                        Text("payments.status_unpaid").tag(PaymentStatus.unpaid)
                        Text("payments.status_paid").tag(PaymentStatus.paid)
                        Text("payments.status_waived").tag(PaymentStatus.waived)
                    }
                    TextField("payments.note", text: $viewModel.recordNote)

                    Button("payments.save_record") {
                        Task { await viewModel.upsertPaymentRecord() }
                    }
                }

                Section("payments.section_methods") {
                    if viewModel.paymentMethods.isEmpty {
                        Text("payments.no_methods")
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

                Section("payments.section_records") {
                    if viewModel.paymentRecords.isEmpty {
                        Text("payments.no_records")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.paymentRecords) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(String(localized: "payments.participant")): \(record.participantID)")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(String(localized: "payments.status")): \(record.status.rawValue)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("\(String(localized: "payments.base")): \(record.baseFeeAmount.formatted(.currency(code: "USD"))), \(String(localized: "payments.late")): \(record.lateUsageFeeAmount.formatted(.currency(code: "USD")))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("\(String(localized: "payments.total")): \(record.totalAmount.formatted(.currency(code: "USD")))")
                                    .font(.footnote)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("payments.title")
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
}
