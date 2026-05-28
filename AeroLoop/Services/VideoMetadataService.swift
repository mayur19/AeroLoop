import AppKit
import AVFoundation
import CoreGraphics
import Foundation

/// Extracts metadata and thumbnails from video files using AVFoundation.
struct VideoMetadataService {

    // MARK: - Durable Imports

    /// Securely copies the selected video file to the App Group Library directory.
    static func importVideoToLibrary(url: URL) async throws -> URL {
        let fm = FileManager.default
        let libraryURL = SharedPaths.libraryURL

        try SharedPaths.ensureDirectoryExists(at: libraryURL)

        let destURL = libraryURL.appendingPathComponent(url.lastPathComponent)

        // If the file already exists in our library, just return it.
        if fm.fileExists(atPath: destURL.path) {
            return destURL
        }

        try fm.copyItem(at: url, to: destURL)
        return destURL
    }

    // MARK: - Metadata Extraction

    /// Extracts metadata from a video file and returns a populated `WallpaperItem`.
    static func extractMetadata(from url: URL) async -> WallpaperItem {
        let asset = AVAsset(url: url)

        // Load duration
        var duration: TimeInterval = 0
        if let cmDuration = try? await asset.load(.duration) {
            duration = CMTimeGetSeconds(cmDuration)
        }

        // Load resolution from the first video track
        let resolution = await loadResolution(asset: asset)

        // File size
        let fileSize: Int64 = {
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attrs[.size] as? Int64 else { return 0 }
            return size
        }()

        return WallpaperItem(
            url: url,
            title: url.deletingPathExtension().lastPathComponent,
            duration: duration,
            resolution: resolution,
            fileSize: fileSize
        )
    }

    // MARK: - Thumbnail Generation

    /// Generates or retrieves a cached thumbnail image from the video.
    static func generateThumbnail(
        from url: URL,
        at time: CMTime = CMTime(seconds: 1, preferredTimescale: 600)
    ) async -> NSImage? {
        let fm = FileManager.default
        let cacheDir = SharedPaths.thumbnailsURL

        try? SharedPaths.ensureDirectoryExists(at: cacheDir)

        let cacheFile = cacheDir.appendingPathComponent("\(url.deletingPathExtension().lastPathComponent).jpg")

        // 1. Check cache
        if fm.fileExists(atPath: cacheFile.path) {
            if let img = NSImage(contentsOf: cacheFile) {
                return img
            }
        }

        // 2. Generate
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)

        do {
            let (cgImage, _) = try await generator.image(at: time)
            let nsImage = NSImage(
                cgImage: cgImage,
                size: NSSize(width: cgImage.width, height: cgImage.height)
            )

            // 3. Save to cache
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            if let jpegData = bitmapRep.representation(using: .jpeg, properties: [:]) {
                try? jpegData.write(to: cacheFile)
            }

            return nsImage
        } catch {
            print("[VideoMetadataService] Thumbnail generation failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private Helpers

    /// Loads the video resolution accounting for track transform (rotation).
    private static func loadResolution(asset: AVAsset) async -> CGSize {
        guard let tracks = try? await asset.loadTracks(withMediaType: .video),
              let track = tracks.first else {
            return .zero
        }

        guard let naturalSize = try? await track.load(.naturalSize),
              let preferredTransform = try? await track.load(.preferredTransform) else {
            return .zero
        }

        // Apply the preferred transform to get the correct orientation
        let transformedSize = naturalSize.applying(preferredTransform)
        return CGSize(
            width: abs(transformedSize.width),
            height: abs(transformedSize.height)
        )
    }
}
