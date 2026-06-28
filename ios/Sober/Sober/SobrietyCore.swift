import Foundation

/// App Group used to share sobriety data between the app and its widgets.
/// NOTE: enable this exact group on BOTH targets in Signing & Capabilities.
enum AppGroup {
    static let id = "group.com.sober.app"
    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

/// Milestones used for the progress ring, badges, and celebrations.
enum Milestones {
    struct Badge: Identifiable {
        let id: Int            // threshold in days
        var days: Int { id }
        let icon: String
        let label: String
    }

    static let ring = [7, 14, 30, 60, 90, 180, 270, 365]
    static let badges: [Badge] = [
        Badge(id: 7,   icon: "🌱", label: "1 week"),
        Badge(id: 30,  icon: "⭐️", label: "1 month"),
        Badge(id: 90,  icon: "🔥", label: "90 days"),
        Badge(id: 180, icon: "💪", label: "6 months"),
        Badge(id: 365, icon: "🏆", label: "1 year"),
    ]

    static func next(after days: Int) -> (next: Int, prev: Int) {
        var prev = 0
        for m in ring {
            if days < m { return (m, prev) }
            prev = m
        }
        let years = days / 365 + 1
        return (years * 365, (years - 1) * 365)
    }

    static func label(_ d: Int) -> String {
        let map = [7: "1 week", 14: "2 weeks", 30: "1 month", 60: "2 months",
                   90: "90 days", 180: "6 months", 270: "9 months", 365: "1 year"]
        if let l = map[d] { return l }
        let years = Int((Double(d) / 365).rounded())
        return years == 1 ? "1 year" : "\(years) years"
    }
}

/// Pure, value-type model of the user's sobriety data plus all derived stats.
/// Shared by the app (via SobrietyStore) and the widget timeline provider.
struct SobrietyData {
    var startDate: Date?
    var checkins: Set<String>
    var dailySpend: Double?
    var dailyHours: Double?
    var lastCelebrated: Int
    var reminderEnabled: Bool = false
    var reminderHour: Int = 20
    var reminderMinute: Int = 0

    static let calendar = Calendar.current
    static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: persistence keys
    private static let kStart = "sober.startDate"
    private static let kCheckins = "sober.checkins"
    private static let kSpend = "sober.dailySpend"
    private static let kHours = "sober.dailyHours"
    private static let kCelebrated = "sober.lastCelebrated"
    private static let kReminderOn = "sober.reminderEnabled"
    private static let kReminderH = "sober.reminderHour"
    private static let kReminderM = "sober.reminderMinute"

    static func load() -> SobrietyData {
        let d = AppGroup.defaults
        return SobrietyData(
            startDate: d.object(forKey: kStart) as? Date,
            checkins: Set((d.array(forKey: kCheckins) as? [String]) ?? []),
            dailySpend: d.object(forKey: kSpend) as? Double,
            dailyHours: d.object(forKey: kHours) as? Double,
            lastCelebrated: d.integer(forKey: kCelebrated),
            reminderEnabled: d.bool(forKey: kReminderOn),
            reminderHour: d.object(forKey: kReminderH) as? Int ?? 20,
            reminderMinute: d.object(forKey: kReminderM) as? Int ?? 0
        )
    }

    func save() {
        let d = AppGroup.defaults
        d.set(startDate, forKey: Self.kStart)
        d.set(Array(checkins), forKey: Self.kCheckins)
        if let s = dailySpend { d.set(s, forKey: Self.kSpend) } else { d.removeObject(forKey: Self.kSpend) }
        if let h = dailyHours { d.set(h, forKey: Self.kHours) } else { d.removeObject(forKey: Self.kHours) }
        d.set(lastCelebrated, forKey: Self.kCelebrated)
        d.set(reminderEnabled, forKey: Self.kReminderOn)
        d.set(reminderHour, forKey: Self.kReminderH)
        d.set(reminderMinute, forKey: Self.kReminderM)
    }

    /// Log today as a sober day directly in shared storage (used by the
    /// interactive widget's App Intent, which has no SobrietyStore instance).
    static func checkInTodayInSharedStore() {
        var d = load()
        if d.startDate == nil { d.startDate = Date() }
        d.checkins.insert(d.todayKey)
        d.save()
    }

    // MARK: key helpers
    func key(_ date: Date) -> String { Self.keyFormatter.string(from: date) }
    func date(fromKey k: String) -> Date? { Self.keyFormatter.date(from: k) }
    var todayKey: String { key(Date()) }

    // MARK: status
    func isSober(_ k: String) -> Bool {
        if checkins.contains(k) { return true }
        if let s = startDate { return k >= key(s) && k <= todayKey }
        return false
    }

    var daysSober: Int {
        let cal = Self.calendar
        if let s = startDate {
            let start = cal.startOfDay(for: s)
            let today = cal.startOfDay(for: Date())
            if start <= today {
                return (cal.dateComponents([.day], from: start, to: today).day ?? 0) + 1
            }
        }
        return currentStreak
    }

    var currentStreak: Int {
        let cal = Self.calendar
        var day = cal.startOfDay(for: Date())
        if !isSober(key(day)) { day = cal.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while isSober(key(day)) {
            count += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    func soberKeys() -> [String] {
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

    var bestStreak: Int {
        let cal = Self.calendar
        let keys = soberKeys().sorted()
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

    var totalDays: Int {
        let t = todayKey
        return soberKeys().filter { $0 <= t }.count
    }

    /// Default daily savings — roughly a drink or two. Always applied unless
    /// the user sets their own figure.
    static let defaultDailySpend: Double = 12

    /// Effective $/day (user's value if set, else the default).
    var effectiveDailySpend: Double {
        (dailySpend ?? 0) > 0 ? dailySpend! : Self.defaultDailySpend
    }
    /// Money saved always has a value (defaults to ~$12/day).
    var moneySaved: Double { Double(daysSober) * effectiveDailySpend }
    var hoursSaved: Double? { dailyHours.map { Double(daysSober) * $0 } }

    /// Highest badge milestone reached, for celebration tracking.
    var highestBadgeReached: Int {
        Milestones.badges.filter { daysSober >= $0.days }.map { $0.days }.max() ?? 0
    }
}
