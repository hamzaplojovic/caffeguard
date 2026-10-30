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
    /// macOS's own daemons hold keep-awake assertions routinely (powerd does whenever the
    /// display is on), so only programs outside these folders count. /usr/bin, where
    /// `caffeinate` lives, is deliberately not one of them.
    private static let systemFolders = ["/System/Library/", "/usr/libexec/", "/usr/sbin/", "/Library/Apple/"]

    /// Detects active power assertions, including those owned by a wrapper's caffeinate child.
    /// Supports Amphetamine, KeepingYouAwake, Lungo, Theine, Caffeinated and Raycast Coffee
    /// without relying on an app's name or installation location.
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
        return keepAwakeTypes.contains(assertionType) && !systemFolders.contains { processPath.hasPrefix($0) }
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
