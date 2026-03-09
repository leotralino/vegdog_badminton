import Foundation

enum DateDisplay {
    private static let weekdayMap: [Int: String] = [
        1: "周日", 2: "周一", 3: "周二", 4: "周三", 5: "周四", 6: "周五", 7: "周六"
    ]
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mma"
        return formatter
    }()

    static func session(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = weekdayMap[calendar.component(.weekday, from: date)] ?? ""
        let time = timeFormatter.string(from: date).lowercased()
        return "\(month)月\(day)日，\(year)（\(weekday)），\(time)"
    }

    static func shouldMoveToHistory(_ session: Session, now: Date = Date()) -> Bool {
        if session.status == .locked {
            return now >= session.startsAt.addingTimeInterval(3 * 60 * 60)
        }
        return session.startsAt < now
    }
}
