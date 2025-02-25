import SwiftUI
import AppKit
import WidgetKit

extension NSNotification.Name {
    static let spotifyAuthChanged = NSNotification.Name("spotifyAuthChanged")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Initialize the main window
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered, defer: false)
        window?.center()
        window?.setFrameAutosaveName("Main Window")
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        
        if url.scheme == "musicwidget" {
            SpotifyAuth.shared.handleRedirect(url: url)
            // Update the main window content
            DispatchQueue.main.async {
                self.window?.contentView = NSHostingView(rootView: ContentView())
            }
        }
    }
}