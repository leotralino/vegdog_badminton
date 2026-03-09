import SwiftUI

@MainActor
final class SessionCreateViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var location: String = ""
    @Published var startsAt: Date
    @Published var withdrawDeadline: Date
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
        let defaults = Self.defaultSchedule()
        self.startsAt = defaults.startsAt
        self.withdrawDeadline = defaults.withdrawDeadline
    }

    func normalizeStartTime() {
        startsAt = Self.roundToQuarterHour(startsAt)
        if withdrawDeadline > startsAt {
            withdrawDeadline = startsAt
        }
    }

    func normalizeWithdrawDeadline() {
        withdrawDeadline = Self.roundToQuarterHour(withdrawDeadline)
        if withdrawDeadline > startsAt {
            withdrawDeadline = startsAt
        }
    }

    func submit() async -> Bool {
        normalizeStartTime()
        normalizeWithdrawDeadline()

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

    private static func defaultSchedule(now: Date = Date()) -> (startsAt: Date, withdrawDeadline: Date) {
        let calendar = Calendar(identifier: .gregorian)
        var fridayComponents = DateComponents()
        fridayComponents.weekday = 6
        fridayComponents.hour = 20
        fridayComponents.minute = 0
        var nextFriday = calendar.nextDate(
            after: now,
            matching: fridayComponents,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? now.addingTimeInterval(7 * 24 * 60 * 60)
        nextFriday = roundToQuarterHour(nextFriday)

        var withdraw = calendar.date(byAdding: .day, value: -2, to: nextFriday) ?? now
        withdraw = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: withdraw) ?? withdraw
        withdraw = roundToQuarterHour(withdraw)
        return (nextFriday, min(withdraw, nextFriday))
    }

    private static func roundToQuarterHour(_ date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let rounded = Int((Double(minute) / 15.0).rounded()) * 15
        if rounded == 60 {
            let normalized = calendar.date(byAdding: .hour, value: 1, to: date) ?? date
            components = calendar.dateComponents([.year, .month, .day, .hour], from: normalized)
            components.minute = 0
        } else {
            components.minute = rounded
        }
        components.second = 0
        return calendar.date(from: components) ?? date
    }
}
