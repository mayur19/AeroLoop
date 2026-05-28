import AVKit
import SwiftUI

/// A reusable video preview component with display mode selection and optional
/// apply action.
struct VideoPreviewView: View {

    let url: URL
    @Binding var displayMode: DisplayMode
    var onApply: ((WallpaperItem) -> Void)?

    @State private var player: AVPlayer?
    @State private var metadata: WallpaperItem?
    @State private var isLoadingMetadata = true

    var body: some View {
        VStack(spacing: 12) {
            // MARK: - Video Player

            if let player {
                VideoPlayer(player: player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(maxWidth: 460)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(maxWidth: 460)
                    .overlay {
                        ProgressView()
                    }
            }

            // MARK: - Metadata

            if isLoadingMetadata {
                ProgressView()
                    .controlSize(.small)
            } else if let metadata {
                HStack(spacing: 8) {
                    Label(metadata.resolutionFormatted, systemImage: "aspectratio")
                    Text("·").foregroundStyle(.tertiary)
                    Label(metadata.durationFormatted, systemImage: "clock")
                    Text("·").foregroundStyle(.tertiary)
                    Label(metadata.fileSizeFormatted, systemImage: "doc")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // MARK: - Display Mode Picker

            Picker("Display Mode", selection: $displayMode) {
                ForEach(DisplayMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280)

            // MARK: - Apply Button

            if let onApply {
                Button {
                    var item = metadata ?? WallpaperItem(url: url)
                    item.displayMode = displayMode
                    onApply(item)
                } label: {
                    Text("Apply Wallpaper")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: 240)
            }
        }
        .padding()
        .onAppear {
            loadPreview()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    // MARK: - Private

    private func loadPreview() {
        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = true
        avPlayer.play()
        player = avPlayer

        Task {
            let item = await VideoMetadataService.extractMetadata(from: url)
            metadata = item
            isLoadingMetadata = false
        }
    }
}
