import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var auth = SpotifyAuth.shared
    @State private var songTitle: String?
    @State private var artistName: String?
    @State private var albumArtworkURL: URL?
    @State private var lastUpdateTime: Date = Date()
    @State private var isLoading: Bool = false
    
    // Use the same UserDefaults instance throughout (still needed for token storage)
    private let sharedUserDefaults = UserDefaults(suiteName: "group.com.yourname.MusicWidgetApp")!

    var body: some View {
        VStack {
            if auth.isAuthenticated {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Fetching song data...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if let song = songTitle, let artist = artistName {
                        if let url = albumArtworkURL {
                            AsyncImage(url: url) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 120, height: 120)
                            .cornerRadius(8)
                        }
                        Text("Now Playing")
                            .font(.headline)
                        Text(song)
                            .font(.title)
                            .multilineTextAlignment(.center)
                        Text(artist)
                            .font(.subheadline)
                        
                        Text("Last updated: \(timeAgoString(from: lastUpdateTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Refresh Now") {
                            fetchNowPlaying()
                        }
                        .padding(.top, 8)
                    } else {
                        Text("No song playing on Spotify")
                            .font(.headline)
                        Text("Open Spotify and start playing music")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Check Now") {
                            fetchNowPlaying()
                        }
                        .padding(.top, 8)
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    VStack(spacing: 12) {
                        Button("Log Out") {
                            print("Logging out...")
                            auth.accessToken = nil
                            // Clear song data file when logging out
                            deleteSongDataFile()
                        }
                        
                        Button("Force Refresh Widget") {
                            forceWidgetRefresh()
                        }
                        .font(.caption)
                        
                        // Add a debug section to show file path
                        Text("Container Path (for debugging):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(SpotifyAPI.containerURL.path)
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Text("Spotify Widget")
                        .font(.title)
                        .bold()
                    
                    Text("Login to show your currently playing music in a widget")
                        .multilineTextAlignment(.center)
                    
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
        }
        .padding()
        .frame(minWidth: 350, minHeight: 400)
        .onAppear {
            if auth.isAuthenticated {
                isLoading = true
                fetchNowPlaying()
                startTimer()
                
                // Try to load any existing data
                loadStoredSongData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotifyAuthChanged)) { _ in
            print("Auth status changed. Authenticated: \(auth.isAuthenticated)")
            if auth.isAuthenticated {
                isLoading = true
                fetchNowPlaying()
                startTimer()
            } else {
                // Clear the data when logging out
                deleteSongDataFile()
            }
        }
    }

    private func fetchNowPlaying() {
        print("Fetching now playing data in ContentView...")
        isLoading = true
        
        SpotifyAPI.fetchNowPlaying { songTitle, artistName, albumArtworkURL, error in
            isLoading = false
            
            if let error = error {
                print("Error fetching song: \(error.localizedDescription)")
                return
            }
            
            print("Fetched data in ContentView: songTitle=\(songTitle ?? "nil"), artistName=\(artistName ?? "nil")")
            
            self.songTitle = songTitle
            self.artistName = artistName
            self.albumArtworkURL = albumArtworkURL
            self.lastUpdateTime = Date()
            
            // Force widget to update immediately
            forceWidgetRefresh()
        }
    }
    
    private func loadStoredSongData() {
        if let songData = SpotifyAPI.loadFromFile() {
            print("Loaded song data from file")
            
            if let songTitle = songData["songTitle"] as? String {
                self.songTitle = songTitle
            }
            
            if let artistName = songData["artistName"] as? String {
                self.artistName = artistName
            }
            
            if let albumArtworkURLString = songData["albumArtworkURL"] as? String,
               let url = URL(string: albumArtworkURLString) {
                self.albumArtworkURL = url
            }
            
            if let timestamp = songData["timestamp"] as? TimeInterval {
                self.lastUpdateTime = Date(timeIntervalSince1970: timestamp)
            }
        }
    }
    
    private func deleteSongDataFile() {
        let songDataURL = SpotifyAPI.containerURL.appendingPathComponent("songData.json")
        
        do {
            if FileManager.default.fileExists(atPath: songDataURL.path) {
                try FileManager.default.removeItem(at: songDataURL)
                print("Song data file deleted")
            }
        } catch {
            print("Error deleting song data file: \(error)")
        }
        
        // Clear local state
        songTitle = nil
        artistName = nil
        albumArtworkURL = nil
        
        // Force widget refresh
        forceWidgetRefresh()
    }
    
    private func forceWidgetRefresh() {
        WidgetCenter.shared.reloadAllTimelines()
        print("Forced widget timeline reload")
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in // Refresh every 30 seconds
            fetchNowPlaying()
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ContentView()
}