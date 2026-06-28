import SwiftUI

@main
struct SoberApp: App {
    @StateObject private var store = SobrietyStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { phase in
            // Re-sync if a widget logged a check-in while we were away.
            if phase == .active { store.reload() }
        }
    }
}
