import Cocoa
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var config = AppConfig.loadOrCreate()
    private lazy var controller = AutoMuteController(config: config)

    private var statusItem: NSStatusItem!
    private var enabledItem: NSMenuItem!
    private var loginItem: NSMenuItem!
    private var accessItem: NSMenuItem!
    private var mediaModeItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.start()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let iconURL = Bundle.main.url(forResource: "menubar-icon", withExtension: "png"),
               let image = NSImage(contentsOf: iconURL) {
                image.isTemplate = true
                button.image = image
                button.title = ""
            } else {
                button.title = config.menuBarTitle
            }
            button.toolTip = "AutoMute"
        }

        let menu = NSMenu()
        menu.delegate = self

        enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.target = self
        menu.addItem(enabledItem)

        mediaModeItem = NSMenuItem(title: "Media Control", action: nil, keyEquivalent: "")
        mediaModeItem.submenu = buildMediaModeMenu()
        menu.addItem(mediaModeItem)

        loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)

        accessItem = NSMenuItem(title: "Accessibility: Unknown", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        accessItem.target = self
        menu.addItem(accessItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateMenuState()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenuState()
    }

    private func updateMenuState() {
        enabledItem.state = controller.getEnabled() ? .on : .off
        loginItem.state = loginItemEnabled() ? .on : .off
        if controller.requiresAccessibility() {
            accessItem.title = controller.accessibilityAuthorized() ? "Accessibility: Granted" : "Accessibility: Not Granted"
            accessItem.isEnabled = true
        } else {
            accessItem.title = "Accessibility: Not Required"
            accessItem.isEnabled = false
        }
        updateMediaModeMenuState()
    }

    @objc private func toggleEnabled() {
        controller.setEnabled(!controller.getEnabled())
        updateMenuState()
    }

    @objc private func toggleLoginItem() {
        let enabled = !loginItemEnabled()
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Log.info("Failed to toggle login item: \(error)")
        }
        updateMenuState()
    }

    private func buildMediaModeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(makeMediaModeItem(title: "MediaRemote (Recommended)", mode: .mediaRemote))
        menu.addItem(makeMediaModeItem(title: "HID Event", mode: .hid))
        menu.addItem(makeMediaModeItem(title: "Media Key", mode: .mediaKey))
        menu.addItem(makeMediaModeItem(title: "Now Playing UI (Not Recommended)", mode: .nowPlayingUI))
        return menu
    }

    private func makeMediaModeItem(title: String, mode: MediaControlMode) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(selectMediaMode(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = mode
        return item
    }

    private func updateMediaModeMenuState() {
        guard let submenu = mediaModeItem.submenu else { return }
        let current = controller.getMediaControlMode()
        for item in submenu.items {
            if let mode = item.representedObject as? MediaControlMode {
                item.state = (mode == current) ? .on : .off
            }
        }
    }

    @objc private func selectMediaMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? MediaControlMode else { return }
        controller.setMediaControlMode(mode)
        config.mediaControlMode = mode
        config.save()
        updateMediaModeMenuState()
    }

    @objc private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func loginItemEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
}
