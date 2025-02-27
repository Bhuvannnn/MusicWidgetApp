import WidgetKit
import SwiftUI
import AppIntents

// Add the MusicWidgetEntry struct
struct MusicWidgetEntry: TimelineEntry {
    let date: Date
    let isPlaying: Bool
    let songTitle: String?
    let artistName: String?
    let albumArtworkURL: URL?
    let localArtworkURL: URL?
    let isLoading: Bool
    let debugMessage: String
}

// Update the Provider to conform to TimelineProvider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MusicWidgetEntry {
        MusicWidgetEntry(
            date: Date(), 
            isPlaying: false, 
            songTitle: "Loading...", 
            artistName: "Loading...", 
            albumArtworkURL: nil,
            localArtworkURL: nil, 
            isLoading: false,
            debugMessage: "Placeholder"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MusicWidgetEntry) -> Void) {
        let entry = loadCurrentData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MusicWidgetEntry>) -> Void) {
        let entry = loadCurrentData()
        
        // Refresh more frequently for better responsiveness
        let refreshDate = Date().addingTimeInterval(5)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        print("Widget: Creating new timeline with entry: \(String(describing: entry.songTitle))")
        completion(timeline)
    }
    
    private func loadCurrentData() -> MusicWidgetEntry {
        var debugMsg = "Checking for song data file..."
        var localArtworkURL: URL? = nil
        var isLoading = false
        
        // Try to load from file
        if let songData = SpotifyAPI.loadFromFile() {
            print("Widget: Successfully loaded song data from file")
            
            let songTitle = songData["songTitle"] as? String
            let artistName = songData["artistName"] as? String
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
            
            debugMsg += " Found data file with Title: \(songTitle ?? "nil"), Artist: \(artistName ?? "nil")"
            print("Widget data load - \(debugMsg)")
            
            return MusicWidgetEntry(
                date: Date(),
                isPlaying: isPlaying,
                songTitle: songTitle,
                artistName: artistName,
                albumArtworkURL: albumArtworkURL,
                localArtworkURL: localArtworkURL,
                isLoading: isLoading,
                debugMessage: debugMsg
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
                albumArtworkURL: nil,
                localArtworkURL: nil,
                isLoading: false,
                debugMessage: debugMsg
            )
        }
    }
}

struct MusicWidgetExtensionEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily
    
    var body: some View {
        VStack {
            if entry.songTitle == nil || entry.artistName == nil {
                VStack {
                    Text("No Current Song")
                        .font(.headline)
                    Text("Open the Spotify app and play music")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Debug: \(entry.debugMessage)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
            } else if let song = entry.songTitle, let artist = entry.artistName {
                VStack {
                    if let localURL = entry.localArtworkURL {
                        // Use local image file
                        if let uiImage = NSImage(contentsOf: localURL) {
                            Image(nsImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: albumArtSize, height: albumArtSize)
                                .cornerRadius(8)
                                .overlay(
                                    entry.isLoading ? 
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.3)) : nil
                                )
                        } else {
                            albumArtPlaceholder
                        }
                    } else if let url = entry.albumArtworkURL {
                        // Fall back to remote URL if needed
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            albumArtPlaceholder
                        }
                        .frame(width: albumArtSize, height: albumArtSize)
                        .cornerRadius(8)
                        .overlay(
                            entry.isLoading ? 
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.3)) : nil
                        )
                    } else {
                        albumArtPlaceholder
                    }
                    
                    if entry.isLoading {
                        Text("Changing track...")
                            .font(.headline)
                            .lineLimit(1)
                    } else {
                        Text(song)
                            .font(.headline)
                            .lineLimit(1)
                        Text(artist)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: buttonSpacing) {
                        Link(destination: URL(string: "musicwidget://previous")!) {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: buttonSize, height: buttonSize)
                                .padding(8)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(buttonSize/2)
                                .foregroundColor(.primary)
                        }
                        
                        Link(destination: URL(string: "musicwidget://playpause")!) {
                            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: buttonSize, height: buttonSize)
                                .padding(8)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(buttonSize/2)
                                .foregroundColor(.primary)
                        }
                        
                        Link(destination: URL(string: "musicwidget://next")!) {
                            Image(systemName: "forward.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: buttonSize, height: buttonSize)
                                .padding(8)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(buttonSize/2)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 4)
                    .opacity(entry.isLoading ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: entry.isLoading)
                }
            } else {
                Text("Not Playing")
                    .font(.headline)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // UI Constants
    private var albumArtSize: CGFloat {
        switch widgetFamily {
        case .systemMedium:
            return 80
        default:
            return 50
        }
    }
    
    private var buttonSize: CGFloat {
        switch widgetFamily {
        case .systemMedium:
            return 22
        default:
            return 18
        }
    }
    
    private var buttonSpacing: CGFloat {
        switch widgetFamily {
        case .systemMedium:
            return 20
        default:
            return 10
        }
    }
    
    private var albumArtPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
            Image(systemName: "music.note")
                .font(.system(size: albumArtSize * 0.4))
                .foregroundColor(.gray)
        }
        .frame(width: albumArtSize, height: albumArtSize)
        .overlay(
            entry.isLoading ? 
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3)) : nil
        )
    }
}

struct MusicWidgetExtension: Widget {
    let kind: String = "MusicWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider(),
            content: { entry in
                MusicWidgetExtensionEntryView(entry: entry)
                    .widgetURL(URL(string: "musicwidget://nowplaying"))
            }
        )
        .configurationDisplayName("Music Widget")
        .description("Displays current Spotify playback")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}