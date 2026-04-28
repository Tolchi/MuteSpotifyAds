import Foundation
import Combine
import ServiceManagement // Necesario para el inicio automático

class SpotifyMonitor: ObservableObject {
    @Published var isMuted: Bool = false
    @Published var isActive: Bool = true
    
    // Nuevas variables para nuestras dos funciones
    @Published var enforcePrivateSession: Bool = false
    @Published var launchAtLogin: Bool = false
    
    private var timerTask: Task<Void, Never>?
    private var originalVolume: Int = 100
    
    init() {
        // Comprobamos si la app ya estaba configurada para iniciar con el Mac
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        startMonitoring()
    }
    
    func toggleMonitoring() {
        isActive.toggle()
        if isActive { startMonitoring() } else { stopMonitoring() }
    }
    
    // Función para activar o desactivar el inicio automático
    func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Error al cambiar el inicio automático: \(error.localizedDescription)")
        }
    }
    
    private func startMonitoring() {
        timerTask = Task {
            while !Task.isCancelled {
                if isActive {
                    await checkSpotify()
                    
                    // Si el usuario quiere sesión privada, lo verificamos en cada ciclo
                    if enforcePrivateSession {
                        await ensurePrivateSession()
                    }
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func stopMonitoring() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    private func checkSpotify() async {
        let urlScript = "tell application \"Spotify\" to get spotify url of current track"
        let trackURL = executeAppleScript(urlScript)
        
        if trackURL?.hasPrefix("spotify:ad") == true {
            if !isMuted {
                let volScript = "tell application \"Spotify\" to get sound volume"
                if let volStr = executeAppleScript(volScript), let vol = Int(volStr) {
                    originalVolume = vol > 0 ? vol : 100
                }
                _ = executeAppleScript("tell application \"Spotify\" to set sound volume to 0")
                DispatchQueue.main.async { self.isMuted = true }
            }
        } else {
            if isMuted {
                _ = executeAppleScript("tell application \"Spotify\" to set sound volume to \(originalVolume)")
                DispatchQueue.main.async { self.isMuted = false }
            }
        }
    }
    
    // Función que interactúa con el menú de Spotify para forzar la sesión privada
    private func ensurePrivateSession() async {
        // NOTA: Si tu Spotify está en español, cambia "Private Session" por "Sesión privada"
        let script = """
        tell application "System Events"
            if exists (process "Spotify") then
                tell process "Spotify"
                    -- Accede al menú de la aplicación Spotify (el segundo elemento de la barra de menú)
                    set theMenu to menu 1 of menu bar item 2 of menu bar 1
                    set theMenuItem to menu item "Private Session" of theMenu
                    
                    if exists theMenuItem then
                        -- Comprobamos si tiene una marca de verificación (checkmark)
                        set isChecked to (value of attribute "AXMenuItemMarkChar" of theMenuItem) is not missing value
                        if not isChecked then
                            click theMenuItem
                        end if
                    end if
                end tell
            end if
        end tell
        """
        _ = executeAppleScript(script)
    }
    
    private func executeAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil { return output.stringValue }
        }
        return nil
    }
}
