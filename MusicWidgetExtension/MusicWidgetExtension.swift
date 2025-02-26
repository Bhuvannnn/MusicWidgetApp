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
        
        let entry = MusicWidgetEntry(
            date: Date(),
            isPlaying: songTitle != nil,
            songTitle: songTitle ?? "Not Playing",
            artistName: artistName ?? "Unknown Artist",
            albumArtworkURL: albumArtworkURL
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30))) // Refresh every 30 seconds
        completion(timeline)
    }
}

struct MusicWidgetExtensionEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            if entry.songTitle == nil || entry.artistName == nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                Text("Loading...?")
                    .font(.headline)
            } else if let song = entry.songTitle, let artist = entry.artistName {
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
            }
        )
        .configurationDisplayName("Music Widget")
        .description("Displays current Spotify playback")
        .supportedFamilies([.systemSmall])
    }
}