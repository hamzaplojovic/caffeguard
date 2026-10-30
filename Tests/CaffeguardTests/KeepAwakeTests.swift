import Foundation
import IOKit.pwr_mgt
import Testing
@testable import Caffeguard

struct KeepAwakeTests {
    // Representative power assertions: commercial apps are not launched by these tests.
    // KeepingYouAwake and Raycast Coffee run caffeinate, which owns their assertions.
    @Test(arguments: [
        "PreventUserIdleSystemSleep", "PreventUserIdleDisplaySleep", "PreventSystemSleep",
        "NoIdleSleepAssertion", "NoDisplaySleepAssertion",
    ], [
        (name: "Terminal", path: "/usr/bin/caffeinate"),
        (name: "Amphetamine", path: "/Applications/Amphetamine.app/Contents/MacOS/Amphetamine"),
        (name: "KeepingYouAwake", path: "/usr/bin/caffeinate"),
        (name: "Lungo", path: "/Applications/Lungo.app/Contents/MacOS/Lungo"),
        (name: "Theine", path: "/Applications/Theine.app/Contents/MacOS/Theine"),
        (name: "Caffeinated", path: "/Applications/Caffeinated.app/Contents/MacOS/Caffeinated"),
        (name: "Raycast Coffee", path: "/usr/bin/caffeinate"),
    ])
    func supportedAppsCountOnlyWhileTheirSessionIsActive(type: String, source: (name: String, path: String)) {
        #expect(SystemActivity.keepsMacAwake(assertion: assertion(type), processPath: source.path))
        #expect(!SystemActivity.keepsMacAwake(
            assertion: assertion(type, level: kIOPMAssertionLevelOff), processPath: source.path
        ))
    }

    @Test(arguments: [
        "/Users/owner/Applications/Lungo.app/Contents/MacOS/Lungo",
        "/Volumes/Tools/Theine.app/Contents/MacOS/Theine",
        "/Applications/Renamed.app/Contents/MacOS/Helper",
    ])
    func installationLocationAndProcessNameDoNotLimitSupport(path: String) {
        #expect(SystemActivity.keepsMacAwake(assertion: assertion(), processPath: path))
    }

    @Test(arguments: [
        "/System/Library/CoreServices/powerd.bundle/powerd",
        "/usr/sbin/coreaudiod",
        "/usr/libexec/backupd",
        "/Library/Apple/System/Library/ExampleHelper",
    ])
    func macOSItselfDoesNotCount(path: String) {
        #expect(!SystemActivity.keepsMacAwake(assertion: assertion(), processPath: path))
    }

    @Test(arguments: ["UserIsActive", "PreventDiskIdle", "InternalPreventDisplaySleep", "Unknown"])
    func otherKindsOfAssertionDoNotCount(type: String) {
        #expect(!SystemActivity.keepsMacAwake(assertion: assertion(type), processPath: "/usr/bin/caffeinate"))
    }

    @Test func incompleteAssertionsAndUnknownProcessesDoNotCount() {
        for incomplete: [String: Any] in [
            [:],
            [kIOPMAssertionTypeKey: "PreventUserIdleSystemSleep"],
            [kIOPMAssertionLevelKey: kIOPMAssertionLevelOn],
            [kIOPMAssertionTypeKey: "PreventUserIdleSystemSleep", kIOPMAssertionLevelKey: "255"],
        ] {
            #expect(!SystemActivity.keepsMacAwake(assertion: incomplete, processPath: "/usr/bin/caffeinate"))
        }
        #expect(!SystemActivity.keepsMacAwake(assertion: assertion(), processPath: nil))
    }

    @Test func oneActiveAppAmongSystemAndPausedAssertionsIsEnough() {
        var snapshot: [NSNumber: [[String: Any]]] = [
            1: [assertion()], // powerd
            2: [assertion(level: kIOPMAssertionLevelOff), assertion("PreventDiskIdle")],
            3: [assertion()], // a process that has exited before its path could be read
        ]
        let paths: [pid_t: String] = [
            1: "/System/Library/CoreServices/powerd.bundle/powerd",
            2: "/usr/bin/caffeinate",
            4: "/Applications/Caffeinated.app/Contents/MacOS/Caffeinated",
        ]
        #expect(!SystemActivity.isKeptAwake(assertionsByProcess: snapshot) { paths[$0] })
        snapshot[4] = [assertion("UserIsActive"), assertion("PreventUserIdleDisplaySleep")]
        #expect(SystemActivity.isKeptAwake(assertionsByProcess: snapshot) { paths[$0] })
        snapshot[4] = []
        #expect(!SystemActivity.isKeptAwake(assertionsByProcess: snapshot) { paths[$0] })
        #expect(!SystemActivity.isKeptAwake(assertionsByProcess: [:]) { paths[$0] })
    }

    @Test func aRealPowerAssertionCanBePausedAndResumed() throws {
        let name = "Caffeguard compatibility test \(UUID().uuidString)"
        var id = IOPMAssertionID(kIOPMNullAssertionID)
        try #require(IOPMAssertionCreateWithName(
            kIOPMAssertPreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn), name as CFString, &id
        ) == kIOReturnSuccess)
        defer { IOPMAssertionRelease(id) }

        func isActive() throws -> Bool {
            var result: Unmanaged<CFDictionary>?
            try #require(IOPMCopyAssertionsByProcess(&result) == kIOReturnSuccess)
            let snapshot = try #require(result?.takeRetainedValue() as? [NSNumber: [[String: Any]]])
            let ownPID = NSNumber(value: ProcessInfo.processInfo.processIdentifier)
            let ownAssertions = (snapshot[ownPID] ?? []).filter { $0[kIOPMAssertionNameKey] as? String == name }
            return SystemActivity.isKeptAwake(assertionsByProcess: [ownPID: ownAssertions]) { _ in
                Bundle.main.executableURL?.path
            }
        }

        #expect(try isActive())
        try #require(IOPMAssertionSetProperty(
            id, kIOPMAssertionLevelKey as CFString, NSNumber(value: kIOPMAssertionLevelOff)
        ) == kIOReturnSuccess)
        #expect(try !isActive())
        try #require(IOPMAssertionSetProperty(
            id, kIOPMAssertionLevelKey as CFString, NSNumber(value: kIOPMAssertionLevelOn)
        ) == kIOReturnSuccess)
        #expect(try isActive())
    }

    private func assertion(
        _ type: String = "PreventUserIdleSystemSleep", level: Int = kIOPMAssertionLevelOn
    ) -> [String: Any] {
        [kIOPMAssertionTypeKey: type, kIOPMAssertionLevelKey: NSNumber(value: level)]
    }
}
