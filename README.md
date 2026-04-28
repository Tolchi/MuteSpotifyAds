# MuteSpotifyAds for macOS (Apple Silicon) 🎧🚫

A lightweight macOS application, written in modern SwiftUI, that automatically mutes ads in the Spotify desktop app and restores the volume when the music resumes.

## 💡 Inspiration and Motivation

This project is heavily inspired by the excellent original repository [qmnl/MuteSpotifyAds](https://github.com/qmnl/MuteSpotifyAds).

My main motivation for rewriting this tool was that the original version will stop working on modern **Apple Silicon (Macs with M-series processors)** architectures and newer versions of macOS. To address this, I created this new version from scratch using SwiftUI and Swift's modern concurrency APIs (`async/await`), ensuring optimal performance, low battery consumption, and long-term native compatibility.

## ✨ Main Features

* **Automatic Mute:** Intelligently detects when an ad plays using AppleScript, lowering Spotify's volume to 0 and restoring it to its exact original level when the ad ends.

* **Infinite Private Session:** Monitors and forces Spotify to remain in "Private Session" at all times, preventing the application from automatically deactivating it after a period of inactivity.

## 🛠️ Requirements

* Modern macOS (Tested and optimized for macOS Tahoe).

* Mac with an Apple Silicon (M1/M2/M3/M4)

* The official Spotify desktop application is installed.

## 🚀 Installation and Compilation (For Developers)

1. Clone this repository to your Mac.
2. Open the `.xcodeproj` project in **Xcode**.

3. Select your project's Target and go to the **Signing & Capabilities** tab.

4. **Important:** Remove (click the trash can icon/X) the **"App Sandbox"** capability. This is strictly necessary for macOS to allow our application to run AppleScript and control other applications (Spotify and System Events).

5. Compile and run the application (`Cmd + R`).

### 🔒 System Permissions

Due to built-in macOS security, the first time you run the application, you will need to grant it a couple of permissions. The system will display a pop-up window; Simply go to **System Settings > Privacy and Security** and allow the following:

1. **Automation:** So the app can read the current track and change the Spotify volume.

2. **Accessibility:** So the app can interact with the system interface and invisibly click on the "Private Session" option in the Spotify menu.

## 📝 Language Setup Notes

The **Infinite Private Session** feature uses *UI Scripting* to click the menu. By default, the code looks for the English option: `"Private Session"`.

If you have the Spotify version installed in another language (for example, Spanish), you will need to modify the `SpotifyMonitor.swift` file. Find the line:
`set theMenuItem to menu item "Private Session" of theMenu`
And change it to the exact name that appears in your menu, like:
`set theMenuItem to menu item "Private Session" of theMenu`

*Made using Google Gemini as programming agent*

I don't know how to program in Swift or make a macOS app.

Don't ask me anything about this project.

Feel free to fork it.

## MIT License
