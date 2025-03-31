import WidgetKit
import SwiftUI
// No need for AppIntents here, but keep SwiftUI and WidgetKit

// Re-declare the keys and theme enum for use within the widget extension
// (Alternatively, move these to a shared file/framework if the project grows)
struct AppStorageKeys {
    static let widgetTheme = "widgetTheme"
    static let widgetTransparency = "widgetTransparency"
    static let showAlbumArt = "showAlbumArt"
    static let showArtistName = "showArtistName"
    static let showAlbumName = "showAlbumName"
}

enum WidgetTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
}
// Add the MusicWidgetEntry struct
struct MusicWidgetEntry: TimelineEntry {
    let date: Date
    let isPlaying: Bool
    let songTitle: String?
    let artistName: String?
    let albumName: String? // Add album name
    let albumArtworkURL: URL?
    let localArtworkURL: URL?
    let isLoading: Bool
    let debugMessage: String

    // Add settings properties to the entry
    let widgetTheme: WidgetTheme
    let widgetTransparency: Double
    let showAlbumArt: Bool
    let showArtistName: Bool
    let showAlbumName: Bool
}

// Update the Provider to conform to AppIntentTimelineProvider for interactive widgets
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MusicWidgetEntry {
        MusicWidgetEntry(
            date: Date(), 
            isPlaying: false, 
            songTitle: "Loading...", 
            artistName: "Loading...",
            albumName: "Loading...", // Add placeholder
            albumArtworkURL: nil,
            localArtworkURL: nil,
            isLoading: false,
            debugMessage: "Placeholder",
            // Default settings for placeholder
            widgetTheme: .system,
            widgetTransparency: 1.0,
            showAlbumArt: true,
            showArtistName: true,
            showAlbumName: true
        )
    }

    // Required for AppIntentTimelineProvider: Snapshot for a specific configuration
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> MusicWidgetEntry {
        // For this widget, the configuration doesn't change the snapshot, so load normally
        return loadCurrentData()
    }

    // Required for AppIntentTimelineProvider: Timeline for a specific configuration
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<MusicWidgetEntry> {
        let entry = loadCurrentData()
        
        // Refresh more frequently for better responsiveness
        let refreshDate = Date().addingTimeInterval(5) // Keep refresh interval
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        print("Widget: Creating new timeline with entry: \(String(describing: entry.songTitle))")
        return timeline
    }
    
    private func loadCurrentData() -> MusicWidgetEntry {
        var debugMsg = "Checking for song data file..."
        var localArtworkURL: URL? = nil
        var isLoading = false

        // Load widget settings from file, providing defaults
        let settings = SpotifyAPI.loadWidgetSettingsFromFile() ?? [:]
        let themeRawValue = settings[AppStorageKeys.widgetTheme] as? String
        let widgetTheme = WidgetTheme(rawValue: themeRawValue ?? WidgetTheme.system.rawValue) ?? .system
        let widgetTransparency = settings[AppStorageKeys.widgetTransparency] as? Double ?? 1.0
        let showAlbumArt = settings[AppStorageKeys.showAlbumArt] as? Bool ?? true
        let showArtistName = settings[AppStorageKeys.showArtistName] as? Bool ?? true
        let showAlbumName = settings[AppStorageKeys.showAlbumName] as? Bool ?? true
        debugMsg += " Loaded Settings: Theme=\(widgetTheme.rawValue), Trans=\(widgetTransparency), Art=\(showAlbumArt), Artist=\(showArtistName), Album=\(showAlbumName)."

        // Try to load from file
        if let songData = SpotifyAPI.loadFromFile() {
            print("Widget: Successfully loaded song data from file")
            
            let songTitle = songData["songTitle"] as? String
            let artistName = songData["artistName"] as? String
            let albumName = songData["albumName"] as? String // Load album name
            let albumArtworkURLString = songData["albumArtworkURL"] as? String
            let isPlaying = songData["isPlaying"] as? Bool ?? false
            
            // Check if we're in a loading state (track changing)
            isLoading = songData["loading"] as? Bool ?? false
            
            // Try to get the local image path
            if let localPath = songData["localImagePath"] as? String {
                localArtworkURL = URL(fileURLWithPath: localPath)
                debugMsg += " Found local image at: \(localPath)"
            } else if let urlString = albumArtworkURLString, let cachedURL = SpotifyAPI.getCachedImageURL(for: urlString) {
                localArtworkURL = cachedURL
                debugMsg += " Found cached image"
            }
            
            let albumArtworkURL = albumArtworkURLString != nil ? URL(string: albumArtworkURLString!) : nil
            
            debugMsg += " Found data file with Title: \(songTitle ?? "nil"), Artist: \(artistName ?? "nil"), Album: \(albumName ?? "nil")"
            print("Widget data load - \(debugMsg)")
            
            return MusicWidgetEntry(
                date: Date(),
                isPlaying: isPlaying,
                songTitle: songTitle,
                artistName: artistName,
                albumName: albumName, // Pass album name
                albumArtworkURL: albumArtworkURL,
                localArtworkURL: localArtworkURL,
                isLoading: isLoading,
                debugMessage: debugMsg,
                // Pass loaded settings to entry
                widgetTheme: widgetTheme,
                widgetTransparency: widgetTransparency,
                showAlbumArt: showAlbumArt,
                showArtistName: showArtistName,
                showAlbumName: showAlbumName
            )
        } else {
            // No data file found
            debugMsg += " No data file found."
            print("Widget data load - \(debugMsg)")
            
            return MusicWidgetEntry(
                date: Date(),
                isPlaying: false,
                songTitle: nil,
                artistName: nil,
                albumName: nil, // Set album name to nil
                albumArtworkURL: nil,
                localArtworkURL: nil,
                isLoading: false,
                debugMessage: debugMsg,
                // Pass loaded settings (or defaults) to entry
                widgetTheme: widgetTheme,
                widgetTransparency: widgetTransparency,
                showAlbumArt: showAlbumArt,
                showArtistName: showArtistName,
                showAlbumName: showAlbumName
            )
        }
    }
}

struct MusicWidgetExtensionEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.colorScheme) private var colorScheme // To detect system dark/light mode

    // Settings are now passed via the 'entry' object, remove @AppStorage properties

    var body: some View {
        // Determine effective color scheme based on theme setting
        // Use settings from the entry object
        let effectiveColorScheme: ColorScheme = {
            switch entry.widgetTheme {
            case .light: return .light
            case .dark: return .dark
            case .system: return colorScheme // Use environment's color scheme
            }
        }()

        VStack(alignment: .center, spacing: widgetFamily == .systemMedium ? 8 : 4) { // Adjust spacing
            if entry.songTitle == nil { // Simplified check
                Spacer() // Push content to center
                VStack {
                    Text("No Current Song")
                        .font(.headline)
                    Text("Play music on Spotify")
                        .font(.caption)
                        .foregroundColor(.secondary)
//                    Text("Debug: \(entry.debugMessage)") // Optional: Keep for debugging
//                        .font(.system(size: 8))
//                        .foregroundColor(.gray)
//                        .padding(.top, 2)
                }
                Spacer() // Push content to center
            } else if let song = entry.songTitle { // Only need song title to show something
                // Use HStack for Medium widget layout
                let layout = widgetFamily == .systemMedium ? AnyLayout(HStackLayout(alignment: .center, spacing: 12)) : AnyLayout(VStackLayout(alignment: .center, spacing: 4))

                layout {
                    // --- Album Art (Conditional based on entry setting) ---
                    if entry.showAlbumArt {
                        Group {
                            if let localURL = entry.localArtworkURL, let nsImage = NSImage(contentsOf: localURL) {
                                Image(nsImage: nsImage)
                                    .resizable()
                            } else if let remoteURL = entry.albumArtworkURL {
                                AsyncImage(url: remoteURL) { image in
                                    image.resizable()
                                } placeholder: {
                                    albumArtPlaceholder // Use the placeholder here
                                }
                            } else {
                                albumArtPlaceholder // Use placeholder if no URL
                            }
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: albumArtSize, height: albumArtSize)
                        .cornerRadius(widgetFamily == .systemMedium ? 6 : 4) // Slightly smaller corner radius
                        .overlay(
                            entry.isLoading ?
                            RoundedRectangle(cornerRadius: widgetFamily == .systemMedium ? 6 : 4)
                                .fill(.black.opacity(0.4))
                                .overlay(ProgressView().tint(.white)) // Show progress indicator when loading
                            : nil
                        )
                        .shadow(radius: 3, y: 1) // Add subtle shadow
                    }

                    // --- Text Info (Conditional) ---
                    VStack(alignment: widgetFamily == .systemMedium ? .leading : .center) {
                        if entry.isLoading {
                            Text("Changing track...")
                                .font(widgetFamily == .systemMedium ? .title3 : .headline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        } else {
                            Text(song)
                                .font(widgetFamily == .systemMedium ? .title3 : .headline)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            // Show Artist Name (Conditional based on entry setting)
                            if entry.showArtistName, let artist = entry.artistName {
                                Text(artist)
                                    .font(widgetFamily == .systemMedium ? .body : .subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            // Show Album Name (Conditional based on entry setting)
                            if entry.showAlbumName, let album = entry.albumName {
                                Text(album)
                                    .font(widgetFamily == .systemMedium ? .caption : .caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: widgetFamily == .systemMedium ? .leading : .center) // Allow text to expand in medium

                    if widgetFamily == .systemMedium {
                         Spacer() // Push controls to the right in medium widget
                    }
                    
                    // --- Playback Controls ---
                    HStack(spacing: buttonSpacing) {
                        // Previous Button
                        Button(intent: PreviousTrackIntent()) {
                            Image(systemName: "backward.fill")
                        }
                        .buttonStyle(WidgetButtonStyle(size: buttonSize))

                        // Play/Pause Button
                        Button(intent: PlayPauseIntent()) {
                            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(WidgetButtonStyle(size: buttonSize))

                        // Next Button
                        Button(intent: NextTrackIntent()) {
                            Image(systemName: "forward.fill")
                        }
                        .buttonStyle(WidgetButtonStyle(size: buttonSize))
                    }
                    .padding(.top, widgetFamily == .systemMedium ? 0 : 4) // No top padding for controls in medium
                    .opacity(entry.isLoading ? 0.5 : 1.0) // Fade controls slightly when loading
                    .disabled(entry.isLoading) // Disable buttons when loading
                } // End of main layout HStack/VStack
            } else {
                // Fallback if song title is nil but we got here somehow
                Text("Waiting for Spotify...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        // Apply background based on theme and transparency
        .containerBackground(containerBackgroundView(), for: .widget)
        // Apply the effective color scheme to the content
        .environment(\.colorScheme, effectiveColorScheme)
    }
    
    // MARK: - Helper Views and Functions
    private var albumArtSize: CGFloat {
        switch widgetFamily {
        case .systemMedium: return 60 // Adjusted size for medium
        default: return 45 // Adjusted size for small
        }
    }
    
    private var buttonSize: CGFloat {
        switch widgetFamily {
        case .systemMedium: return 20 // Adjusted size
        default: return 16 // Adjusted size
        }
    }
    
    private var buttonSpacing: CGFloat {
        switch widgetFamily {
        case .systemMedium: return 15 // Adjusted spacing
        default: return 8 // Adjusted spacing
        }
    }
    
    // Placeholder view for album art
    private var albumArtPlaceholder: some View {
        RoundedRectangle(cornerRadius: widgetFamily == .systemMedium ? 6 : 4)
            .fill(.gray.opacity(0.2)) // Use a subtle fill
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: albumArtSize * 0.5))
                    .foregroundColor(.gray.opacity(0.6))
            )
            .frame(width: albumArtSize, height: albumArtSize) // Ensure frame is applied
    }

    // Determine the background ShapeStyle based on theme settings
    // Use entry settings for background
    private func containerBackgroundView() -> Color {
        let baseColor: Color = {
            switch entry.widgetTheme { // Use entry.widgetTheme
            case .light: return .white
            case .dark: return .black
            case .system:
                // Use system background colors which adapt automatically
                // Using specific colors for better control than windowBackgroundColor
                 return colorScheme == .dark ? Color(nsColor: .underPageBackgroundColor) : Color(nsColor: .textBackgroundColor) // Example system colors
            }
        }()

        // Apply transparency from entry and return the Color
        return baseColor.opacity(entry.widgetTransparency) // Use entry.widgetTransparency
    }
}

// Custom Button Style for consistent look
struct WidgetButtonStyle: ButtonStyle {
    let size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.9)) // Icon size relative to button size
            .frame(width: size * 1.5, height: size * 1.5) // Make tappable area larger
            .background(configuration.isPressed ? Color.gray.opacity(0.4) : Color.secondary.opacity(0.15))
            .clipShape(Circle())
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}


struct MusicWidgetExtension: Widget {
    let kind: String = "MusicWidgetExtension"

    var body: some WidgetConfiguration {
        // Use AppIntentConfiguration for interactive widgets
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self, // Use the basic intent for now
            provider: Provider()
        ) { entry in
            MusicWidgetExtensionEntryView(entry: entry)
                // Removed widgetURL as interaction is handled by intents now
        }
        .configurationDisplayName("Music Widget")
        .description("Displays current Spotify playback")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}