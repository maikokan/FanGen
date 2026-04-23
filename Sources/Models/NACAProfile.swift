import Foundation

struct NACAProfile: Codable, Equatable {
    var code: String
    var angleOffset: Double

    init(code: String = "2412", angleOffset: Double = 0.0) {
        self.code = code
        self.angleOffset = angleOffset
    }

    var isValid: Bool {
        guard code.count == 4 else { return false }
        guard let _ = Int(code) else { return false }
        return true
    }

    var maxThickness: Double {
        let digits = Array(code)
        guard let m = Double(String(digits[0])),
              let p = Double(String(digits[1])),
              let t = Double(String(digits[2...3])) else { return 0 }
        return t / 100.0
    }

    var maxCamber: Double {
        let digits = Array(code)
        guard let m = Double(String(digits[0])) else { return 0 }
        return m / 100.0
    }

    var camberPosition: Double {
        let digits = Array(code)
        guard let p = Double(String(digits[1])) else { return 0 }
        return p / 10.0
    }
}
