import Foundation
import ApplicationServices

final class AutoMuteController {
    private var config: AppConfig
    private let axDetector: AXVoiceDetector?
    private let micMonitor: MicActivityMonitor?
    private var pausedByUs = false
    private var isEnabled = true
    private var lastToggleTime: Date?
    private var activeSources = Set<String>()

    init(config: AppConfig) {
        self.config = config
        switch config.triggerMode {
        case .ax:
            self.axDetector = AXVoiceDetector(config: config)
            self.micMonitor = nil
        case .microphone:
            self.axDetector = nil
            self.micMonitor = MicActivityMonitor()
        case .hybrid:
            self.axDetector = AXVoiceDetector(config: config)
            self.micMonitor = MicActivityMonitor()
        }
        Log.enabled = config.debugLog
    }

    func start() {
        if requiresAccessibility() {
            _ = AccessibilityPermission.requestIfNeeded()
        }
        if config.mediaControlMode == .hid {
            HIDMediaKey.requestAccessIfNeeded()
        }
        axDetector?.onStart = { [weak self] in
            self?.handleStart(source: "ax")
        }
        axDetector?.onEnd = { [weak self] in
            self?.handleEnd(source: "ax")
        }
        micMonitor?.onStart = { [weak self] in
            self?.handleStart(source: "mic")
        }
        micMonitor?.onEnd = { [weak self] in
            self?.handleEnd(source: "mic")
        }

        axDetector?.start(promptForAccessibility: false)
        micMonitor?.start()
    }

    func stop() {
        axDetector?.stop()
        micMonitor?.stop()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            activeSources.removeAll()
            pausedByUs = false
        }
    }

    func setMediaControlMode(_ mode: MediaControlMode) {
        config.mediaControlMode = mode
        if mode == .hid {
            HIDMediaKey.requestAccessIfNeeded()
        }
        if mode == .nowPlayingUI {
            _ = AccessibilityPermission.requestIfNeeded()
        }
    }

    func getMediaControlMode() -> MediaControlMode {
        return config.mediaControlMode
    }

    func getEnabled() -> Bool {
        return isEnabled
    }

    func accessibilityAuthorized() -> Bool {
        return AccessibilityPermission.granted()
    }

    func requiresAccessibility() -> Bool {
        if config.mediaControlMode == .nowPlayingUI {
            return true
        }
        if config.triggerMode == .ax || config.triggerMode == .hybrid {
            return true
        }
        return false
    }

    private func handleStart(source: String) {
        let wasActive = !activeSources.isEmpty
        activeSources.insert(source)
        Log.info("Trigger start from \(source). Active sources=\(activeSources)")
        guard !wasActive else { return }
        guard isEnabled else { return }
        if config.requireAudioRunning && !AudioDevice.isDefaultOutputRunning() {
            Log.info("Audio not running; skip pause.")
            pausedByUs = false
            return
        }
        if shouldThrottleToggle() {
            return
        }
        MediaController.togglePlayPause(mode: config.mediaControlMode)
        pausedByUs = true
        Log.info("Sent play/pause (pause).")
    }

    private func handleEnd(source: String) {
        activeSources.remove(source)
        Log.info("Trigger end from \(source). Active sources=\(activeSources)")
        guard activeSources.isEmpty else { return }
        guard isEnabled else {
            pausedByUs = false
            return
        }
        guard pausedByUs else { return }
        if shouldThrottleToggle() {
            return
        }
        MediaController.togglePlayPause(mode: config.mediaControlMode)
        pausedByUs = false
        Log.info("Sent play/pause (resume).")
    }

    private func shouldThrottleToggle() -> Bool {
        let now = Date()
        if let last = lastToggleTime, now.timeIntervalSince(last) < 0.25 {
            return true
        }
        lastToggleTime = now
        return false
    }
}
