import Foundation

struct SpotifyConfig {
    static let clientID = "YOUR_SPOTIFY_CLIENT_ID"
    static let clientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
    static let redirectURI = "musicwidget://callback"
    static let scope = "user-read-playback-state user-read-currently-playing user-modify-playback-state"
} 