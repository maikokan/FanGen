import Foundation

enum StationProfile: Codable, Equatable {
    case simple(SimpleShape)
    case naca(NACAProfile)

    var displayName: String {
        switch self {
        case .simple(let shape):
            return shape.displayName
        case .naca(let profile):
            return "NACA \(profile.code)"
        }
    }

    var isSimple: Bool {
        if case .simple = self { return true }
        return false
    }

    var isNACA: Bool {
        if case .naca = self { return true }
        return false
    }
}