import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var auth = SpotifyAuth.shared
    @State private var songTitle: String?
    @State private var artistName: String?
    @State private var albumArtworkURL: URL?

    var body: some View {
        VStack {
            if auth.isAuthenticated {
                if let song = songTitle, let artist = artistName {
                    if let url = albumArtworkURL {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                    }
                    Text("Now Playing")
                        .font(.headline)
                    Text(song)
                        .font(.title)
                    Text(artist)
                        .font(.subheadline)
                } else {
                    Text("Fetching song information...")
                        .font(.headline)
                }
                Button("Log Out") {
                    print("Logging out...")
                    auth.accessToken = nil
                }
            } else {
                Button("Login with Spotify") {
                    print("Starting Spotify authorization...")
                    auth.authorizeSpotify()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
        .onAppear {
            if auth.isAuthenticated {
                fetchNowPlaying()
                startTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotifyAuthChanged)) { _ in
            print("Auth status changed. Authenticated: \(auth.isAuthenticated)")
            if auth.isAuthenticated {
                fetchNowPlaying()
                startTimer()
                WidgetCenter.shared.reloadAllTimelines()
                print("Forced widget refresh after auth change")
            }
        }
    }

    private func fetchNowPlaying() {
        print("Fetching now playing data in ContentView...")
        SpotifyAPI.fetchNowPlaying { songTitle, artistName, albumArtworkURL, _ in
            print("Fetched data in ContentView: songTitle=\(songTitle ?? "nil"), artistName=\(artistName ?? "nil")")
            self.songTitle = songTitle
            self.artistName = artistName
            self.albumArtworkURL = albumArtworkURL
            WidgetCenter.shared.reloadAllTimelines()
            print("Reloaded widget timelines")
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in // Refresh every 30 seconds
            fetchNowPlaying()
        }
    }
}

#Preview {
    ContentView()
}