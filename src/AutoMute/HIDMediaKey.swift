import Foundation
import IOKit
import IOKit.hidsystem

enum HIDMediaKey {
    static func requestAccessIfNeeded() {
        _ = IOHIDRequestAccess(kIOHIDRequestTypePostEvent)
    }

    static func togglePlayPause() {
        postMediaKey(NX_KEYTYPE_PLAY)
    }

    private static func postMediaKey(_ key: Int32) {
        guard let connect = openHIDSystem() else {
            Log.info("HIDMediaKey: failed to open IOHIDSystem")
            return
        }
        defer { IOServiceClose(connect) }

        var event = NXEventData()
        event.compound.subType = Int16(NX_SUBTYPE_AUX_CONTROL_BUTTONS)
        event.compound.misc.L.0 = (key << 16) | (0xA << 8)
        event.compound.misc.L.1 = 0
        IOHIDPostEvent(connect, UInt32(NX_SYSDEFINED), IOGPoint(x: 0, y: 0), &event, UInt32(kNXEventDataVersion), 0, 0)

        event.compound.misc.L.0 = (key << 16) | (0xB << 8)
        IOHIDPostEvent(connect, UInt32(NX_SYSDEFINED), IOGPoint(x: 0, y: 0), &event, UInt32(kNXEventDataVersion), 0, 0)
    }

    private static func openHIDSystem() -> io_connect_t? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        if service == 0 {
            return nil
        }
        defer { IOObjectRelease(service) }

        var connect: io_connect_t = 0
        let result = IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect)
        if result != KERN_SUCCESS {
            return nil
        }
        return connect
    }
}
