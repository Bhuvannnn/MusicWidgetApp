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