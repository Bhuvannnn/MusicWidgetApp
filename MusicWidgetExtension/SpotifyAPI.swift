import Foundation
import SwiftUI
import AppKit

public struct SpotifyAPI {
    private static let userDefaults = UserDefaults(suiteName: "group.com.yourname.MusicWidgetApp")!
    private static let accessTokenKey = "spotifyAccessToken"
    
    public static func fetchNowPlaying(completion: @escaping (String?, String?, Image?) -> Void) {
        guard let token = userDefaults.string(forKey: accessTokenKey) else {
            completion(nil, nil, nil)
            return
        }

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let item = json["item"] as? [String: Any],
                  let songTitle = item["name"] as? String,
                  let artistArray = item["artists"] as? [[String: Any]],
                  let artistName = artistArray.first?["name"] as? String,
                  let album = item["album"] as? [String: Any],
                  let images = album["images"] as? [[String: Any]],
                  let artworkURL = images.first?["url"] as? String,
                  let url = URL(string: artworkURL) else {
                completion(nil, nil, nil)
                return
            }
            
            URLSession.shared.dataTask(with: url) { imgData, _, _ in
                var image: Image? = nil
                if let imgData = imgData, let nsImage = NSImage(data: imgData) {
                    image = Image(nsImage: nsImage)
                }
                completion(songTitle, artistName, image)
            }.resume()
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