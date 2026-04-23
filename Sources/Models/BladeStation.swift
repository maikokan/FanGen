import Foundation

struct BladeStation: Identifiable, Codable, Equatable {
    var id: UUID
    var radius: Double
    var chord: Double
    var pitch: Double
    var thickness: Double
    var profile: StationProfile

    init(
        id: UUID = UUID(),
        radius: Double,
        chord: Double,
        pitch: Double,
        thickness: Double,
        profile: StationProfile
    ) {
        self.id = id
        self.radius = radius
        self.chord = chord
        self.pitch = pitch
        self.thickness = thickness
        self.profile = profile
    }

    var radiusPercentage: Double {
        radius * 100.0
    }

    var displayName: String {
        if radius <= 0.001 { return "Hub" }
        if radius >= 0.999 { return "Tip" }
        return "\(Int(radiusPercentage))%"
    }

    static func defaultStations() -> [BladeStation] {
        [
            BladeStation(radius: 0.0, chord: 40, pitch: 25, thickness: 8, profile: .simple(.tapered)),
            BladeStation(radius: 0.5, chord: 35, pitch: 20, thickness: 6, profile: .simple(.tapered)),
            BladeStation(radius: 1.0, chord: 25, pitch: 15, thickness: 4, profile: .simple(.tapered))
        ]
    }
}

extension BladeStation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
