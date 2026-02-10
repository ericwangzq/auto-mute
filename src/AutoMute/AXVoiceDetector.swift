import Cocoa
import ApplicationServices

final class AXVoiceDetector {
    enum Mode {
        case normal
        case probe
    }

    private let config: AppConfig
    private let mode: Mode
    private var observer: AXObserver?
    private var appElement: AXUIElement?
    private var appPID: pid_t?
    private var overlays: [UInt: AXUIElement] = [:]
    private var debounceWorkItem: DispatchWorkItem?
    private var timeoutTimer: DispatchSourceTimer?
    private var voiceActive = false

    var onStart: (() -> Void)?
    var onEnd: (() -> Void)?

    init(config: AppConfig, mode: Mode = .normal) {
        self.config = config
        self.mode = mode
    }

    func start(promptForAccessibility: Bool = true) {
        if promptForAccessibility {
            _ = ensureAccessibilityPermission()
        }

        attachToMatchingAppIfRunning()
        observeAppLifecycle()
    }

    func stop() {
        detach()
    }

    func ensureAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func observeAppLifecycle() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(appLaunched(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        nc.addObserver(self, selector: #selector(appTerminated(_:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }

    @objc private func appLaunched(_ notification: Notification) {
        attachToMatchingAppIfRunning()
    }

    @objc private func appTerminated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if app.processIdentifier == appPID {
            Log.info("Input method terminated; resetting state.")
            resetStateAndNotifyEnd()
            detach()
        }
    }

    private func attachToMatchingAppIfRunning() {
        if appPID != nil { return }
        let apps = NSWorkspace.shared.runningApplications
        if let app = apps.first(where: { matchesTargetAppByBundleId($0) }) ?? apps.first(where: { matchesTargetAppByName($0) }) {
            attach(to: app)
        }
    }

    private func matchesTargetApp(_ app: NSRunningApplication) -> Bool {
        return matchesTargetAppByBundleId(app) || matchesTargetAppByName(app)
    }

    private func matchesTargetAppByBundleId(_ app: NSRunningApplication) -> Bool {
        if let bundleId = app.bundleIdentifier {
            return config.targetBundleIds.contains(bundleId)
        }
        return false
    }

    private func matchesTargetAppByName(_ app: NSRunningApplication) -> Bool {
        if let name = app.localizedName {
            for needle in config.targetNameIncludes where name.localizedCaseInsensitiveContains(needle) {
                return true
            }
        }
        return false
    }

    private func attach(to app: NSRunningApplication) {
        detach()
        Log.info("Attaching to input method: \(app.localizedName ?? "(unknown)") [pid=\(app.processIdentifier)]")
        appPID = app.processIdentifier
        appElement = AXUIElementCreateApplication(app.processIdentifier)

        var newObserver: AXObserver?
        let result = AXObserverCreate(app.processIdentifier, axObserverCallback, &newObserver)
        guard result == .success, let observer = newObserver, let appElement = appElement else {
            Log.info("Failed to create AXObserver: \(result.rawValue)")
            return
        }
        self.observer = observer

        let context = Unmanaged.passUnretained(self).toOpaque()
        let windowResult = AXObserverAddNotification(observer, appElement, kAXWindowCreatedNotification as CFString, context)
        if windowResult != .success {
            Log.info("Failed to add kAXWindowCreatedNotification: \(windowResult.rawValue)")
        }
        if config.observeAllCreated || mode == .probe {
            let createdResult = AXObserverAddNotification(observer, appElement, kAXCreatedNotification as CFString, context)
            if createdResult != .success {
                Log.info("Failed to add kAXCreatedNotification: \(createdResult.rawValue)")
            }
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }

    private func detach() {
        if let observer = observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
        observer = nil
        appElement = nil
        appPID = nil
        overlays.removeAll()
        voiceActive = false
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        timeoutTimer?.cancel()
        timeoutTimer = nil
    }

    fileprivate func handle(notification: String, element: AXUIElement) {
        if notification == kAXWindowCreatedNotification || notification == kAXCreatedNotification {
            if mode == .probe {
                logElementDetails(element, source: notification)
            }
            if isOverlayElement(element) {
                trackOverlay(element)
            }
        } else if notification == kAXUIElementDestroyedNotification {
            untrackOverlay(element)
        }
    }

    private func trackOverlay(_ element: AXUIElement) {
        let key = elementKey(element)
        guard overlays[key] == nil else { return }
        overlays[key] = element
        Log.info("Overlay detected. count=\(overlays.count)")

        if let observer = observer {
            let context = Unmanaged.passUnretained(self).toOpaque()
            let result = AXObserverAddNotification(observer, element, kAXUIElementDestroyedNotification as CFString, context)
            if result != .success {
                Log.info("Failed to observe destroy for overlay: \(result.rawValue)")
            }
        }

        if !voiceActive {
            voiceActive = true
            let delay = DispatchTimeInterval.milliseconds(max(0, config.debounceMs))
            debounceWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                guard !self.overlays.isEmpty else { return }
                self.onStart?()
                self.startTimeoutTimer()
            }
            debounceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    private func untrackOverlay(_ element: AXUIElement) {
        let key = elementKey(element)
        if overlays.removeValue(forKey: key) != nil {
            Log.info("Overlay removed. count=\(overlays.count)")
        }
        if overlays.isEmpty {
            resetStateAndNotifyEnd()
        }
    }

    private func resetStateAndNotifyEnd() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        timeoutTimer?.cancel()
        timeoutTimer = nil
        if voiceActive {
            voiceActive = false
            onEnd?()
        }
    }

    private func startTimeoutTimer() {
        let timeoutMs = max(1000, config.activeTimeoutMs)
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + .milliseconds(timeoutMs))
        timer.setEventHandler { [weak self] in
            Log.info("Voice session timeout reached; forcing end.")
            self?.overlays.removeAll()
            self?.resetStateAndNotifyEnd()
        }
        timer.resume()
        timeoutTimer?.cancel()
        timeoutTimer = timer
    }

    private func isOverlayElement(_ element: AXUIElement) -> Bool {
        if let hidden = AXHelpers.axBool(element, kAXHiddenAttribute), hidden {
            return false
        }

        guard let size = AXHelpers.axSize(element, kAXSizeAttribute) else { return false }
        let min = config.overlayMinSize
        let max = config.overlayMaxSize
        guard size.width >= min.width,
              size.height >= min.height,
              size.width <= max.width,
              size.height <= max.height else {
            return false
        }

        let role = AXHelpers.axString(element, kAXRoleAttribute) ?? ""
        let subrole = AXHelpers.axString(element, kAXSubroleAttribute) ?? ""

        if !config.allowedRoles.isEmpty && !config.allowedRoles.contains(role) {
            return false
        }
        if !config.allowedSubroles.isEmpty && !config.allowedSubroles.contains(subrole) {
            // Subrole can be empty for some elements. Allow empty.
            if !subrole.isEmpty {
                return false
            }
        }

        return true
    }

    private func elementKey(_ element: AXUIElement) -> UInt {
        return UInt(bitPattern: Unmanaged.passUnretained(element).toOpaque())
    }

    private func logElementDetails(_ element: AXUIElement, source: String) {
        let role = AXHelpers.axString(element, kAXRoleAttribute) ?? "(nil)"
        let subrole = AXHelpers.axString(element, kAXSubroleAttribute) ?? "(nil)"
        let title = AXHelpers.axString(element, kAXTitleAttribute) ?? "(nil)"
        let size = AXHelpers.axSize(element, kAXSizeAttribute)
        let pos = AXHelpers.axPoint(element, kAXPositionAttribute)
        Log.info("AX \(source) role=\(role) subrole=\(subrole) title=\(title) size=\(size?.debugDescription ?? "(nil)") pos=\(pos?.debugDescription ?? "(nil)")")
    }
}

private func axObserverCallback(observer: AXObserver, element: AXUIElement, notification: CFString, refcon: UnsafeMutableRawPointer?) {
    guard let refcon else { return }
    let detector = Unmanaged<AXVoiceDetector>.fromOpaque(refcon).takeUnretainedValue()
    detector.handle(notification: notification as String, element: element)
}
