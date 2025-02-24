import SwiftUI
import AppKit
import WidgetKit

extension NSNotification.Name {
    static let spotifyAuthChanged = NSNotification.Name("spotifyAuthChanged")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        print("Received URL: \(url.absoluteString)")
        SpotifyAuth.shared.handleRedirect(url: url)
        NotificationCenter.default.post(name: .spotifyAuthChanged, object: nil)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Set activation policy to regular
        NSApp.setActivationPolicy(.regular)
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
           let url = URL(string: urlString) {
            print("Handling URL event: \(url.absoluteString)")
            DispatchQueue.main.async {
                SpotifyAuth.shared.handleRedirect(url: url)
                NotificationCenter.default.post(name: .spotifyAuthChanged, object: nil)
                
                // Force update the widget
                WidgetCenter.shared.reloadAllTimelines()
            }
        } else {
            print("Failed to parse URL from event")
        }
    }
}