import Foundation
import SwiftUI
import AppKit
import WidgetKit

public struct SpotifyAPI {
    private static let userDefaults = UserDefaults(suiteName: "group.com.yourname.MusicWidgetApp")!
    private static let accessTokenKey = "spotifyAccessToken"
    
    // MARK: - File-based sharing (works without Developer Program)
    
    static let containerURL: URL = {
        let containerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SharedContainer", isDirectory: true)
        
        // Ensure the directory exists
        if !FileManager.default.fileExists(atPath: containerURL.path) {
            try? FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        }
        
        // Create images directory
        let imagesURL = containerURL.appendingPathComponent("Images", isDirectory: true)
        if !FileManager.default.fileExists(atPath: imagesURL.path) {
            try? FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        }
        
        print("Container URL: \(containerURL)")
        return containerURL
    }()
    
    static var imagesDirectoryURL: URL {
        return containerURL.appendingPathComponent("Images", isDirectory: true)
    }
    
    static func saveToFile(songData: [String: Any]) {
        let songDataURL = containerURL.appendingPathComponent("songData.json")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: songData)
            try data.write(to: songDataURL)
            print("Song data saved to file: \(songDataURL)")
        } catch {
            print("Error saving song data to file: \(error)")
        }
    }
    
    static func loadFromFile() -> [String: Any]? {
        let songDataURL = containerURL.appendingPathComponent("songData.json")
        
        do {
            guard FileManager.default.fileExists(atPath: songDataURL.path) else {
                print("No song data file exists")
                return nil
            }
            
            let data = try Data(contentsOf: songDataURL)
            let songData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("Successfully loaded song data from file")
            return songData
        } catch {
            print("Error loading song data from file: \(error)")
            return nil
        }
    }
    
    // MARK: - Image Caching
    
    static func cacheImageFromURL(_ urlString: String, completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid image URL")
            completion(nil)
            return
        }
        
        // Create a unique filename based on the URL
        let filename = urlString.hash.description + ".jpg"
        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        
        // Check if file already exists (cached)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("Image already cached at: \(fileURL.path)")
            completion(fileURL)
            return
        }
        
        // Download the image
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error downloading image: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                // Save the image data to file
                try data.write(to: fileURL)
                print("Image cached successfully at: \(fileURL.path)")
                completion(fileURL)
            } catch {
                print("Error saving image: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    static func getCachedImageURL(for imageURLString: String) -> URL? {
        let filename = imageURLString.hash.description + ".jpg"
        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    static func loadCachedImage(for imageURLString: String) -> NSImage? {
        guard let fileURL = getCachedImageURL(for: imageURLString) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return NSImage(data: data)
        } catch {
            print("Error loading cached image: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Widget UI Helper
    
    static func getWidgetImage(from imageURLString: String?) -> NSImage? {
        guard let urlString = imageURLString else { return nil }
        
        // Try to load from cache first
        if let cachedImage = loadCachedImage(for: urlString) {
            return cachedImage
        }
        
        // If not in cache, return nil (widget will have to wait for app to cache it)
        return nil
    }
    
    // MARK: - Spotify API calls
    
    public static func fetchNowPlaying(completion: @escaping (String?, String?, URL?, Error?) -> Void) {
        guard let token = userDefaults.string(forKey: accessTokenKey) else {
            print("SpotifyAPI: No access token found")
            completion(nil, nil, nil, NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
            return
        }

        let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("SpotifyAPI: Fetching currently playing track...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for connection errors
            if let error = error {
                print("SpotifyAPI: Network error: \(error.localizedDescription)")
                completion(nil, nil, nil, error)
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("SpotifyAPI: Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 204 {
                    // 204 No Content means nothing is playing
                    print("SpotifyAPI: No track currently playing")
                    completion(nil, nil, nil, nil)
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    // 401 Unauthorized means the token is expired
                    print("SpotifyAPI: Token expired")
                    completion(nil, nil, nil, NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication expired"]))
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    // Any other non-200 status is an error
                    print("SpotifyAPI: Error status code: \(httpResponse.statusCode)")
                    completion(nil, nil, nil, NSError(domain: "SpotifyAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error"]))
                    return
                }
            }
            
            // Check if we have data
            guard let data = data, !data.isEmpty else {
                print("SpotifyAPI: No data received")
                completion(nil, nil, nil, NSError(domain: "SpotifyAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                // Check if we have a valid track item
                guard let item = json?["item"] as? [String: Any] else {
                    print("SpotifyAPI: No track item in response")
                    completion(nil, nil, nil, nil)
                    return
                }
                
                let songTitle = item["name"] as? String
                let artists = item["artists"] as? [[String: Any]]
                let artistName = artists?.first?["name"] as? String
                let album = item["album"] as? [String: Any]
                let images = album?["images"] as? [[String: Any]]
                let imageUrlString = images?.first?["url"] as? String
                let albumArtworkURL = imageUrlString != nil ? URL(string: imageUrlString!) : nil
                
                print("SpotifyAPI: Successfully parsed track - \(songTitle ?? "Unknown") by \(artistName ?? "Unknown")")
                
                // Cache the album artwork image if available
                if let imageURLString = imageUrlString {
                    cacheImageFromURL(imageURLString) { cachedURL in
                        let songData: [String: Any] = [
                            "songTitle": songTitle as Any,
                            "artistName": artistName as Any,
                            "albumArtworkURL": imageURLString as Any,
                            "localImagePath": cachedURL?.path as Any,
                            "timestamp": Date().timeIntervalSince1970,
                            "isPlaying": json?["is_playing"] as? Bool ?? true
                        ]
                        
                        saveToFile(songData: songData)
                        
                        DispatchQueue.main.async {
                            completion(songTitle, artistName, albumArtworkURL, nil)
                        }
                    }
                } else {
                    // No image available, save the rest of the data
                    let songData: [String: Any] = [
                        "songTitle": songTitle as Any,
                        "artistName": artistName as Any,
                        "albumArtworkURL": NSNull(),
                        "timestamp": Date().timeIntervalSince1970,
                        "isPlaying": json?["is_playing"] as? Bool ?? true
                    ]
                    
                    saveToFile(songData: songData)
                    
                    DispatchQueue.main.async {
                completion(songTitle, artistName, albumArtworkURL, nil)
                    }
                }
            } catch {
                print("SpotifyAPI: JSON parsing error: \(error)")
                completion(nil, nil, nil, error)
            }
        }.resume()
    }
    
    // MARK: - AppleScript Spotify Control
    
    private static func executeAppleScript(_ command: String) -> String? {
        let script = NSAppleScript(source: "tell application \"Spotify\" to \(command)")
        var error: NSDictionary?
        let output = script?.executeAndReturnError(&error)
        
        if let error = error {
            print("SpotifyAPI: AppleScript error: \(error)")
            return nil
        }
        
        return output?.stringValue
    }
    
    // MARK: - Enhanced Playback Controls (Using AppleScript)
    
    public static func playPause() {
        print("SpotifyAPI: Play/Pause button pressed (using AppleScript)")
        
        // First try the API method
        if let token = userDefaults.string(forKey: accessTokenKey) {
            // Try API first
            executePlayPauseViaAPI(token: token)
            
            // But also use AppleScript as backup immediately after
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                executePlayPauseViaAppleScript()
            }
        } else {
            // No token, use AppleScript directly
            executePlayPauseViaAppleScript()
        }
    }
    
    private static func executePlayPauseViaAppleScript() {
        // Check if Spotify is running first
        let isSpotifyRunning = NSWorkspace.shared.runningApplications.contains { app in
            return app.bundleIdentifier == "com.spotify.client"
        }
        
        if !isSpotifyRunning {
            print("SpotifyAPI: Spotify desktop app is not running")
            return
        }
        
        // Get current state to update our local cache
        if let playerState = executeAppleScript("player state") {
            let isPlaying = playerState == "playing"
            print("SpotifyAPI: Current Spotify state via AppleScript: \(playerState)")
            
            // Update our cache with the toggled state
            if var songData = loadFromFile() as? [String: Any] {
                songData["isPlaying"] = !isPlaying
                saveToFile(songData: songData)
                print("SpotifyAPI: Updated local isPlaying state to: \(!isPlaying)")
            }
        }
        
        // Execute the play/pause command
        _ = executeAppleScript("playpause")
        print("SpotifyAPI: Executed playpause via AppleScript")
        
        // Force widget refresh
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        // Fetch the latest track info after the action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            fetchNowPlaying { _, _, _, _ in
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    private static func executePlayPauseViaAPI(token: String) {
        // Original API implementation
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player")!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for connection errors
            if let error = error {
                print("SpotifyAPI: Network error: \(error.localizedDescription)")
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("SpotifyAPI: Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 204 {
                    // 204 No Content means nothing is playing
                    print("SpotifyAPI: No track currently playing")
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    // 401 Unauthorized means the token is expired
                    print("SpotifyAPI: Token expired")
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    // Any other non-200 status is an error
                    print("SpotifyAPI: Error status code: \(httpResponse.statusCode)")
                    return
                }
            }
            
            // Check if we have data
            guard let data = data, !data.isEmpty else {
                print("SpotifyAPI: No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let isPlaying = json["is_playing"] as? Bool {
                    
                    // If playing, send pause command; if paused, send play command
                    let endpoint = isPlaying ? "pause" : "play"
                    print("SpotifyAPI: Current state is \(isPlaying ? "playing" : "paused"), sending \(endpoint) command")
                    
                    // Create a new request for the play/pause action
                    var actionRequest = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/\(endpoint)")!)
                    actionRequest.httpMethod = "PUT"
                    actionRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    URLSession.shared.dataTask(with: actionRequest) { _, actionResponse, actionError in
                        if let actionError = actionError {
                            print("SpotifyAPI: Error sending \(endpoint) command: \(actionError.localizedDescription)")
                            return
                        }
                        
                        if let actionHttpResponse = actionResponse as? HTTPURLResponse {
                            print("SpotifyAPI: \(endpoint) command response: \(actionHttpResponse.statusCode)")
                            
                            if actionHttpResponse.statusCode == 204 {
                                // Success - update our stored state
                                if var songData = loadFromFile() as? [String: Any] {
                                    songData["isPlaying"] = !isPlaying
                                    saveToFile(songData: songData)
                                    print("SpotifyAPI: Updated isPlaying state to \(!isPlaying)")
                                }
                            } else {
                                print("SpotifyAPI: Failed to \(endpoint) with status \(actionHttpResponse.statusCode)")
                            }
                        }
                    }.resume()
                }
            } catch {
                print("SpotifyAPI: JSON parsing error: \(error)")
            }
        }.resume()
    }
    
    public static func nextTrack() {
        print("SpotifyAPI: Next track button pressed (using AppleScript)")
        
        // Try API method if token exists
        if let token = userDefaults.string(forKey: accessTokenKey) {
            // Existing API method first
            executeNextTrackViaAPI(token: token)
            
            // But also use AppleScript as backup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                executeNextTrackViaAppleScript()
            }
        } else {
            // Fallback to AppleScript
            executeNextTrackViaAppleScript()
        }
    }
    
    private static func executeNextTrackViaAppleScript() {
        // Check if Spotify is running
        let isSpotifyRunning = NSWorkspace.shared.runningApplications.contains { app in
            return app.bundleIdentifier == "com.spotify.client"
        }
        
        if !isSpotifyRunning {
            print("SpotifyAPI: Spotify desktop app is not running")
            return
        }
        
        // Update local state to indicate loading
        if var songData = loadFromFile() as? [String: Any] {
            songData["loading"] = true
            saveToFile(songData: songData)
        }
        
        // Force widget refresh to show loading state
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        // Execute the next track command
        _ = executeAppleScript("next track")
        print("SpotifyAPI: Executed next track via AppleScript")
        
        // Fetch the latest track info after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            fetchNowPlaying { _, _, _, _ in
                // Clear loading state and refresh widget
                if var songData = loadFromFile() as? [String: Any] {
                    songData["loading"] = nil
                    saveToFile(songData: songData)
                }
                
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    private static func executeNextTrackViaAPI(token: String) {
        print("SpotifyAPI: Sending next track command via API")
        
        // Create a request for the next track action
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/next")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("SpotifyAPI: Error sending next track command: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("SpotifyAPI: Next track command response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 204 {
                    // Success - update our loading state
                    if var songData = loadFromFile() as? [String: Any] {
                        songData["loading"] = true
                        saveToFile(songData: songData)
                        print("SpotifyAPI: Set loading state for next track")
                        
                        // Force widget refresh with loading state
                        DispatchQueue.main.async {
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                        
                        // Wait a moment then fetch the updated track info
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            fetchNowPlaying { _, _, _, _ in
                                // Clear loading state
                                if var updatedSongData = loadFromFile() as? [String: Any] {
                                    updatedSongData["loading"] = false
                                    saveToFile(songData: updatedSongData)
                                }
                                
                                // Refresh widget again with new track
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
                } else {
                    print("SpotifyAPI: Failed to send next track command with status \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    public static func previousTrack() {
        print("SpotifyAPI: Previous track button pressed (using AppleScript)")
        
        // Try API method if token exists
        if let token = userDefaults.string(forKey: accessTokenKey) {
            // Existing API method first
            executePreviousTrackViaAPI(token: token)
            
            // But also use AppleScript as backup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                executePreviousTrackViaAppleScript()
            }
        } else {
            // Fallback to AppleScript
            executePreviousTrackViaAppleScript()
        }
    }
    
    private static func executePreviousTrackViaAppleScript() {
        // Check if Spotify is running
        let isSpotifyRunning = NSWorkspace.shared.runningApplications.contains { app in
            return app.bundleIdentifier == "com.spotify.client"
        }
        
        if !isSpotifyRunning {
            print("SpotifyAPI: Spotify desktop app is not running")
            return
        }
        
        // Update local state to indicate loading
        if var songData = loadFromFile() as? [String: Any] {
            songData["loading"] = true
            saveToFile(songData: songData)
        }
        
        // Force widget refresh to show loading state
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        // Execute the previous track command
        _ = executeAppleScript("previous track")
        print("SpotifyAPI: Executed previous track via AppleScript")
        
        // Fetch the latest track info after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            fetchNowPlaying { _, _, _, _ in
                // Clear loading state and refresh widget
                if var songData = loadFromFile() as? [String: Any] {
                    songData["loading"] = nil
                    saveToFile(songData: songData)
                }
                
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    private static func executePreviousTrackViaAPI(token: String) {
        print("SpotifyAPI: Sending previous track command via API")
        
        // Create a request for the previous track action
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/previous")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("SpotifyAPI: Error sending previous track command: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("SpotifyAPI: Previous track command response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 204 {
                    // Success - update our loading state
                    if var songData = loadFromFile() as? [String: Any] {
                        songData["loading"] = true
                        saveToFile(songData: songData)
                        print("SpotifyAPI: Set loading state for previous track")
                        
                        // Force widget refresh with loading state
                        DispatchQueue.main.async {
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                        
                        // Wait a moment then fetch the updated track info
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            fetchNowPlaying { _, _, _, _ in
                                // Clear loading state
                                if var updatedSongData = loadFromFile() as? [String: Any] {
                                    updatedSongData["loading"] = false
                                    saveToFile(songData: updatedSongData)
                                }
                                
                                // Refresh widget again with new track
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
                } else {
                    print("SpotifyAPI: Failed to send previous track command with status \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}