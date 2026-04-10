import SwiftUI
import SwiftData

@main
struct GenghsiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No WindowGroup — this is a menubar-only app
        Settings {
            EmptyView()
        }
        .modelContainer(DataStore.shared.container)
    }
}
