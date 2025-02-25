import SwiftUI

struct ContentView: View {
    @StateObject private var auth = SpotifyAuth.shared
    @State private var songTitle: String?
    @State private var artistName: String?

    var body: some View {
        VStack {
            if auth.isAuthenticated {
                if let song = songTitle, let artist = artistName {
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
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotifyAuthChanged)) { _ in
            print("Auth status changed. Authenticated: \(auth.isAuthenticated)")
            if auth.isAuthenticated {
                fetchNowPlaying()
            }
        }
    }

    private func fetchNowPlaying() {
        SpotifyAPI.fetchNowPlaying { songTitle, artistName, _ in
            self.songTitle = songTitle
            self.artistName = artistName
        }
    }
}

#Preview {
    ContentView()
}