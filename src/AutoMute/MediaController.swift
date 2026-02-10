import Foundation

enum MediaController {
    static func togglePlayPause(mode: MediaControlMode) {
        switch mode {
        case .mediaKey:
            MediaKey.togglePlayPause()
        case .nowPlayingUI:
            NowPlayingUI.togglePlayPause()
        case .hid:
            HIDMediaKey.togglePlayPause()
        case .mediaRemote:
            MediaRemoteControl.togglePlayPause()
        }
    }
}
