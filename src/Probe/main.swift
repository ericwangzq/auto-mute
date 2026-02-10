import Cocoa

var config = AppConfig.loadOrCreate()
config.debugLog = true
config.observeAllCreated = true
Log.enabled = true

let detector = AXVoiceDetector(config: config, mode: .probe)
let granted = detector.ensureAccessibilityPermission()
if !granted {
    print("Accessibility permission is required. Please grant and rerun.")
}

detector.start(promptForAccessibility: false)
print("AutoMute probe running. Trigger voice input to see AX logs. Press Ctrl+C to exit.")
RunLoop.main.run()
