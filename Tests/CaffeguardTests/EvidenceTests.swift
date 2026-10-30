import Foundation
import Testing
@testable import Caffeguard

struct EvidenceTests {
    private func withDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let suite = "CaffeguardTests.Evidence.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @Test func noSelectionAndResetUseTheOriginalFolder() throws {
        try withDefaults { defaults in
            #expect(Evidence.folder(defaults: defaults) == Evidence.defaultFolder)
            defaults.set("/tmp/Custom Photos", forKey: Preference.photoFolderPath)
            defaults.set("", forKey: Preference.photoFolderPath)
            #expect(Evidence.folder(defaults: defaults) == Evidence.defaultFolder)
        }
    }

    @Test func savesPhotosInThePersistedDestinationAndCreatesMissingDirectories() throws {
        try withDefaults { defaults in
            let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: root) }
            let destination = root.appending(path: "My Photos/Intrusions", directoryHint: .isDirectory)
            defaults.set(destination.path, forKey: Preference.photoFolderPath)

            let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
            let saved = try Evidence.save(jpeg, defaults: defaults)

            #expect(saved.deletingLastPathComponent() == destination)
            #expect(saved.pathExtension == "jpg")
            #expect(try Data(contentsOf: saved) == jpeg)
        }
    }

    @Test func theLastPhotoIsReadFromTheSelectedFolder() throws {
        try withDefaults { defaults in
            let destination = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: destination) }
            defaults.set(destination.path, forKey: Preference.photoFolderPath)
            #expect(Evidence.latest(defaults: defaults) == nil)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            for name in ["Intrusion 2026-10-29 at 12.00.00.jpg", "Intrusion 2026-10-30 at 12.00.00.jpg", "notes.txt"] {
                try Data().write(to: destination.appending(path: name))
            }
            #expect(Evidence.latest(defaults: defaults)?.lastPathComponent == "Intrusion 2026-10-30 at 12.00.00.jpg")
        }
    }
}
