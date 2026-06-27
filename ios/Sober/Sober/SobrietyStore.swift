import Foundation
import Combine

/// Holds all sobriety data and derives the counter, streaks, and grid status.
///
/// Persistence: `startDate` and the set of explicit check-in day-keys are
/// stored in `UserDefaults`. Day-keys are "yyyy-MM-dd" strings in the user's
/// local calendar, so lexicographic string comparison matches date order.
final class SobrietyStore: ObservableObject {
    @Published var startDate: Date? { didSet { persist() } }
    @Published var checkins: Set<String> { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private let startKey = "sober.startDate"
    private let checkinsKey = "sober.checkins"

    static let calendar = Calendar.current
    static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        let t = defaults.object(forKey: startKey) as? Date
        self.startDate = t
        if let arr = defaults.array(forKey: checkinsKey) as? [String] {
            self.checkins = Set(arr)
        } else {
            self.checkins = []
        }
    }

    private func persist() {
        defaults.set(startDate, forKey: startKey)
        defaults.set(Array(checkins), forKey: checkinsKey)
    }

    // MARK: - Key helpers

    func key(_ date: Date) -> String { Self.keyFormatter.string(from: date) }
    func date(fromKey k: String) -> Date? { Self.keyFormatter.date(from: k) }
    var todayKey: String { key(Date()) }

    // MARK: - Core status

    /// Is this day-key counted as a sober day?
    func isSober(_ k: String) -> Bool {
        if checkins.contains(k) { return true }
        if let s = startDate {
            return k >= key(s) && k <= todayKey
        }
        return false
    }

    /// The headline counter: days from start date through today, inclusive.
    var daysSober: Int {
        let cal = Self.calendar
        if let s = startDate {
            let start = cal.startOfDay(for: s)
            let today = cal.startOfDay(for: Date())
            if start <= today {
                let d = cal.dateComponents([.day], from: start, to: today).day ?? 0
                return d + 1
            }
        }
        return currentStreak
    }

    /// Consecutive sober days ending today (or yesterday if today isn't logged yet).
    var currentStreak: Int {
        let cal = Self.calendar
        var day = cal.startOfDay(for: Date())
        if !isSober(key(day)) {
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        var count = 0
        while isSober(key(day)) {
            count += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    /// All sober day-keys: explicit check-ins plus the start-date → today range.
    private var soberKeys: [String] {
        var set = checkins
        if let s = startDate {
            let cal = Self.calendar
            var day = cal.startOfDay(for: s)
            let end = cal.startOfDay(for: Date())
            while day <= end {
                set.insert(key(day))
                day = cal.date(byAdding: .day, value: 1, to: day)!
            }
        }
        return Array(set)
    }

    /// Longest run of consecutive sober days across all data.
    var bestStreak: Int {
        let cal = Self.calendar
        let keys = soberKeys.sorted()
        guard !keys.isEmpty else { return 0 }
        var best = 1, run = 1
        for i in 1..<keys.count {
            guard let a = date(fromKey: keys[i - 1]), let b = date(fromKey: keys[i]) else { continue }
            let diff = cal.dateComponents([.day], from: a, to: b).day ?? 0
            run = (diff == 1) ? run + 1 : 1
            best = max(best, run)
        }
        return best
    }

    /// Total sober days up to and including today.
    var totalDays: Int {
        let t = todayKey
        return soberKeys.filter { $0 <= t }.count
    }

    // MARK: - Mutations

    /// Log today as sober. Seeds the start date on the very first check-in.
    func checkInToday() {
        let k = todayKey
        if startDate == nil { startDate = Date() }
        checkins.insert(k)
    }

    var isCheckedInToday: Bool { isSober(todayKey) }

    func reset() {
        startDate = nil
        checkins = []
    }
}
