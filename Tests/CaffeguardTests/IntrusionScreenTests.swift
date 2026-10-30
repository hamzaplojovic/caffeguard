import AppKit
import Foundation
import Testing
@testable import Caffeguard

struct IntrusionScreenTests {
    private func withDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let suite = "CaffeguardTests.IntrusionScreen.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @Test func newInstallUsesTheRedScreenAndBothVerificationTriggers() throws {
        try withDefaults { defaults in
            let configuration = IntrusionScreenConfiguration(defaults: defaults)
            #expect(configuration.theme.id == Theme.all[0].id)
            #expect(configuration.displayMessage == Theme.all[0].message)
            #expect(configuration.unlockTrigger == .doubleClickOrAnyKey)
        }
    }

    @Test(arguments: IntrusionUnlockTrigger.allCases)
    func savedChoicesAndCustomMessageAreLoaded(trigger: IntrusionUnlockTrigger) throws {
        for theme in Theme.all {
            try withDefaults { defaults in
                defaults.set(theme.id, forKey: Preference.theme)
                defaults.set("Private Mac. Please contact the owner.", forKey: Preference.intrusionMessage)
                defaults.set(trigger.rawValue, forKey: Preference.intrusionUnlockTrigger)

                let configuration = IntrusionScreenConfiguration(defaults: defaults)
                #expect(configuration.theme.id == theme.id)
                #expect(configuration.displayMessage == "Private Mac. Please contact the owner.")
                #expect(configuration.unlockTrigger == trigger)
            }
        }
    }

    @Test func aBlankMessageKeepsEachThemesOwnWords() {
        for theme in Theme.all {
            let configuration = IntrusionScreenConfiguration(themeID: theme.id, message: " \n\t ")
            #expect(configuration.displayMessage == theme.message)
        }
    }

    @Test func unknownSavedChoicesAndBlankMessageHaveUsableDefaults() throws {
        try withDefaults { defaults in
            defaults.set("unknown-style", forKey: Preference.theme)
            defaults.set(" \n\t ", forKey: Preference.intrusionMessage)
            defaults.set("unknown-trigger", forKey: Preference.intrusionUnlockTrigger)

            let configuration = IntrusionScreenConfiguration(defaults: defaults)
            #expect(configuration.theme.id == Theme.all[0].id)
            #expect(configuration.unlockTrigger == .doubleClickOrAnyKey)
            #expect(configuration.displayMessage == Theme.all[0].message)
        }
    }

    @Test(arguments: IntrusionUnlockTrigger.allCases)
    func windowOnlyRequestsVerificationForTheChosenInput(trigger: IntrusionUnlockTrigger) throws {
        _ = NSApplication.shared
        let window = IntrusionAlertWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: .borderless, backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.unlockTrigger = trigger
        var requests = 0
        window.onUnlockRequest = { requests += 1 }

        func click(_ count: Int) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(
                with: .leftMouseDown, location: NSPoint(x: 40, y: 40), modifierFlags: [],
                timestamp: 0, windowNumber: window.windowNumber, context: nil,
                eventNumber: 1, clickCount: count, pressure: 1
            ))
        }
        func key(repeated: Bool = false) throws -> NSEvent {
            try #require(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                windowNumber: window.windowNumber, context: nil, characters: "a",
                charactersIgnoringModifiers: "a", isARepeat: repeated, keyCode: 0
            ))
        }

        window.sendEvent(try click(1))
        #expect(requests == 0) // A single click never starts verification.
        window.sendEvent(try click(2))
        #expect(requests == (trigger == .anyKey ? 0 : 1))
        requests = 0
        window.sendEvent(try key())
        #expect(requests == (trigger == .doubleClick ? 0 : 1))
        requests = 0
        window.sendEvent(try key(repeated: true))
        #expect(requests == 0) // Holding a key must not repeatedly reopen the prompt.
        #expect(!window.isVisible) // Requests never show or dismiss a real alert in this test.
    }
}
