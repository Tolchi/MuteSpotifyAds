import Cocoa
import UserNotifications

class SpotifyNotificationManager {
    
    private var lastNotifiedSong: String = ""

    init() {
        requestNotificationPermission()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(playbackStateChanged(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
    }

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }

    @objc private func playbackStateChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let trackName = userInfo["Name"] as? String ?? ""
        let artistName = userInfo["Artist"] as? String ?? ""
        let playerState = userInfo["Player State"] as? String ?? ""
        let trackId = userInfo["Track ID"] as? String ?? ""
        
        if trackName.isEmpty || artistName.isEmpty || trackName == "Spotify" || trackId.contains("ad") {
            return
        }
        
        guard playerState == "Playing" else { return }
        
        let currentSongSignature = "\(trackName) - \(artistName)"
        
        if currentSongSignature != self.lastNotifiedSong {
            self.lastNotifiedSong = currentSongSignature
            
            // FIX: Dispatch the notification payload building onto a global background utility queue.
            // This prevents XPC connection collision bugs like com.apple.linkd.autoShortcut (Error 4097)
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.sendMacNotification(title: trackName, artist: artistName)
            }
        }
    }

    private func sendMacNotification(title: String, artist: String) {
        let content = UNMutableNotificationContent()
        content.title = "Now Playing"
        content.subtitle = title
        content.body = "by \(artist)"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "SpotifyTrackChange", content: content, trigger: nil)
        
        // UNUserNotificationCenter is thread-safe and can be safely called from background queues
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver track notification: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
