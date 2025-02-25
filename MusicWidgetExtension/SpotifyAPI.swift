import Foundation
import SwiftUI
import AppKit

public struct SpotifyAPI {
    private static let userDefaults = UserDefaults(suiteName: "group.com.yourname.MusicWidgetApp")!
    private static let accessTokenKey = "spotifyAccessToken"
    
    public static func fetchNowPlaying(completion: @escaping (String?, String?, Error?) -> Void) {
        guard let token = userDefaults.string(forKey: accessTokenKey) else {
            completion(nil, nil, nil)
            return
        }

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil, error)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let item = json?["item"] as? [String: Any]
                let songTitle = item?["name"] as? String
                let artists = item?["artists"] as? [[String: Any]]
                let artistName = artists?.first?["name"] as? String
                completion(songTitle, artistName, nil)
            } catch {
                completion(nil, nil, error)
            }
        }.resume()
    }
    
    public static func playPause() {
        guard let token = userDefaults.string(forKey: accessTokenKey) else { return }
        
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/play")!)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    public static func nextTrack() {
        guard let token = userDefaults.string(forKey: accessTokenKey) else { return }
        
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/next")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request).resume()
    }
}