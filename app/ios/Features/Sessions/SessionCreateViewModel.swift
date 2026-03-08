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
            errorMessage = "Title is required."
            return false
        }
        guard !trimmedLocation.isEmpty else {
            errorMessage = "Location is required."
            return false
        }
        guard let courtCount = Int(courtCount), courtCount > 0 else {
            errorMessage = "Court count must be a positive integer."
            return false
        }
        guard let maxParticipants = Int(maxParticipants), maxParticipants > 0 else {
            errorMessage = "Max participants must be a positive integer."
            return false
        }
        guard withdrawDeadline <= startsAt else {
            errorMessage = "Withdraw deadline should be before session start."
            return false
        }

        let parsedAmount = Double(fixedAmount)
        if feeMode == .fixedPerPerson && (parsedAmount == nil || parsedAmount! < 0) {
            errorMessage = "Fixed amount must be a non-negative number."
            return false
        }

        let parsedRatio = Double(lateWithdrawRatio)
        if parsedRatio == nil || parsedRatio! < 0 || parsedRatio! > 1 {
            errorMessage = "Late withdraw ratio must be between 0 and 1."
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
