import SwiftUI

@MainActor
final class PaymentsViewModel: ObservableObject {
    @Published var sessionID: String = ""
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var paymentRecords: [PaymentRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var newMethodType: PaymentMethodType = .venmo
    @Published var newMethodLabel: String = ""
    @Published var newMethodAccountRef: String = ""
    @Published var newMethodDeepLink: String = ""

    @Published var recordParticipantID: String = ""
    @Published var recordBaseFeeAmount: String = ""
    @Published var recordLateUsageFeeAmount: String = ""
    @Published var recordStatus: PaymentStatus = .unpaid
    @Published var recordNote: String = ""

    private let service: BadmintonServiceProtocol

    init(service: BadmintonServiceProtocol) {
        self.service = service
    }

    func loadSessionPayments() async {
        let id = sanitizedSessionID()
        guard !id.isEmpty else {
            errorMessage = String(localized: "error.session_id_required")
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let methods = service.listPaymentMethods(sessionID: id)
            async let records = service.listPaymentRecords(sessionID: id)
            paymentMethods = try await methods
            paymentRecords = try await records
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addPaymentMethod() async {
        let id = sanitizedSessionID()
        guard !id.isEmpty else {
            errorMessage = String(localized: "error.session_id_required")
            return
        }
        guard !newMethodLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = String(localized: "error.method_label_required")
            return
        }
        guard !newMethodAccountRef.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = String(localized: "error.account_ref_required")
            return
        }

        let request = CreatePaymentMethodRequest(
            type: newMethodType,
            label: newMethodLabel.trimmingCharacters(in: .whitespacesAndNewlines),
            accountRef: newMethodAccountRef.trimmingCharacters(in: .whitespacesAndNewlines),
            deepLink: optionalTrimmed(newMethodDeepLink)
        )

        do {
            _ = try await service.createPaymentMethod(sessionID: id, request: request)
            resetMethodForm()
            await loadSessionPayments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func upsertPaymentRecord() async {
        let id = sanitizedSessionID()
        guard !id.isEmpty else {
            errorMessage = String(localized: "error.session_id_required")
            return
        }
        let participantID = recordParticipantID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !participantID.isEmpty else {
            errorMessage = String(localized: "error.participant_id_required")
            return
        }
        guard let baseFee = Double(recordBaseFeeAmount) else {
            errorMessage = String(localized: "error.base_fee_invalid")
            return
        }

        let lateUsage = Double(recordLateUsageFeeAmount)
        let request = UpsertPaymentRecordRequest(
            participantID: participantID,
            baseFeeAmount: baseFee,
            lateUsageFeeAmount: lateUsage,
            status: recordStatus,
            note: optionalTrimmed(recordNote)
        )

        do {
            _ = try await service.upsertPaymentRecord(sessionID: id, request: request)
            resetRecordForm()
            await loadSessionPayments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sanitizedSessionID() -> String {
        sessionID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func optionalTrimmed(_ raw: String) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func resetMethodForm() {
        newMethodType = .venmo
        newMethodLabel = ""
        newMethodAccountRef = ""
        newMethodDeepLink = ""
    }

    private func resetRecordForm() {
        recordParticipantID = ""
        recordBaseFeeAmount = ""
        recordLateUsageFeeAmount = ""
        recordStatus = .unpaid
        recordNote = ""
    }
}
