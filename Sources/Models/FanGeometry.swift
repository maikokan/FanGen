import Foundation

enum RotationDirection: String, Codable, CaseIterable, Identifiable {
    case clockwise = "CW"
    case counterClockwise = "CCW"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clockwise: return "Clockwise"
        case .counterClockwise: return "Counter-Clockwise"
        }
    }

    var isClockwise: Bool {
        self == .clockwise
    }
}

enum TwistDistribution: String, Codable, CaseIterable, Identifiable {
    case constant
    case linear
    case variable

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .constant: return "Constant"
        case .linear: return "Linear"
        case .variable: return "Variable (per station)"
        }
    }
}

struct FanGeometry: Codable, Equatable {
    var bladeCount: Int
    var hub: HubParameters
    var bladeRadius: Double
    var pitchAngle: Double
    var rotationDirection: RotationDirection
    var twistDistribution: TwistDistribution
    var stations: [BladeStation]

    init(
        bladeCount: Int = 5,
        hub: HubParameters = HubParameters.default,
        bladeRadius: Double = 100.0,
        pitchAngle: Double = 25.0,
        rotationDirection: RotationDirection = .clockwise,
        twistDistribution: TwistDistribution = .linear,
        stations: [BladeStation] = BladeStation.defaultStations()
    ) {
        self.bladeCount = bladeCount
        self.hub = hub
        self.bladeRadius = bladeRadius
        self.pitchAngle = pitchAngle
        self.rotationDirection = rotationDirection
        self.twistDistribution = twistDistribution
        self.stations = stations
    }

    var bladeLength: Double {
        bladeRadius - hub.radius
    }

    var innerRadius: Double {
        hub.radius
    }

    var outerRadius: Double {
        bladeRadius
    }

    var pitchDirection: Double {
        rotationDirection == .clockwise ? 1.0 : -1.0
    }

    mutating func addStation(at radius: Double) {
        let interpolated = interpolateStation(at: radius)
        stations.append(interpolated)
        stations.sort { $0.radius < $1.radius }
    }

    mutating func removeStation(at index: Int) {
        guard stations.count > 2, index >= 0, index < stations.count else { return }
        stations.remove(at: index)
    }

    private func interpolateStation(at radius: Double) -> BladeStation {
        let sorted = stations.sorted { $0.radius < $1.radius }

        guard let lower = sorted.last(where: { $0.radius <= radius }),
              let upper = sorted.first(where: { $0.radius >= radius }) else {
            return BladeStation(radius: radius, chord: 30, pitch: pitchAngle, thickness: 6, profile: .simple(.tapered))
        }

        if lower.radius == upper.radius || lower.radius == radius {
            return BladeStation(
                radius: radius,
                chord: lower.chord,
                pitch: lower.pitch,
                thickness: lower.thickness,
                profile: lower.profile
            )
        }

        let t = (radius - lower.radius) / (upper.radius - lower.radius)
        let chord = lower.chord + (upper.chord - lower.chord) * t
        let pitch = lower.pitch + (upper.pitch - lower.pitch) * t
        let thickness = lower.thickness + (upper.thickness - lower.thickness) * t

        return BladeStation(
            radius: radius,
            chord: chord,
            pitch: pitch,
            thickness: thickness,
            profile: lower.profile
        )
    }

    static let `default` = FanGeometry()

    static var bladeCountRange: ClosedRange<Int> { 2...9 }
    static var bladeRadiusRange: ClosedRange<Double> { 50...200 }
    static var pitchAngleRange: ClosedRange<Double> { 0...60 }
}