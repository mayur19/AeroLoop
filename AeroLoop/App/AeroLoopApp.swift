import AppIntents
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = SettingsManager.sharedDefaults
        let showInDock = defaults.bool(forKey: "aeroloop.showInDock")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }
}

@main
struct AeroLoopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState = AppState.shared
    @Environment(\.openWindow) private var openWindow
    
    init() {}

    var body: some Scene {

        // MARK: - Menu Bar

        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Label("AeroLoop", systemImage: "play.circle.fill")
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !appState.settings.hasCompletedOnboarding {
                            openWindow(id: "onboarding")
                            if #available(macOS 14.0, *) {
                                NSApp.activate()
                            } else {
                                NSApp.activate(ignoringOtherApps: true)
                            }
                        }
                    }
                }
        }
        .menuBarExtraStyle(.menu)

        // MARK: - Settings

        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // MARK: - Onboarding Window

        Window("Welcome to AeroLoop", id: "onboarding") {
            OnboardingView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .onAppear {
                    if let window = NSApp.windows.first(where: {
                        $0.identifier?.rawValue == "onboarding"
                    }) {
                        window.setContentSize(NSSize(width: 520, height: 600))
                        window.center()
                        window.titlebarAppearsTransparent = true
                        window.isMovableByWindowBackground = true
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 600)
        
        // MARK: - Library Window
        
        Window("AeroLoop Library", id: "library") {
            LibraryView()
                .environmentObject(appState)
                .environmentObject(appState.library)
                .environmentObject(appState.playlists)
                .preferredColorScheme(.dark)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    if let window = NSApp.windows.first(where: {
                        $0.identifier?.rawValue == "library"
                    }) {
                        window.titlebarAppearsTransparent = true
                        window.styleMask.insert(.fullSizeContentView)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 700)
    }
}
