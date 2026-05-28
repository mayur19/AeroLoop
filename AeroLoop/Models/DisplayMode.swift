import AVFoundation
import Foundation

/// Defines how a video wallpaper is scaled to fit the display.
enum DisplayMode: String, CaseIterable, Codable, Identifiable {
    case fill
    case fit
    case stretch

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fill: return "Fill"
        case .fit: return "Fit"
        case .stretch: return "Stretch"
        }
    }

    var description: String {
        switch self {
        case .fill: return "Fills the screen, cropping edges if needed"
        case .fit: return "Fits within the screen, may show black bars"
        case .stretch: return "Stretches to fill, may distort the image"
        }
    }

    var systemImage: String {
        switch self {
        case .fill: return "arrow.up.left.and.arrow.down.right"
        case .fit: return "arrow.down.right.and.arrow.up.left"
        case .stretch: return "arrow.left.and.right"
        }
    }

    /// Maps to AVPlayerLayer video gravity for rendering.
    var avLayerVideoGravity: AVLayerVideoGravity {
        switch self {
        case .fill: return .resizeAspectFill
        case .fit: return .resizeAspect
        case .stretch: return .resize
        }
    }
}
