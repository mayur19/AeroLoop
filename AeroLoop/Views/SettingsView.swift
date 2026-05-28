import ServiceManagement
import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case playback = "Playback"
    case schedules = "Schedules"
    case battery = "Battery"
    case privacy = "Privacy"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .playback: return "play.circle"
        case .schedules: return "calendar"
        case .battery: return "battery.100"
        case .privacy: return "lock.shield"
        }
    }
}

/// Glassy settings window for AeroLoop preferences.
struct SettingsView: View {

    @EnvironmentObject var appState: AppState
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            // Glass Custom Segmented Picker Toolbar
            HStack(spacing: 12) {
                ForEach(SettingsTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .frame(width: 80, height: 50)
                        .foregroundStyle(selectedTab == tab ? .white : .secondary)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .matchedGeometryEffect(id: "TabBackground", in: animationNamespace)

                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            }
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider().opacity(0.5)

            // Content Area
            Group {
                switch selectedTab {
                case .general:
                    GeneralTab(settings: appState.settings)
                case .playback:
                    PlaybackTab(settings: appState.settings)
                case .schedules:
                    SchedulesTab(settings: appState.settings, playlists: appState.playlists)
                case .battery:
                    BatteryTab(settings: appState.settings, batteryMonitor: appState.batteryMonitor)
                case .privacy:
                    PrivacyTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 450)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        // Extend into title bar area
        .ignoresSafeArea(.all, edges: .top)
    }

    @Namespace private var animationNamespace
}

// MARK: - Schedules Tab

private struct SchedulesTab: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var playlists: PlaylistService

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GroupBox("Day & Night") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Automatically switch playlists based on your Mac's Light or Dark mode appearance.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Day Playlist:")
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: Binding(
                                get: { settings.dayPlaylistId ?? "" },
                                set: { settings.dayPlaylistId = $0.isEmpty ? nil : $0 }
                            )) {
                                Text("None").tag("")
                                ForEach(playlists.playlists, id: \.playlist.id) { pw in
                                    Text(pw.playlist.title).tag(pw.playlist.id.uuidString)
                                }
                            }
                            .labelsHidden()
                        }

                        HStack {
                            Text("Night Playlist:")
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: Binding(
                                get: { settings.nightPlaylistId ?? "" },
                                set: { settings.nightPlaylistId = $0.isEmpty ? nil : $0 }
                            )) {
                                Text("None").tag("")
                                ForEach(playlists.playlists, id: \.playlist.id) { pw in
                                    Text(pw.playlist.title).tag(pw.playlist.id.uuidString)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                    .padding(4)
                }

                GroupBox("Battery Saver") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Switch to a specific playlist (like low-framerate videos or static loops) when unplugged.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Battery Playlist:")
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: Binding(
                                get: { settings.batteryPlaylistId ?? "" },
                                set: { settings.batteryPlaylistId = $0.isEmpty ? nil : $0 }
                            )) {
                                Text("None").tag("")
                                ForEach(playlists.playlists, id: \.playlist.id) { pw in
                                    Text(pw.playlist.title).tag(pw.playlist.id.uuidString)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                    .padding(4)
                }
            }
            .padding()
        }
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GroupBox("Startup") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Launch AeroLoop at Login", isOn: Binding(
                            get: { settings.launchAtLogin },
                            set: { settings.setLaunchAtLogin($0) }
                        ))

                        Text("Appears in the menu bar when your Mac starts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                }

                GroupBox("Overlays") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show Clock on Desktop", isOn: $settings.showClockOverlay)

                        Text("Displays a minimal clock over your wallpaper.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                }

                GroupBox("Dock Behavior") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show App Icon in Dock", isOn: Binding(
                            get: { settings.showInDock },
                            set: { newValue in
                                settings.showInDock = newValue
                                NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                            }
                        ))

                        Text("When disabled, AeroLoop only appears in the menu bar.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                }

                GroupBox("Quality") {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Quality Mode", selection: Binding(
                            get: { settings.qualityMode },
                            set: { settings.qualityMode = $0 }
                        )) {
                            ForEach(QualityMode.allCases) { mode in
                                Label(mode.label, systemImage: mode.systemImage)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(settings.qualityMode.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .animation(.easeInOut, value: settings.qualityMode)
                    }
                    .padding(4)
                }

                GroupBox("Screen Saver") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Install the AeroLoop Screen Saver to play your active wallpaper when your Mac is idle.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Install Screen Saver...") {
                            installScreenSaver()
                        }
                    }
                    .padding(4)
                }
            }
            .padding()
        }
    }

    private func installScreenSaver() {
        guard let plugInsURL = Bundle.main.builtInPlugInsURL else { return }
        let saverURL = plugInsURL.appendingPathComponent("AeroLoopSaver.saver")
        let fm = FileManager.default

        guard fm.fileExists(atPath: saverURL.path) else {
            print("Screen saver not found in bundle at \(saverURL.path)")
            return
        }

        // Open the .saver file, which prompts macOS to install it via System Preferences
        NSWorkspace.shared.open(saverURL)
    }
}

// MARK: - Playback Tab

private struct PlaybackTab: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GroupBox("Display") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Sync all displays", isOn: Binding(
                            get: { settings.syncAllDisplays },
                            set: { settings.syncAllDisplays = $0 }
                        ))

                        Text("Apply the same wallpaper to every connected monitor.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Picker("Default Display Mode", selection: Binding(
                            get: { settings.displayMode },
                            set: { settings.displayMode = $0 }
                        )) {
                            ForEach(DisplayMode.allCases) { mode in
                                Label(mode.label, systemImage: mode.systemImage)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(settings.displayMode.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .animation(.easeInOut, value: settings.displayMode)
                    }
                    .padding(4)
                }

                GroupBox("Audio") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Mute Audio", isOn: Binding(
                            get: { settings.audioMuted },
                            set: { settings.audioMuted = $0 }
                        ))

                        Text("When enabled, wallpaper videos play silently.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                }
            }
            .padding()
        }
    }
}

// MARK: - Battery Tab

private struct BatteryTab: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var batteryMonitor: BatteryMonitor

    /// Simple heuristic: if the battery level is reported as 0 and not
    /// charging, assume this is a desktop Mac without a battery.
    private var isDesktopMac: Bool {
        batteryMonitor.batteryLevel <= 0 && !batteryMonitor.isCharging && !batteryMonitor.isOnBattery
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isDesktopMac {
                    GroupBox {
                        HStack {
                            Image(systemName: "desktopcomputer")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Battery options don't apply to desktop Macs.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(4)
                    }
                }

                GroupBox("Power Management") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Pause on Battery Power", isOn: Binding(
                            get: { settings.pauseOnBattery },
                            set: { settings.pauseOnBattery = $0 }
                        ))
                        .disabled(isDesktopMac)

                        Text("Automatically pause the live wallpaper when your Mac is not plugged in to save battery.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Toggle("Pause in Fullscreen Apps", isOn: Binding(
                            get: { settings.pauseInFullscreen },
                            set: { settings.pauseInFullscreen = $0 }
                        ))

                        Text("Pause playback when a fullscreen application is active to reduce resource usage.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                }
            }
            .padding()
        }
    }
}

// MARK: - Privacy Tab

private struct PrivacyTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green.gradient)

            Text("AeroLoop does not collect any data.")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                privacyBullet(
                    icon: "chart.bar.xaxis",
                    text: "No analytics or telemetry"
                )
                privacyBullet(
                    icon: "network.slash",
                    text: "No network requests — ever"
                )
                privacyBullet(
                    icon: "icloud.slash",
                    text: "No cloud storage or sync"
                )
                privacyBullet(
                    icon: "eye.slash",
                    text: "No tracking or fingerprinting"
                )
                privacyBullet(
                    icon: "externaldrive",
                    text: "Your videos stay on your Mac"
                )
            }
            .padding(.horizontal, 40)

            Divider()
                .frame(width: 200)

            Link(destination: URL(string: "https://aeroloop.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func privacyBullet(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
        }
    }
}
