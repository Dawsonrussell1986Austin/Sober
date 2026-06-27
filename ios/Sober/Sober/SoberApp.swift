import SwiftUI

@main
struct SoberApp: App {
    @StateObject private var store = SobrietyStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
