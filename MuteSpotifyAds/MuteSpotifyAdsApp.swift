import SwiftUI

@main
struct MuteSpotifyAdsApp: App {
    @StateObject private var spotifyMonitor = SpotifyMonitor()
    
    private var notificationManager: SpotifyNotificationManager
        
    init() {
       // Initialize the native macOS Spotify notification subsystem
       self.notificationManager = SpotifyNotificationManager()
    }

    var body: some Scene {
        MenuBarExtra(
            "MuteSpotifyAds",
            systemImage: spotifyMonitor.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        ) {
            Button(spotifyMonitor.isActive ? String(localized: "Pause Monitoring") : String(localized: "Resume Monitoring")) {
                spotifyMonitor.toggleMonitoring()
            }
            
            Divider()
            
            // Toggle for the infinite private session
            Toggle("Enforce Private Session", isOn: $spotifyMonitor.enforcePrivateSession)
            
            // Toggle for launching the app at startup
            Toggle("Launch at Login", isOn: $spotifyMonitor.launchAtLogin)
                .onChange(of: spotifyMonitor.launchAtLogin) { oldValue, newValue in
                    spotifyMonitor.toggleLaunchAtLogin(enabled: newValue)
                }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
