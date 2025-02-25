//
//  MusicWidgetExtension.swift
//  MusicWidgetExtension
//
//  Created by Bhuvan Shah on 2/23/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MusicWidgetEntry {
        MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Song Title", artistName: "Artist", albumArtworkURL: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MusicWidgetEntry) -> Void) {
        let entry = MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Song Title", artistName: "Artist", albumArtworkURL: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MusicWidgetEntry>) -> Void) {
        print("Fetching now playing data...")
        SpotifyAPI.fetchNowPlaying { songTitle, artistName, albumArtworkURL, error in
            if let error = error {
                print("Error fetching now playing data: \(error)")
                let entry = MusicWidgetEntry(date: Date(), isPlaying: false, songTitle: "Error", artistName: "Error", albumArtworkURL: nil)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30)))
                completion(timeline)
                return
            }
            
            print("Fetched data: songTitle=\(songTitle ?? "nil"), artistName=\(artistName ?? "nil")")
            let entry = MusicWidgetEntry(
                date: Date(),
                isPlaying: true,
                songTitle: songTitle,
                artistName: artistName,
                albumArtworkURL: albumArtworkURL
            )
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30))) // Refresh every 30 seconds
            completion(timeline)
        }
    }
}

struct MusicWidgetExtensionEntryView : View {
    var entry: Provider.Entry

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

struct MusicWidgetExtension: Widget {
    let kind: String = "MusicWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MusicWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Music Widget")
        .description("Displays current Spotify playback")
        .supportedFamilies([.systemSmall])
    }
}