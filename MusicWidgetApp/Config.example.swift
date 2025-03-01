import Foundation

// RENAME THIS STRUCT TO SpotifyConfig AFTER COPYING THIS FILE
// This is just an example file - copy it to Config.swift and fill in your credentials
struct ExampleSpotifyConfig {
    static let clientID = "YOUR_SPOTIFY_CLIENT_ID"
    static let clientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
    static let redirectURI = "musicwidget://callback"
    static let scope = "user-read-playback-state user-read-currently-playing user-modify-playback-state"
} 