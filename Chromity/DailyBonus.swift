
import Foundation

enum DailyBonus {
    static let amount = 150

    private static let key = "LastDailyBonusClaim"

    static var isAvailable: Bool {
        guard let last = UserDefaults.standard.object(forKey: key) as? Date else { return true }
        if last > Date() {
            UserDefaults.standard.set(Date(), forKey: key)
            return false
        }
        return !Calendar.current.isDateInToday(last)
    }

    static func markClaimed() {
        UserDefaults.standard.set(Date(), forKey: key)
    }
}
