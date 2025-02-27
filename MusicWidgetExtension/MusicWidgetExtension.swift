import WidgetKit
import SwiftUI

// Add the MusicWidgetEntry struct
struct MusicWidgetEntry: TimelineEntry {
    let date: Date
    let isPlaying: Bool
    let songTitle: String?
    let artistName: String?
    let albumArtworkURL: URL?
    let debugMessage: String
}

// Update the Provider to conform to TimelineProvider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MusicWidgetEntry {
        MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Loading...", artistName: "Loading...", albumArtworkURL: nil, debugMessage: "Placeholder")
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
        
        // Try to load from file
        if let songData = SpotifyAPI.loadFromFile() {
            print("Widget: Successfully loaded song data from file")
            
            let songTitle = songData["songTitle"] as? String
            let artistName = songData["artistName"] as? String
            let albumArtworkURLString = songData["albumArtworkURL"] as? String
            let albumArtworkURL = albumArtworkURLString != nil ? URL(string: albumArtworkURLString!) : nil
            
            debugMsg += " Found data file with Title: \(songTitle ?? "nil"), Artist: \(artistName ?? "nil")"
            print("Widget data load - \(debugMsg)")
            
            return MusicWidgetEntry(
                date: Date(),
                isPlaying: songTitle != nil && !songTitle!.isEmpty,
                songTitle: songTitle,
                artistName: artistName,
                albumArtworkURL: albumArtworkURL,
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
                debugMessage: debugMsg
            )
        }
    }
}

struct MusicWidgetExtensionEntryView: View {
    var entry: Provider.Entry
    
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
                    if let url = entry.albumArtworkURL {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                    }
                    Text(song)
                        .font(.headline)
                        .lineLimit(1)
                    Text(artist)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    HStack {
                        Button(intent: PlayPauseIntent()) {
                            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: NextTrackIntent()) {
                            Image(systemName: "forward.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("Not Playing")
                    .font(.headline)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
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
    }
}