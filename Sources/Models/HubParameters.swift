import Foundation

struct HubParameters: Codable, Equatable {
    var radius: Double
    var height: Double
    var centerHole: Bool
    var holeDiameter: Double

    init(
        radius: Double = 15.0,
        height: Double = 10.0,
        centerHole: Bool = false,
        holeDiameter: Double = 5.0
    ) {
        self.radius = radius
        self.height = height
        self.centerHole = centerHole
        self.holeDiameter = holeDiameter
    }

    var outerDiameter: Double {
        radius * 2.0
    }

    var holeRadius: Double {
        holeDiameter / 2.0
    }

    static let `default` = HubParameters()
}

extension HubParameters {
    static var radiusRange: ClosedRange<Double> { 5...50 }
    static var heightRange: ClosedRange<Double> { 5...30 }
    static var holeDiameterRange: ClosedRange<Double> { 2...20 }
}
