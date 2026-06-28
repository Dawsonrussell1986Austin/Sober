import AppIntents
import WidgetKit

/// Logs today's sober check-in. Used by the interactive widget button (iOS 17+)
/// and available as a Shortcut/Siri action. Shared by the app and widget targets.
@available(iOS 16.0, *)
struct CheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Check in sober today"
    static var description = IntentDescription("Log that you stayed sober today.")

    func perform() async throws -> some IntentResult {
        SobrietyData.checkInTodayInSharedStore()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
