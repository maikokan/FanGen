import Foundation

enum PreviewMode: String, Codable, CaseIterable, Identifiable {
    case live
    case onApply

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .live: return "Live Preview"
        case .onApply: return "On Apply"
        }
    }
}

struct PreviewSettings: Codable, Equatable {
    var mode: PreviewMode
    var livePreviewDelay: Double
    var autoRotate: Bool
    var rotationSpeed: Double

    init(
        mode: PreviewMode = .onApply,
        livePreviewDelay: Double = 0.3,
        autoRotate: Bool = true,
        rotationSpeed: Double = 0.5
    ) {
        self.mode = mode
        self.livePreviewDelay = livePreviewDelay
        self.autoRotate = autoRotate
        self.rotationSpeed = rotationSpeed
    }

    static let `default` = PreviewSettings()

    var isLivePreview: Bool {
        mode == .live
    }
}
