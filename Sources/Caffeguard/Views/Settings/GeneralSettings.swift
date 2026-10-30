import AVFoundation
import ServiceManagement
import SwiftUI

struct GeneralSettings: View {
    @AppStorage(Preference.cameraID) private var cameraID: String?
    @AppStorage(Preference.photoFolderPath) private var photoFolderPath = ""
    @AppStorage(Preference.idleSeconds) private var idleSeconds = Preference.defaultIdleSeconds
    @State private var isCustom = false
    @State private var opensAtLogin = SMAppService.mainApp.status

    private static let custom = -1

    var body: some View {
        Form {
            Section {
                Toggle("Open at Login", isOn: Binding {
                    opensAtLogin == .enabled
                } set: { on in
                    try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    opensAtLogin = SMAppService.mainApp.status
                })
            } footer: {
                if opensAtLogin == .requiresApproval {
                    Button("Allow Caffeguard in Login Items…", action: SMAppService.openSystemSettingsLoginItems)
                        .buttonStyle(.link)
                }
            }

            Section {
                CameraPicker(selection: $cameraID)
                    // Covers choosing a camera here after skipping the welcome window.
                    .onChange(of: cameraID) { Task { await AVCaptureDevice.requestAccess(for: .video) } }
            } footer: {
                Text("iPhone cameras are never used.")
            }

            Section {
                Picker("Arm after", selection: idleChoice) {
                    ForEach(Preference.idleChoices, id: \.self) { seconds in
                        Text(Self.label(seconds)).tag(seconds)
                    }
                    Divider()
                    Text("Custom").tag(Self.custom)
                }
                if isCustom {
                    LabeledContent("Seconds") {
                        HStack {
                            TextField("Seconds", value: $idleSeconds, format: .number)
                                .labelsHidden()
                                .multilineTextAlignment(.trailing)
                                .frame(width: 64)
                            Stepper("Seconds", value: $idleSeconds, in: 1...86_400)
                                .labelsHidden()
                        }
                    }
                }
            } footer: {
                Text("Caffeguard arms while something keeps your Mac awake, like caffeinate or Amphetamine, and it has had no input for this long.")
            }
            Section {
                LabeledContent("Save photos to") {
                    Text(verbatim: photoFolderPath.isEmpty ? Evidence.defaultFolder.path : photoFolderPath)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .help(photoFolderPath.isEmpty ? Evidence.defaultFolder.path : photoFolderPath)
                }
                HStack {
                    Button("Choose Folder…", action: choosePhotoFolder)
                    Spacer()
                    Button("Use Default") { photoFolderPath = "" }
                        .disabled(photoFolderPath.isEmpty)
                }
            } header: {
                Text("Photos")
            } footer: {
                Text("New photos are saved here. Existing photos stay in their original folder.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize()
        .onAppear { isCustom = !Preference.idleChoices.contains(idleSeconds) }
    }

    private func choosePhotoFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Photo Folder"
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = Evidence.folder()
        if panel.runModal() == .OK, let folder = panel.url {
            photoFolderPath = folder.path
        }
    }

    private var idleChoice: Binding<Int> {
        Binding {
            isCustom ? Self.custom : idleSeconds
        } set: { choice in
            isCustom = choice == Self.custom
            if !isCustom { idleSeconds = choice }
        }
    }

    private static func label(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .wide))
    }
}
