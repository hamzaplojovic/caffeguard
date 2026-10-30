import CoreGraphics
import Foundation
import IOKit.pwr_mgt

/// The two facts that arm Caffeguard: something keeps the Mac awake, and nobody is using it.
enum SystemActivity {
    /// Assertion types an app holds to stop the Mac idling to sleep, current and legacy names.
    private static let keepAwakeTypes: Set<String> = [
        "PreventUserIdleSystemSleep", "PreventUserIdleDisplaySleep", "PreventSystemSleep",
        "NoIdleSleepAssertion", "NoDisplaySleepAssertion",
    ]
    /// Only these programs count, matched by executable name wherever they are installed.
    /// Browsers, music and video calls hold the same assertions for their own reasons, so they
    /// must not arm Caffeguard. KeepingYouAwake and Raycast's Coffee run `caffeinate`, which
    /// owns their assertions, so they are covered by it.
    static let keepAwakeTools: Set<String> = [
        "caffeinate", "Amphetamine", "Lungo", "Theine", "Caffeinated", "Caffeine", "Owly",
    ]

    /// True while one of `keepAwakeTools` actively keeps the Mac from idling to sleep.
    static var isKeptAwake: Bool {
        var byProcess: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&byProcess) == kIOReturnSuccess,
              let assertions = byProcess?.takeRetainedValue() as? [NSNumber: [[String: Any]]]
        else { return false }
        return isKeptAwake(assertionsByProcess: assertions, processPath: processPath)
    }

    static func isKeptAwake(
        assertionsByProcess: [NSNumber: [[String: Any]]],
        processPath: (pid_t) -> String?
    ) -> Bool {
        assertionsByProcess.contains { pid, held in
            let path = processPath(pid.int32Value)
            return held.contains { keepsMacAwake(assertion: $0, processPath: path) }
        }
    }

    static func keepsMacAwake(assertion: [String: Any], processPath: String?) -> Bool {
        // Apps can pause a session by switching its assertion off without releasing it.
        guard let assertionType = assertion[kIOPMAssertionTypeKey] as? String,
              let level = assertion[kIOPMAssertionLevelKey] as? Int,
              level == kIOPMAssertionLevelOn,
              let processPath else { return false }
        return keepAwakeTypes.contains(assertionType)
            && keepAwakeTools.contains(URL(filePath: processPath).lastPathComponent)
    }

    private static func processPath(_ pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    /// Seconds since the last keyboard, mouse or trackpad input.
    static var idleTime: TimeInterval {
        // An event type of ~0 means "any input".
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }
}
