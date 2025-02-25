import WidgetKit
import SwiftUI
import AppIntents

struct MusicWidgetEntry: TimelineEntry {
    let date: Date
    let isPlaying: Bool
    let songTitle: String?
    let artistName: String?
    let albumArtworkURL: URL?
}

struct MusicWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MusicWidgetEntry {
        MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Song Title", artistName: "Artist", albumArtworkURL: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MusicWidgetEntry) -> Void) {
        let entry = MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Song Title", artistName: "Artist", albumArtworkURL: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MusicWidgetEntry>) -> Void) {
        SpotifyAPI.fetchNowPlaying { songTitle, artistName, albumArtworkURL, _ in
            let entry = MusicWidgetEntry(
                date: Date(),
                isPlaying: true,
                songTitle: songTitle,
                artistName: artistName,
                albumArtworkURL: albumArtworkURL
            )
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
            completion(timeline)
        }
    }
}

struct MusicWidgetEntryView : View {
    var entry: MusicWidgetProvider.Entry

    var body: some View {
        VStack {
            if let song = entry.songTitle, let artist = entry.artistName {
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

struct MusicWidget: Widget {
    let kind: String = "MusicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MusicWidgetProvider()) { entry in
            MusicWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Music Widget")
        .description("Displays current Spotify playback")
        .supportedFamilies([.systemSmall])
    }
}