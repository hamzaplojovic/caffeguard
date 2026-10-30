import AppKit
import LocalAuthentication
import SwiftUI

/// Covers every display, above the menu bar and full-screen apps, until the owner unlocks it
/// with Touch ID or the Mac's password, or logs back in after the Mac was locked.
final class IntrusionAlert {
    var onUnlock: () -> Void = {}
    var isShowing: Bool { !windows.isEmpty }

    private var windows: [NSWindow] = []
    private var previousApp: NSRunningApplication?
    private var isAuthenticating = false
    private var alarm: NSSound?

    init() {
        // Logging back in to a locked Mac proves it is the owner, so that unlocks the alert too.
        DistributedNotificationCenter.default().addObserver(
            forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.finish() }
        }
    }

    func show() {
        guard windows.isEmpty else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        let configuration = IntrusionScreenConfiguration(defaults: .standard)
        let wallpaper = Wallpaper.image
        windows = NSScreen.screens.map { screen in
            let window = IntrusionAlertWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.unlockTrigger = configuration.unlockTrigger
            window.onUnlockRequest = { [weak self] in self?.unlock() }
            window.contentView = NSHostingView(rootView: IntrusionAlertView(configuration: configuration, wallpaper: wallpaper))
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            return window
        }
        bringToFront()
        if UserDefaults.standard.bool(forKey: Preference.alarmSound) {
            alarm = NSSound(named: "Sosumi")
            alarm?.loops = true
            alarm?.play()
        }
    }

    private func unlock() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        // The system Touch ID / password prompt shares the screen saver level; drop just below it.
        windows.forEach { $0.level = NSWindow.Level(NSWindow.Level.screenSaver.rawValue - 1) }
        Task {
            // Touch ID when the Mac has it, otherwise (or after a failed finger) the login password.
            let unlocked = (try? await LAContext().evaluatePolicy(
                .deviceOwnerAuthentication, localizedReason: "dismiss the intrusion alert"
            )) ?? false
            isAuthenticating = false
            if unlocked {
                finish()
            } else {
                windows.forEach { $0.level = .screenSaver }
                bringToFront()
            }
        }
    }

    private func bringToFront() {
        NSApp.activate()
        windows.first?.makeKey()
    }

    private func finish() {
        guard isShowing else { return }
        alarm?.stop()
        alarm = nil
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        // Otherwise macOS hands focus to Finder when our last window closes.
        previousApp?.activate()
        previousApp = nil
        onUnlock()
    }
}

/// Routes input before the hosting view can consume it. Input only requests authentication.
final class IntrusionAlertWindow: NSWindow {
    var unlockTrigger: IntrusionUnlockTrigger = .doubleClickOrAnyKey
    var onUnlockRequest: () -> Void = {}
    override var canBecomeKey: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            if !event.isARepeat, unlockTrigger.accepts(.keyPress) { onUnlockRequest() }
            return
        }
        if event.type == .leftMouseDown, event.clickCount == 2 {
            if unlockTrigger.accepts(.doubleClick) { onUnlockRequest() }
            return
        }
        super.sendEvent(event)
    }
}
