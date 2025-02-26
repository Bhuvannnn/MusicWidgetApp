import Foundation
import SwiftUI
import AppKit
import Combine

public class SpotifyAuth: ObservableObject {
    public static let shared = SpotifyAuth()
    private var cancellables = Set<AnyCancellable>()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.yourname.MusicWidgetApp")!
    private let accessTokenKey = "spotifyAccessToken"
    
    @Published public var accessToken: String? {
        didSet {
            print("Access token updated: \(accessToken ?? "nil")")
            if let token = accessToken {
                userDefaults.set(token, forKey: accessTokenKey)
            } else {
                userDefaults.removeObject(forKey: accessTokenKey)
            }
        }
    }
    @Published public var isAuthenticated: Bool = false
    
    public static let clientID = "***REMOVED***"
    public static let clientSecret = "76b3e446df04464c9762dfceed93cbe8"
    public static let redirectURI = "musicwidget://callback"
    public static let scope = "user-read-playback-state user-read-currently-playing"

    private struct TokenResponse: Codable {
        let access_token: String
        let token_type: String
        let expires_in: Int
        let refresh_token: String?
        let scope: String
    }

    private init() {
        // Load token from UserDefaults on initialization
        self.accessToken = userDefaults.string(forKey: accessTokenKey)
        self.isAuthenticated = accessToken != nil
    }
    
    public func authorizeSpotify() {
        let authURLString = "https://accounts.spotify.com/authorize?client_id=\(Self.clientID)&response_type=code&redirect_uri=\(Self.redirectURI)&scope=\(Self.scope)&show_dialog=true"
        
        if let encodedAuthURLString = authURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let authURL = URL(string: encodedAuthURLString) {
            NSWorkspace.shared.open(authURL)
        }
    }
    
public func handleRedirect(url: URL) {
    guard let code = url.queryParameters?["code"] else {
        print("No code found in URL")
        return
    }
    
    print("Received authorization code")
    
    let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
    var request = URLRequest(url: tokenURL)
    request.httpMethod = "POST"
    
    let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(Self.redirectURI)"
    let authData = "\(Self.clientID):\(Self.clientSecret)".data(using: .utf8)!.base64EncodedString()
    
    request.httpBody = body.data(using: .utf8)
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.addValue("Basic \(authData)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Token request error: \(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            print("No data received")
            return
        }
        
        do {
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            print("Successfully received access token")
            
            DispatchQueue.main.async {
                self.accessToken = tokenResponse.access_token
                self.isAuthenticated = true
                NotificationCenter.default.post(name: .spotifyAuthChanged, object: nil)
            }
        } catch {
            print("Token decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }
    }.resume()
}
}

extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return nil }
        
        var parameters = [String: String]()
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
}