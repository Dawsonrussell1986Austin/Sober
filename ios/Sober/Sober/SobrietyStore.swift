import Foundation
import Combine
import WidgetKit

/// Observable wrapper around `SobrietyData`. Persists to the shared App Group
/// (so widgets see the same data) and reloads widget timelines on every change.
/// All stat math lives in `SobrietyData` so the widget can reuse it.
final class SobrietyStore: ObservableObject {
    @Published var startDate: Date? { didSet { persist() } }
    @Published var checkins: Set<String> { didSet { persist() } }
    @Published var excluded: Set<String> { didSet { persist() } }
    @Published var dailySpend: Double? { didSet { persist() } }
    @Published var dailyHours: Double? { didSet { persist() } }
    @Published var lastCelebrated: Int { didSet { persist() } }
    @Published var reminderEnabled: Bool { didSet { persist() } }
    @Published var reminderHour: Int { didSet { persist() } }
    @Published var reminderMinute: Int { didSet { persist() } }
    @Published var why: String { didSet { persist() } }
    @Published var mode222: Bool { didSet { persist() } }
    @Published var drinks: [String: Int] { didSet { persist() } }

    private var suppressPersist = false

    init() {
        let d = SobrietyData.load()
        startDate = d.startDate
        checkins = d.checkins
        excluded = d.excluded
        dailySpend = d.dailySpend
        dailyHours = d.dailyHours
        lastCelebrated = d.lastCelebrated
        reminderEnabled = d.reminderEnabled
        reminderHour = d.reminderHour
        reminderMinute = d.reminderMinute
        why = d.why
        mode222 = d.mode222
        drinks = d.drinks
    }

    /// Re-read from shared storage (e.g. after the interactive widget logs a
    /// check-in while the app was backgrounded). Avoids re-persisting.
    func reload() {
        let d = SobrietyData.load()
        suppressPersist = true
        startDate = d.startDate
        checkins = d.checkins
        excluded = d.excluded
        dailySpend = d.dailySpend
        dailyHours = d.dailyHours
        lastCelebrated = d.lastCelebrated
        reminderEnabled = d.reminderEnabled
        reminderHour = d.reminderHour
        reminderMinute = d.reminderMinute
        why = d.why
        mode222 = d.mode222
        drinks = d.drinks
        suppressPersist = false
    }

    /// Snapshot for stat computations (all logic lives in SobrietyData).
    var data: SobrietyData {
        SobrietyData(startDate: startDate, checkins: checkins, excluded: excluded,
                     dailySpend: dailySpend, dailyHours: dailyHours,
                     lastCelebrated: lastCelebrated,
                     reminderEnabled: reminderEnabled,
                     reminderHour: reminderHour, reminderMinute: reminderMinute,
                     why: why, mode222: mode222, drinks: drinks)
    }

    private func persist() {
        guard !suppressPersist else { return }
        data.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Derived stats (delegated)
    var daysSober: Int { data.daysSober }
    var currentStreak: Int { data.currentStreak }
    var bestStreak: Int { data.bestStreak }
    var totalDays: Int { data.totalDays }
    var moneySaved: Double { data.moneySaved }
    var hoursSaved: Double? { data.hoursSaved }
    var isCheckedInToday: Bool { data.isSober(data.todayKey) }
    func isSober(_ k: String) -> Bool { data.isSober(k) }
    func key(_ date: Date) -> String { data.key(date) }
    var todayKey: String { data.todayKey }

    // MARK: - Mutations
    func checkInToday() {
        if startDate == nil { startDate = Date() }
        checkins.insert(todayKey)
    }

    /// Toggle whether a given day (today or earlier) counts as sober.
    func toggleDay(_ key: String) {
        guard key <= todayKey else { return }
        if isSober(key) {
            checkins.remove(key)
            excluded.insert(key)
        } else {
            excluded.remove(key)
            checkins.insert(key)
        }
    }

    /// Set the drink count for a day (2-2-2 mode). 0 clears it back to sober.
    func setDrinks(_ key: String, _ count: Int) {
        guard key <= todayKey else { return }
        if count > 0 {
            drinks[key] = count
            checkins.remove(key)
            excluded.remove(key)
        } else {
            drinks.removeValue(forKey: key)
        }
    }

    var eval222: SobrietyData.Eval222 { data.eval222() }
    func drinkCount(on key: String) -> Int { drinks[key] ?? 0 }

    func reset() {
        startDate = nil
        checkins = []
        excluded = []
        drinks = [:]
        why = ""
        mode222 = false
        dailySpend = nil
        dailyHours = nil
        lastCelebrated = 0
    }

    /// If a new badge milestone has been reached since last time, record it and
    /// return it (so the UI can celebrate). Returns nil if nothing new.
    func newlyReachedMilestone() -> Milestones.Badge? {
        let highest = data.highestBadgeReached
        guard highest > lastCelebrated else { return nil }
        lastCelebrated = highest
        return Milestones.badges.first { $0.days == highest }
    }
}
