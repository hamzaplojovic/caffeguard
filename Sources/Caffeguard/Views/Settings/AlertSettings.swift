import SwiftUI

/// Picks the theme and the optional wallpaper of the intrusion screen, with a live preview.
struct AlertSettings: View {
    @AppStorage(Preference.theme) private var themeID = Theme.all[0].id
    @AppStorage(Preference.intrusionMessage) private var intrusionMessage = ""
    @AppStorage(Preference.intrusionUnlockTrigger) private var intrusionUnlockTrigger = IntrusionUnlockTrigger.doubleClickOrAnyKey
    @State private var wallpaper = Wallpaper.image
    @State private var isChoosingWallpaper = false
    @State private var wallpaperError: String?
    @AppStorage(Preference.alarmSound) private var alarmSound = false
    @AppStorage(Preference.lockScreen) private var lockScreen = false

    private var theme: Theme { Theme.all.first { $0.id == themeID } ?? Theme.all[0] }

    var body: some View {
        Form {
            Section {
                IntrusionAlertView(configuration: IntrusionScreenConfiguration(
                    themeID: themeID, message: intrusionMessage, unlockTrigger: intrusionUnlockTrigger
                ), wallpaper: wallpaper)
                    .frame(width: 1440, height: 900)
                    .scaleEffect(0.29)
                    .frame(width: 418, height: 261)
                    .clipShape(.rect(cornerRadius: 8))
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity)

                Picker("Theme", selection: $themeID) {
                    ForEach(Theme.all) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
            }

            Section {
                TextField("Message", text: $intrusionMessage, prompt: Text(theme.message), axis: .vertical)
                    .lineLimit(2...4)
                Picker("Start verification", selection: $intrusionUnlockTrigger) {
                    ForEach(IntrusionUnlockTrigger.allCases) { trigger in
                        Text(trigger.title).tag(trigger)
                    }
                }
            } footer: {
                Text("Leave the message blank to use the theme’s message. Touch ID or your Mac password is required to dismiss the alert.")
            }

            Section {
                LabeledContent("Wallpaper") {
                    HStack {
                        if wallpaper != nil {
                            Button("Remove") {
                                Wallpaper.remove()
                                wallpaper = nil
                            }
                        }
                        Button(wallpaper == nil ? "Choose…" : "Change…") { isChoosingWallpaper = true }
                    }
                }
            } footer: {
                Text(wallpaperError ?? "Shown behind the theme’s text, tinted in its colors so the text stays readable.")
            }

            Section {
                Toggle("Play an alarm sound", isOn: $alarmSound)
                Toggle("Lock the Mac", isOn: $lockScreen)
            } header: {
                Text("When Someone Is Caught")
            } footer: {
                Text("The alarm plays until the screen is unlocked. Locking shows the login window 3 seconds after the photo; logging back in also dismisses the intrusion screen.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 680)
        .fileImporter(isPresented: $isChoosingWallpaper, allowedContentTypes: [.image]) { result in
            do {
                try Wallpaper.set(from: result.get())
                wallpaper = Wallpaper.image
                wallpaperError = nil
            } catch {
                wallpaperError = "That file could not be used as a wallpaper."
            }
        }
    }
}
