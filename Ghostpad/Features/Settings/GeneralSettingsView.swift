import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var settings: SettingsStore
    let permissions: PermissionMonitor

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private let timeouts: [(String, TimeInterval)] = [("15 seconds", 15), ("30 seconds", 30), ("1 minute", 60), ("2 minutes", 120), ("5 minutes", 300)]

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
            }
            Section {
                Picker("Close keypad after", selection: $settings.inactivityTimeout) {
                    ForEach(timeouts, id: \.1) { title, value in
                        Text(title).tag(value)
                    }
                }
            } footer: {
                Text("Swipe two fingers back toward the left edge or press Esc to close the keypad at any time.")
            }
            Section {
                LabeledContent("Accessibility") {
                    if permissions.isTrusted {
                        Text("Allowed")
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Open System Settings") {
                            permissions.openSystemSettings()
                        }
                    }
                }
            } footer: {
                Text("Ghostpad uses Accessibility to pause the pointer and type keys while the keypad is open.")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            permissions.refresh()
        }
        .onChange(of: launchAtLogin) { _, enabled in
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }
}
