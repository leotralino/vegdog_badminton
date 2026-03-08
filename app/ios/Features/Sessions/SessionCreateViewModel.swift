import SwiftUI

@MainActor
final class SessionCreateViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var location: String = ""
    @Published var startsAt: Date = .now.addingTimeInterval(3600)
    @Published var withdrawDeadline: Date = .now
    @Published var courtCount: String = "2"
    @Published var maxParticipants: String = "8"
    @Published var feeMode: FeeMode = .fixedPerPerson
    @Published var fixedAmount: String = "20"
    @Published var lateWithdrawRatio: String = "1"

    @Published var isSaving = false
    @Published var errorMessage: String?

    private let service: BadmintonServiceProtocol

    init(service: BadmintonServiceProtocol) {
        self.service = service
    }

    func submit() async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = String(localized: "error.title_required")
            return false
        }
        guard !trimmedLocation.isEmpty else {
            errorMessage = String(localized: "error.location_required")
            return false
        }
        guard let courtCount = Int(courtCount), courtCount > 0 else {
            errorMessage = String(localized: "error.court_count_invalid")
            return false
        }
        guard let maxParticipants = Int(maxParticipants), maxParticipants > 0 else {
            errorMessage = String(localized: "error.max_participants_invalid")
            return false
        }
        guard withdrawDeadline <= startsAt else {
            errorMessage = String(localized: "error.withdraw_deadline_invalid")
            return false
        }

        let parsedAmount = Double(fixedAmount)
        if feeMode == .fixedPerPerson && (parsedAmount == nil || parsedAmount! < 0) {
            errorMessage = String(localized: "error.fixed_amount_invalid")
            return false
        }

        let parsedRatio = Double(lateWithdrawRatio)
        if parsedRatio == nil || parsedRatio! < 0 || parsedRatio! > 1 {
            errorMessage = String(localized: "error.late_ratio_invalid")
            return false
        }

        let feeRule = FeeRule(
            mode: feeMode,
            amount: feeMode == .fixedPerPerson ? parsedAmount : nil,
            lateWithdrawRatio: parsedRatio
        )
        let request = CreateSessionRequest(
            title: trimmedTitle,
            startsAt: startsAt,
            endsAt: nil,
            location: trimmedLocation,
            courtCount: courtCount,
            maxParticipants: maxParticipants,
            withdrawDeadline: withdrawDeadline,
            feeRule: feeRule
        )

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await service.createSession(request)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
