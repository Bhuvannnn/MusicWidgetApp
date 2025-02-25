import WidgetKit
import SwiftUI
import AppIntents  // Add this import

struct MusicWidgetEntry: TimelineEntry {
    let date: Date
    let isPlaying: Bool
    let songTitle: String?
    let artistName: String?
}

struct MusicWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MusicWidgetEntry {
        MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Song Title", artistName: "Artist")
    }

    func getSnapshot(in context: Context, completion: @escaping (MusicWidgetEntry) -> Void) {
        let entry = MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Song Title", artistName: "Artist")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MusicWidgetEntry>) -> Void) {
        SpotifyAPI.fetchNowPlaying { songTitle, artistName, _ in
            let entry = MusicWidgetEntry(
                date: Date(),
                isPlaying: true,
                songTitle: songTitle,
                artistName: artistName
            )
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct MusicWidgetEntryView : View {
    var entry: MusicWidgetProvider.Entry

    var body: some View {
        VStack {
            if let song = entry.songTitle, let artist = entry.artistName {
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

struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play/Pause"
    
    func perform() async throws -> some IntentResult {
        SpotifyAPI.playPause()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    
    func perform() async throws -> some IntentResult {
        SpotifyAPI.nextTrack()
        return .result()
    }
}