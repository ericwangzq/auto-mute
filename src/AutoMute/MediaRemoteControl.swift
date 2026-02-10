import Foundation
import Darwin

enum MediaRemoteControl {
    private typealias SendCommandFn = @convention(c) (Int32, CFDictionary?) -> Void
    private static var handle: UnsafeMutableRawPointer? = nil
    private static var sendCommand: SendCommandFn? = nil

    static func togglePlayPause() {
        guard load() else {
            Log.info("MediaRemote: load failed")
            return
        }
        guard let sendCommand else {
            Log.info("MediaRemote: sendCommand missing")
            return
        }
        // 2 is commonly used for toggle play/pause.
        sendCommand(2, nil)
        Log.info("MediaRemote: sent toggle")
    }

    private static func load() -> Bool {
        if sendCommand != nil { return true }
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        handle = dlopen(path, RTLD_NOW)
        if handle == nil {
            Log.info("MediaRemote: dlopen failed")
            return false
        }
        if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommand = unsafeBitCast(sym, to: SendCommandFn.self)
            return true
        }
        return false
    }
}
