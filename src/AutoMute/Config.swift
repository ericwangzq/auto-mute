import Foundation

enum TriggerMode: String, Codable {
    case ax
    case microphone
    case hybrid
}

enum MediaControlMode: String, Codable {
    case mediaKey
    case nowPlayingUI
    case hid
    case mediaRemote
}

struct AppConfig: Codable {
    struct Size: Codable {
        var width: Double
        var height: Double
    }

    var triggerMode: TriggerMode
    var targetBundleIds: [String]
    var targetNameIncludes: [String]
    var allowedRoles: [String]
    var allowedSubroles: [String]
    var overlayMinSize: Size
    var overlayMaxSize: Size
    var debounceMs: Int
    var activeTimeoutMs: Int
    var observeAllCreated: Bool
    var debugLog: Bool
    var requireAudioRunning: Bool
    var menuBarTitle: String
    var mediaControlMode: MediaControlMode

    static func `default`() -> AppConfig {
        return AppConfig(
            triggerMode: .microphone,
            targetBundleIds: [
                "com.tencent.inputmethod.wetype",
                "com.tencent.inputmethod",
                "com.tencent.inputmethod.mac",
                "com.tencent.inputmethod.Mac",
                "com.tencent.inputmethod.inputmethod"
            ],
            targetNameIncludes: ["WeType", "微信输入法"],
            allowedRoles: ["AXWindow", "AXGroup", "AXDialog"],
            allowedSubroles: ["AXFloatingWindow", "AXDialog", "AXSystemDialog"],
            overlayMinSize: Size(width: 120, height: 30),
            overlayMaxSize: Size(width: 320, height: 120),
            debounceMs: 150,
            activeTimeoutMs: 120000,
            observeAllCreated: false,
            debugLog: false,
            requireAudioRunning: true,
            menuBarTitle: "AutoMute",
            mediaControlMode: .hid
        )
    }

    init(
        triggerMode: TriggerMode,
        targetBundleIds: [String],
        targetNameIncludes: [String],
        allowedRoles: [String],
        allowedSubroles: [String],
        overlayMinSize: Size,
        overlayMaxSize: Size,
        debounceMs: Int,
        activeTimeoutMs: Int,
        observeAllCreated: Bool,
        debugLog: Bool,
        requireAudioRunning: Bool,
        menuBarTitle: String,
        mediaControlMode: MediaControlMode
    ) {
        self.triggerMode = triggerMode
        self.targetBundleIds = targetBundleIds
        self.targetNameIncludes = targetNameIncludes
        self.allowedRoles = allowedRoles
        self.allowedSubroles = allowedSubroles
        self.overlayMinSize = overlayMinSize
        self.overlayMaxSize = overlayMaxSize
        self.debounceMs = debounceMs
        self.activeTimeoutMs = activeTimeoutMs
        self.observeAllCreated = observeAllCreated
        self.debugLog = debugLog
        self.requireAudioRunning = requireAudioRunning
        self.menuBarTitle = menuBarTitle
        self.mediaControlMode = mediaControlMode
    }

    enum CodingKeys: String, CodingKey {
        case triggerMode
        case targetBundleIds
        case targetNameIncludes
        case allowedRoles
        case allowedSubroles
        case overlayMinSize
        case overlayMaxSize
        case debounceMs
        case activeTimeoutMs
        case observeAllCreated
        case debugLog
        case requireAudioRunning
        case menuBarTitle
        case mediaControlMode
    }

    init(from decoder: Decoder) throws {
        let defaults = AppConfig.default()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        triggerMode = try container.decodeIfPresent(TriggerMode.self, forKey: .triggerMode) ?? defaults.triggerMode
        targetBundleIds = try container.decodeIfPresent([String].self, forKey: .targetBundleIds) ?? defaults.targetBundleIds
        targetNameIncludes = try container.decodeIfPresent([String].self, forKey: .targetNameIncludes) ?? defaults.targetNameIncludes
        allowedRoles = try container.decodeIfPresent([String].self, forKey: .allowedRoles) ?? defaults.allowedRoles
        allowedSubroles = try container.decodeIfPresent([String].self, forKey: .allowedSubroles) ?? defaults.allowedSubroles
        overlayMinSize = try container.decodeIfPresent(Size.self, forKey: .overlayMinSize) ?? defaults.overlayMinSize
        overlayMaxSize = try container.decodeIfPresent(Size.self, forKey: .overlayMaxSize) ?? defaults.overlayMaxSize
        debounceMs = try container.decodeIfPresent(Int.self, forKey: .debounceMs) ?? defaults.debounceMs
        activeTimeoutMs = try container.decodeIfPresent(Int.self, forKey: .activeTimeoutMs) ?? defaults.activeTimeoutMs
        observeAllCreated = try container.decodeIfPresent(Bool.self, forKey: .observeAllCreated) ?? defaults.observeAllCreated
        debugLog = try container.decodeIfPresent(Bool.self, forKey: .debugLog) ?? defaults.debugLog
        requireAudioRunning = try container.decodeIfPresent(Bool.self, forKey: .requireAudioRunning) ?? defaults.requireAudioRunning
        menuBarTitle = try container.decodeIfPresent(String.self, forKey: .menuBarTitle) ?? defaults.menuBarTitle
        mediaControlMode = try container.decodeIfPresent(MediaControlMode.self, forKey: .mediaControlMode) ?? defaults.mediaControlMode
    }

    static func loadOrCreate() -> AppConfig {
        let url = configURL()
        let fm = FileManager.default
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            let normalized = normalize(decoded)
            if let encoded = try? JSONEncoder().encode(normalized), encoded != data {
                try? encoded.write(to: url, options: [.atomic])
            }
            return normalized
        }

        let config = AppConfig.default()
        do {
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(config)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Best-effort only; keep running with defaults.
        }
        return config
    }

    private static func normalize(_ config: AppConfig) -> AppConfig {
        var c = config
        if !c.targetBundleIds.contains("com.tencent.inputmethod.wetype") {
            c.targetBundleIds.insert("com.tencent.inputmethod.wetype", at: 0)
        }
        if !c.targetNameIncludes.contains("WeType") {
            c.targetNameIncludes.append("WeType")
        }
        c.targetNameIncludes.removeAll { $0 == "WeChat" }
        return c
    }

    static func configURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("AutoMute", isDirectory: true)
            .appendingPathComponent("config.json")
    }
}

enum Log {
    static var enabled = false
    static func info(_ message: String) {
        guard enabled else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
        print("[AutoMute] [\(ts)] \(message)")
    }
}
