import Foundation
import Combine
import ServiceManagement // Required for launch at login

class SpotifyMonitor: ObservableObject {
    @Published var isMuted: Bool = false
    @Published var isActive: Bool = true
    
    // New variables for our two features
    @Published var enforcePrivateSession: Bool = false
    @Published var launchAtLogin: Bool = false
    
    private var timerTask: Task<Void, Never>?
    private var originalVolume: Int = 100
    
    init() {
        // Check if the app was already configured to launch at startup
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        startMonitoring()
    }
    
    func toggleMonitoring() {
        isActive.toggle()
        if isActive { startMonitoring() } else { stopMonitoring() }
    }
    
    // Function to enable or disable launch at login
    func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Error changing launch at login status: \(error.localizedDescription)")
        }
    }
    
    private func startMonitoring() {
        timerTask = Task {
            while !Task.isCancelled {
                if isActive {
                    await checkSpotify()
                    
                    // If the user wants a private session, check it in each cycle
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
    
    // Function that interacts with the Spotify menu to enforce a private session
    private func ensurePrivateSession() async {
        // NOTE: If the user's Spotify is in a language other than English,
        // "Private Session" must match the exact localized menu item string.
        let script = """
        tell application "System Events"
            if exists (process "Spotify") then
                tell process "Spotify"
                    -- Access the Spotify application menu (the second item in the menu bar)
                    set theMenu to menu 1 of menu bar item 2 of menu bar 1
                    set theMenuItem to menu item "Private Session" of theMenu
                    
                    if exists theMenuItem then
                        -- Check if it has a checkmark
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
