import SwiftUI
import AppKit
import WidgetKit

extension NSNotification.Name {
    static let spotifyAuthChanged = NSNotification.Name("spotifyAuthChanged")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
    
    // Add this function to handle URL schemes
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        
        if url.scheme == "musicwidget" {
            SpotifyAuth.shared.handleRedirect(url: url)
        }
    }
}