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
    var excluded: Set<String> = []   // days explicitly marked NOT sober
    var dailySpend: Double?
    var dailyHours: Double?
    var lastCelebrated: Int
    var reminderEnabled: Bool = false
    var reminderHour: Int = 20
    var reminderMinute: Int = 0
    var why: String = ""
    var mode222: Bool = false
    var drinks: [String: Int] = [:]   // day key -> drink count (2-2-2 mode)

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
    private static let kExcluded = "sober.excluded"
    private static let kSpend = "sober.dailySpend"
    private static let kHours = "sober.dailyHours"
    private static let kCelebrated = "sober.lastCelebrated"
    private static let kReminderOn = "sober.reminderEnabled"
    private static let kReminderH = "sober.reminderHour"
    private static let kReminderM = "sober.reminderMinute"
    private static let kWhy = "sober.why"
    private static let kMode222 = "sober.mode222"
    private static let kDrinks = "sober.drinks"

    static func load() -> SobrietyData {
        let d = AppGroup.defaults
        return SobrietyData(
            startDate: d.object(forKey: kStart) as? Date,
            checkins: Set((d.array(forKey: kCheckins) as? [String]) ?? []),
            excluded: Set((d.array(forKey: kExcluded) as? [String]) ?? []),
            dailySpend: d.object(forKey: kSpend) as? Double,
            dailyHours: d.object(forKey: kHours) as? Double,
            lastCelebrated: d.integer(forKey: kCelebrated),
            reminderEnabled: d.bool(forKey: kReminderOn),
            reminderHour: d.object(forKey: kReminderH) as? Int ?? 20,
            reminderMinute: d.object(forKey: kReminderM) as? Int ?? 0,
            why: d.string(forKey: kWhy) ?? "",
            mode222: d.bool(forKey: kMode222),
            drinks: (d.dictionary(forKey: kDrinks) as? [String: Int]) ?? [:]
        )
    }

    func save() {
        let d = AppGroup.defaults
        d.set(startDate, forKey: Self.kStart)
        d.set(Array(checkins), forKey: Self.kCheckins)
        d.set(Array(excluded), forKey: Self.kExcluded)
        if let s = dailySpend { d.set(s, forKey: Self.kSpend) } else { d.removeObject(forKey: Self.kSpend) }
        if let h = dailyHours { d.set(h, forKey: Self.kHours) } else { d.removeObject(forKey: Self.kHours) }
        d.set(lastCelebrated, forKey: Self.kCelebrated)
        d.set(reminderEnabled, forKey: Self.kReminderOn)
        d.set(reminderHour, forKey: Self.kReminderH)
        d.set(reminderMinute, forKey: Self.kReminderM)
        d.set(why, forKey: Self.kWhy)
        d.set(mode222, forKey: Self.kMode222)
        d.set(drinks, forKey: Self.kDrinks)
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
        if (drinks[k] ?? 0) > 0 { return false }    // a drinking day isn't sober
        if excluded.contains(k) { return false }    // explicitly marked not sober
        if checkins.contains(k) { return true }
        if let s = startDate { return k >= key(s) && k <= todayKey }
        return false
    }

    /// Headline = current run of consecutive sober days ending today (honors edits).
    var daysSober: Int { currentStreak }

    /// First day of the current sober streak (for the "since" label), or nil.
    var streakStartDate: Date? {
        let n = currentStreak
        guard n > 0 else { return nil }
        let cal = Self.calendar
        var day = cal.startOfDay(for: Date())
        if !isSober(key(day)) { day = cal.date(byAdding: .day, value: -1, to: day)! }
        return cal.date(byAdding: .day, value: -(n - 1), to: day)
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
        set.subtract(excluded)
        for (k, n) in drinks where n > 0 { set.remove(k) }
        return Array(set)
    }

    // MARK: 2-2-2 (Kevin Rose) — evaluated over a rolling 7 days
    struct Eval222 { let nights: Int; let rule1ok: Bool; let rule2ok: Bool; let rule3ok: Bool }
    func eval222() -> Eval222 {
        let cal = Self.calendar
        var weekKeys: [String] = []
        for i in 0..<7 {
            let day = cal.date(byAdding: .day, value: -i, to: cal.startOfDay(for: Date()))!
            weekKeys.append(key(day))
        }
        weekKeys.sort()
        func d(_ k: String) -> Int { drinks[k] ?? 0 }
        let nights = weekKeys.filter { d($0) > 0 }.count
        let maxPerDay = weekKeys.map { d($0) }.max() ?? 0
        var backToBack = false
        for i in 1..<weekKeys.count where d(weekKeys[i - 1]) > 0 && d(weekKeys[i]) > 0 { backToBack = true }
        return Eval222(nights: nights, rule1ok: maxPerDay <= 2, rule2ok: !backToBack, rule3ok: nights <= 2)
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
