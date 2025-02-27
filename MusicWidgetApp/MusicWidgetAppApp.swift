import SwiftUI

@main
struct MusicWidgetAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .help) {}
        }
    }
}