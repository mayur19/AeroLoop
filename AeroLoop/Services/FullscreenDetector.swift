import AppKit
import Combine

/// Monitors for fullscreen apps to allow pausing the wallpaper to save battery and GPU.
@MainActor
final class FullscreenDetector: ObservableObject {
    @Published var isFullscreenActive: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var checkTimer: Timer?

    func startMonitoring() {
        // Monitor space changes (entering/exiting native fullscreen spaces)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkFullscreenStatus()
            }
            .store(in: &cancellables)

        // Monitor app activation changes
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkFullscreenStatus()
            }
            .store(in: &cancellables)

        // Fallback polling
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkFullscreenStatus()
            }
        }
    }

    func stopMonitoring() {
        cancellables.removeAll()
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func checkFullscreenStatus() {
        // Check if any screen's visible frame differs significantly from its full frame,
        // indicating a fullscreen app is covering the menu bar.
        // When a native fullscreen app is active on a display, the menu bar is hidden
        // and the visible frame equals the full frame on that display.
        // We also check the frontmost app's presentation options.
        let frontmostApp = NSWorkspace.shared.frontmostApplication

        // If AeroLoop itself is frontmost, don't consider it fullscreen
        if frontmostApp?.bundleIdentifier == Bundle.main.bundleIdentifier {
            if isFullscreenActive {
                isFullscreenActive = false
            }
            return
        }

        // Check if the frontmost app has a fullscreen presentation by examining screens.
        // In macOS, when an app enters native fullscreen, it creates its own Space.
        // We detect this by checking if the menu bar is auto-hidden on the main screen.
        var foundFullscreen = false

        if let mainScreen = NSScreen.main {
            // When a fullscreen app is active, the visible frame equals the full frame
            // because the menu bar is hidden. Normally visible frame is smaller due to menu bar.
            let fullFrame = mainScreen.frame
            let visibleFrame = mainScreen.visibleFrame

            // If the visible frame height equals the full frame height (no menu bar),
            // a fullscreen app is likely active
            let menuBarHeight = fullFrame.height - visibleFrame.height - visibleFrame.origin.y + fullFrame.origin.y
            if menuBarHeight < 1 {
                foundFullscreen = true
            }
        }

        if isFullscreenActive != foundFullscreen {
            isFullscreenActive = foundFullscreen
        }
    }
}
