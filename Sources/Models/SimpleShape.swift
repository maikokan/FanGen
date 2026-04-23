import Foundation

enum SimpleShape: String, Codable, CaseIterable, Identifiable {
    case rectangular
    case tapered
    case curved

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rectangular: return "Rectangular"
        case .tapered: return "Tapered"
        case .curved: return "Curved"
        }
    }
}
