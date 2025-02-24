import SwiftUI

struct ContentView: View {
    @StateObject private var auth = SpotifyAuth.shared
    
    var body: some View {
        VStack {
            if auth.isAuthenticated {
                Text("Authenticated!")
                    .font(.title)
                Button("Log Out") {
                    print("Logging out...")
                    auth.accessToken = nil
                }
            } else {
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
        .padding()
        .frame(minWidth: 300, minHeight: 200)
        .onReceive(NotificationCenter.default.publisher(for: .spotifyAuthChanged)) { _ in
            print("Auth status changed. Authenticated: \(auth.isAuthenticated)")
        }
    }
}

#Preview {
    ContentView()
}