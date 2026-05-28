import AVKit
import SwiftUI
import UniformTypeIdentifiers

/// Multi-step onboarding flow shown to first-time users.
struct OnboardingView: View {

    @EnvironmentObject var appState: AppState

    @State private var currentStep = 0
    @State private var selectedVideoURL: URL?
    @State private var selectedItem: WallpaperItem?
    @State private var displayMode: DisplayMode = .fill
    @State private var isFilePickerPresented = false
    @State private var launchAtLogin = true
    @State private var batterySaver = true

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: promiseStep
                case 2: pickWallpaperStep
                case 3: previewStep
                case 4: doneStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.35), value: currentStep)

            // Navigation controls
            navigationBar
        }
        .frame(width: 520, height: 600)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .ignoresSafeArea(.all, edges: .top)
        .alert(item: $appState.appError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .purple.opacity(0.4), radius: 20, y: 8)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
            }

            Text("AeroLoop")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)

            Text("Bring motion to your Mac desktop.")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    // MARK: - Step 2: Promise

    private var promiseStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Free forever.\nLocal forever.\nOpen source.")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 14) {
                promiseBullet(icon: "person.crop.circle.badge.checkmark", text: "No account required")
                promiseBullet(icon: "eye.slash.fill", text: "No ads or tracking")
                promiseBullet(icon: "internaldrive", text: "Your videos stay on your Mac")
                promiseBullet(icon: "chevron.left.forwardslash.chevron.right", text: "Core engine is open source")
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    // MARK: - Step 3: Pick Wallpaper

    private var pickWallpaperStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Choose your first wallpaper")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)

            Text("Pick a video from your Mac, or browse the gallery.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                // Choose My Video button
                Button {
                    isFilePickerPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Choose My Video")
                                .fontWeight(.medium)
                            Text("MP4, MOV, or M4V")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: 280)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .fileImporter(
                    isPresented: $isFilePickerPresented,
                    allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
                    allowsMultipleSelection: false
                ) { result in
                    handleFileImport(result)
                }

                // Browse Gallery button
                Button {
                    NSWorkspace.shared.open(URL(string: "https://coverr.co/")!)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "safari")
                            .font(.system(size: 24))
                        Text("Browse Free Gallery")
                            .font(.headline)
                        Text("Find free looping videos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: 280)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if let selectedItem {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(selectedItem.title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.callout)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Step 4: Preview & Apply

    private var previewStep: some View {
        VStack(spacing: 16) {
            if let url = selectedVideoURL {
                Text("Preview & Apply")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                    .padding(.top, 16)

                VideoPreviewView(
                    url: url,
                    displayMode: $displayMode,
                    onApply: { item in
                        var updated = item
                        updated.displayMode = displayMode
                        appState.applyWallpaper(updated)
                        withAnimation { currentStep = 4 }
                    }
                )
            } else {
                Spacer()

                Image(systemName: "arrow.left.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("No video selected")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("Go back and choose a video first.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.tertiary)

                Spacer()
            }
        }
        .padding()
    }

    // MARK: - Step 5: Done

    private var doneStep: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.green.gradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: .green.opacity(0.3), radius: 16, y: 6)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .transition(.scale.combined(with: .opacity))

            Text("Your desktop is alive!")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Battery Saver", isOn: $batterySaver)
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 8)

            HStack(spacing: 6) {
                Text("Find AeroLoop in your menu bar")
                Image(systemName: "arrow.up.right")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.top, 4)

            Spacer()

            Button {
                finishOnboarding()
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 24)
        }
        .padding()
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // Back button
            if currentStep > 0 && currentStep < totalSteps - 1 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Step indicators
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut, value: currentStep)
                }
            }

            Spacer()

            // Continue button (only on steps 0, 1; step 2 advances via file pick or manually)
            if currentStep < 2 {
                Button("Continue") {
                    withAnimation { currentStep += 1 }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            } else if currentStep == 2 {
                Button("Continue") {
                    withAnimation { currentStep += 1 }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            } else {
                // Steps 3 & 4 handle their own navigation
                Color.clear.frame(width: 80)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func promiseBullet(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }

        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }

        Task {
            do {
                let durableURL = try await VideoMetadataService.importVideoToLibrary(url: url)
                selectedVideoURL = durableURL
                let item = await VideoMetadataService.extractMetadata(from: durableURL)
                selectedItem = item
                _ = await VideoMetadataService.generateThumbnail(from: durableURL)
                withAnimation { currentStep = 3 }
            } catch {
                appState.appError = AppState.AppError(message: "Failed to import video: \(error.localizedDescription)")
            }
        }
    }

    private func finishOnboarding() {
        // Persist user choices.
        appState.settings.setLaunchAtLogin(launchAtLogin)
        appState.settings.pauseOnBattery = batterySaver
        appState.settings.hasCompletedOnboarding = true

        // Close the onboarding window.
        if let window = NSApp.windows.first(where: {
            $0.title.contains("Welcome") || $0.identifier?.rawValue == "onboarding"
        }) {
            window.close()
        }
    }
}
