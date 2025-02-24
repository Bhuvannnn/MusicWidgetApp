import SwiftUI
import AppKit
import WidgetKit

extension NSNotification.Name {
    static let spotifyAuthChanged = NSNotification.Name("spotifyAuthChanged")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the main app window after launch
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Restore activation policy when quitting
        NSApp.setActivationPolicy(.regular)
    }
}