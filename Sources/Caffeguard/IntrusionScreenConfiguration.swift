import Foundation

enum IntrusionUnlockTrigger: String, CaseIterable, Identifiable {
    case doubleClick, anyKey, doubleClickOrAnyKey

    enum Interaction {
        case doubleClick, keyPress
    }

    var id: Self { self }

    var title: String {
        switch self {
        case .doubleClick: "Double-click"
        case .anyKey: "Any key"
        case .doubleClickOrAnyKey: "Double-click or any key"
        }
    }

    var instruction: String {
        switch self {
        case .doubleClick: "Double-click to verify with Touch ID or your Mac password."
        case .anyKey: "Press any key to verify with Touch ID or your Mac password."
        case .doubleClickOrAnyKey: "Double-click or press any key to verify with Touch ID or your Mac password."
        }
    }

    func accepts(_ interaction: Interaction) -> Bool {
        switch (self, interaction) {
        case (.doubleClick, .doubleClick), (.anyKey, .keyPress), (.doubleClickOrAnyKey, _): true
        default: false
        }
    }
}

struct IntrusionScreenConfiguration {
    var themeID = Theme.all[0].id
    var message = ""
    var unlockTrigger: IntrusionUnlockTrigger = .doubleClickOrAnyKey

    var theme: Theme { Theme.all.first { $0.id == themeID } ?? Theme.all[0] }

    var displayMessage: String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? theme.message : trimmed
    }
}

extension IntrusionScreenConfiguration {
    init(defaults: UserDefaults) {
        themeID = defaults.string(forKey: Preference.theme) ?? Theme.all[0].id
        message = defaults.string(forKey: Preference.intrusionMessage) ?? ""
        unlockTrigger = defaults.string(forKey: Preference.intrusionUnlockTrigger)
            .flatMap(IntrusionUnlockTrigger.init(rawValue:)) ?? .doubleClickOrAnyKey
    }
}
