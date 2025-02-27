//
//  AppIntent.swift
//  MusicWidgetExtension
//
//  Created by Bhuvan Shah on 2/23/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play/Pause"
    static var description: LocalizedStringResource = "Toggle play/pause for the current track"
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Play/Pause", subtitle: "Toggle playback")
    }
    
    func perform() async throws -> some IntentResult {
        print("Widget intent: PlayPauseIntent triggered")
        
        // Call the Spotify API method directly
        SpotifyAPI.playPause()
        
        // No need for delay - the API method now handles widget refresh
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    static var description: LocalizedStringResource = "Skip to the next track"
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Next Track", subtitle: "Skip to next track")
    }
    
    func perform() async throws -> some IntentResult {
        print("Widget intent: NextTrackIntent triggered")
        
        // Call the Spotify API method directly
        SpotifyAPI.nextTrack()
        
        // No need for delay - the API method now handles widget refresh
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var description: LocalizedStringResource = "Go back to the previous track"
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Previous Track", subtitle: "Go back to previous track")
    }
    
    func perform() async throws -> some IntentResult {
        print("Widget intent: PreviousTrackIntent triggered")
        
        // Call the Spotify API method directly
        SpotifyAPI.previousTrack()
        
        // No need for delay - the API method now handles widget refresh
        return .result()
    }
}