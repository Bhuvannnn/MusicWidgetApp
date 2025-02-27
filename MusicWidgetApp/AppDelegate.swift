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
        
        // Register for custom URL scheme events
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        
        if url.scheme == "musicwidget" {
            if url.host == "playpause" {
                SpotifyAPI.playPause()
            } else if url.host == "next" {
                SpotifyAPI.nextTrack()
            } else if url.host == "previous" {
                SpotifyAPI.previousTrack()
            } else if url.host == "nowplaying" {
                SpotifyAuth.shared.handleRedirect(url: url)
                // Update the main window content
                DispatchQueue.main.async {
                    self.window?.contentView = NSHostingView(rootView: ContentView())
                }
            }
        }
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        
        print("Handling URL: \(url.absoluteString)")
        
        if url.scheme == "musicwidget" {
            switch url.host {
            case "playpause":
                SpotifyAPI.playPause()
            case "next":
                SpotifyAPI.nextTrack()
            case "previous":
                SpotifyAPI.previousTrack()
            default:
                SpotifyAuth.shared.handleRedirect(url: url)
                // Update the main window content
                DispatchQueue.main.async {
                    self.window?.contentView = NSHostingView(rootView: ContentView())
                }
            }
        }
    }
}