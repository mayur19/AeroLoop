import Foundation

/// Defines the playback quality and performance trade-off.
enum QualityMode: String, CaseIterable, Codable, Identifiable {
    case eco
    case balanced
    case high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .eco: return "Eco"
        case .balanced: return "Balanced"
        case .high: return "High"
        }
    }

    var description: String {
        switch self {
        case .eco: return "Maximum battery life, reduced frame rate"
        case .balanced: return "Good quality with reasonable battery use"
        case .high: return "Maximum smoothness and quality"
        }
    }

    var systemImage: String {
        switch self {
        case .eco: return "leaf.fill"
        case .balanced: return "speedometer"
        case .high: return "bolt.fill"
        }
    }

    /// Target playback frame rate for this quality tier.
    var targetFPS: Float {
        switch self {
        case .eco: return 15
        case .balanced: return 30
        case .high: return 60
        }
    }
}
