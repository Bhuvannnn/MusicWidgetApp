import WidgetKit
import SwiftUI

// Add the MusicWidgetEntry struct
struct MusicWidgetEntry: TimelineEntry {
    let date: Date
    let isPlaying: Bool
    let songTitle: String?
    let artistName: String?
    let albumArtworkURL: URL?
}

// Update the Provider to conform to TimelineProvider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MusicWidgetEntry {
        MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Loading...", artistName: "Loading...", albumArtworkURL: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MusicWidgetEntry) -> Void) {
        let entry = MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Loading...", artistName: "Loading...", albumArtworkURL: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MusicWidgetEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.yourname.MusicWidgetApp")!
        let songTitle = userDefaults.string(forKey: "songTitle")
        let artistName = userDefaults.string(forKey: "artistName")
        let albumArtworkURLString = userDefaults.string(forKey: "albumArtworkURL")
        let albumArtworkURL = albumArtworkURLString != nil ? URL(string: albumArtworkURLString!) : nil
        
        debugPrint("Widget timeline - Retrieved data: Title=\(songTitle ?? "nil"), Artist=\(artistName ?? "nil")")

        let entry = MusicWidgetEntry(
            date: Date(),
            isPlaying: songTitle != nil,
            songTitle: songTitle ?? "Not Playing",
            artistName: artistName ?? "Unknown Artist",
            albumArtworkURL: albumArtworkURL
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(5))) // Refresh every 30 seconds
        completion(timeline)
    }
}

struct MusicWidgetExtensionEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        // Debug information as part of the view
        VStack {
            if entry.songTitle == nil || entry.artistName == nil {
                VStack {
                    Text("Debug Info")
                        .font(.caption)
                    Text("Title: \(entry.songTitle ?? "nil")")
                        .font(.caption2)
                    Text("Artist: \(entry.artistName ?? "nil")")
                        .font(.caption2)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading...")
                        .font(.headline)
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
                    Text(artist)
                        .font(.subheadline)
                    
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
                    .widgetURL(URL(string: "musicwidget://nowplaying")) // Add deep linking
            }
        )
        .configurationDisplayName("Music Widget")
        .description("Displays current Spotify playback")
        .supportedFamilies([.systemSmall, .systemMedium]) // Add more sizes for testing
    }
}