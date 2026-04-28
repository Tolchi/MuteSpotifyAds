import SwiftUI

@main
struct MuteSpotifyAdsApp: App {
    @StateObject private var spotifyMonitor = SpotifyMonitor()

    var body: some Scene {
        MenuBarExtra(
            "MuteSpotifyAds",
            systemImage: spotifyMonitor.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        ) {
            Button(spotifyMonitor.isActive ? "Pausar Monitoreo" : "Reanudar Monitoreo") {
                spotifyMonitor.toggleMonitoring()
            }
            
            Divider()
            
            // Interruptor para la sesión privada infinita
            Toggle("Sesión Privada Infinita", isOn: $spotifyMonitor.enforcePrivateSession)
            
            // Interruptor para el inicio automático con el Mac
            Toggle("Iniciar al encender el Mac", isOn: $spotifyMonitor.launchAtLogin)
                .onChange(of: spotifyMonitor.launchAtLogin) { newValue in
                    spotifyMonitor.toggleLaunchAtLogin(enabled: newValue)
                }
            
            Divider()
            
            Button("Salir") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
