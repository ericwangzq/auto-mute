import ApplicationServices

enum AccessibilityPermission {
    static func requestIfNeeded() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func granted() -> Bool {
        return AXIsProcessTrusted()
    }
}
