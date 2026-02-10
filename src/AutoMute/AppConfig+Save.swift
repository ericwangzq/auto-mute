import Foundation

extension AppConfig {
    func save() {
        let url = AppConfig.configURL()
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(self)
            try data.write(to: url, options: [.atomic])
        } catch {
            Log.info("Config save failed: \(error)")
        }
    }
}
