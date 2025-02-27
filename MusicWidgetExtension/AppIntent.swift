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
    
    func perform() async throws -> some IntentResult {
        SpotifyAPI.playPause()
        
        // Refresh widget after a delay to show updated state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    static var description: LocalizedStringResource = "Skip to the next track"
    
    func perform() async throws -> some IntentResult {
        SpotifyAPI.nextTrack()
        
        // Refresh widget after a delay to show updated track
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var description: LocalizedStringResource = "Go back to the previous track"
    
    func perform() async throws -> some IntentResult {
        SpotifyAPI.previousTrack()
        
        // Refresh widget after a delay to show updated track
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        return .result()
    }
}