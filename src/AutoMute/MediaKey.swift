import Cocoa

enum MediaKey {
    private static let keyStateDown: Int32 = 0xA
    private static let keyStateUp: Int32 = 0xB
    private static let playPauseKey: Int32 = 16

    static func togglePlayPause() {
        postMediaKey(playPauseKey, isDown: true)
        postMediaKey(playPauseKey, isDown: false)
    }

    private static func postMediaKey(_ key: Int32, isDown: Bool) {
        let keyState = isDown ? keyStateDown : keyStateUp
        let data1 = Int((key << 16) | (keyState << 8))
        let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: .init(rawValue: 0xA00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: -1
        )
        event?.cgEvent?.post(tap: .cghidEventTap)
    }
}
