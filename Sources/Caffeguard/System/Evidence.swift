import AppKit

/// Intrusion photos, saved to the chosen folder or ~/Pictures/Caffeguard by default.
enum Evidence {
    static let defaultFolder = URL.picturesDirectory.appending(path: "Caffeguard", directoryHint: .isDirectory)

    static func folder(defaults: UserDefaults = .standard) -> URL {
        guard let path = defaults.string(forKey: Preference.photoFolderPath), !path.isEmpty else {
            return defaultFolder
        }
        return URL(filePath: path, directoryHint: .isDirectory)
    }

    private static let fileDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return formatter
    }()

    static func save(_ jpeg: Data, defaults: UserDefaults = .standard) throws -> URL {
        let folder = folder(defaults: defaults)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: "Intrusion \(fileDate.string(from: .now)).jpg")
        try jpeg.write(to: url)
        return url
    }

    /// The newest photo, so the menu can show it even after Caffeguard restarts.
    static var latest: URL? {
        latest(defaults: .standard)
    }

    static func latest(defaults: UserDefaults) -> URL? {
        let folder = folder(defaults: defaults)
        let photos = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        // File names start with the date and time, so name order is time order.
        return photos.filter { $0.pathExtension == "jpg" }.max { $0.lastPathComponent < $1.lastPathComponent }
    }

    static func showInFinder() {
        let folder = folder()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }
}
