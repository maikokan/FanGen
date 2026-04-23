import Foundation
import SceneKit

enum STLExportError: LocalizedError {
    case invalidMesh
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidMesh:
            return "The mesh is invalid or empty"
        case .writeFailed(let message):
            return "Failed to write STL file: \(message)"
        }
    }
}

class STLExporter {
    static let shared = STLExporter()

    private init() {}

    func export(
        mesh: SCNGeometry,
        format: ExportFormat,
        to url: URL
    ) throws {
        let vertexData = extractVertexData(from: mesh)

        guard !vertexData.isEmpty else {
            throw STLExportError.invalidMesh
        }

        switch format {
        case .binary:
            try writeBinarySTL(vertices: vertexData, to: url)
        case .ascii:
            try writeASCIISTL(vertices: vertexData, to: url)
        }
    }

    private func extractVertexData(from geometry: SCNGeometry) -> [SCNVector3] {
        var vertices: [SCNVector3] = []

        for source in geometry.sources {
            if source.semantic == .vertex {
                if let data = source.data as Data? {
                    let stride = source.bytesPerComponent * source.componentsPerCoordinate

                    data.withUnsafeBytes { buffer in
                        var offset = 0
                        while offset < buffer.count {
                            let x = buffer.load(fromByteOffset: offset, as: Float.self)
                            let y = buffer.load(fromByteOffset: offset + 4, as: Float.self)
                            let z = buffer.load(fromByteOffset: offset + 8, as: Float.self)
                            vertices.append(SCNVector3(x: x, y: y, z: z))
                            offset += stride
                        }
                    }
                }
            }
        }

        return vertices
    }

    private func writeBinarySTL(vertices: [SCNVector3], to url: URL) throws {
        var data = Data()

        var header = [UInt8](repeating: 0, count: 80)
        let headerString = "FanGen STL Export"
        for (i, char) in headerString.utf8.prefix(80).enumerated() {
            header[i] = char
        }
        data.append(contentsOf: header)

        var triangleCount = UInt32(vertices.count / 9)
        data.append(contentsOf: withUnsafeBytes(of: &triangleCount) { Array($0) })

        for i in stride(from: 0, to: vertices.count, by: 9) {
            let v1 = vertices[i]
            let v2 = vertices[i + 1]
            let v3 = vertices[i + 2]

            let (nx, ny, nz) = calculateNormal(v1: v1, v2: v2, v3: v3)

            var normal = Float(nx)
            data.append(contentsOf: withUnsafeBytes(of: &normal) { Array($0) })
            var normalY = Float(ny)
            data.append(contentsOf: withUnsafeBytes(of: &normalY) { Array($0) })
            var normalZ = Float(nz)
            data.append(contentsOf: withUnsafeBytes(of: &normalZ) { Array($0) })

            for vertex in [v1, v2, v3] {
                var x = Float(vertex.x)
                var y = Float(vertex.y)
                var z = Float(vertex.z)
                data.append(contentsOf: withUnsafeBytes(of: &x) { Array($0) })
                data.append(contentsOf: withUnsafeBytes(of: &y) { Array($0) })
                data.append(contentsOf: withUnsafeBytes(of: &z) { Array($0) })
            }

            var attribute = UInt16(0)
            data.append(contentsOf: withUnsafeBytes(of: &attribute) { Array($0) })
        }

        do {
            try data.write(to: url)
        } catch {
            throw STLExportError.writeFailed(error.localizedDescription)
        }
    }

    private func writeASCIISTL(vertices: [SCNVector3], to url: URL) throws {
        var output = "solid fan\n"

        for i in stride(from: 0, to: vertices.count, by: 9) {
            let v1 = vertices[i]
            let v2 = vertices[i + 1]
            let v3 = vertices[i + 2]

            let (nx, ny, nz) = calculateNormal(v1: v1, v2: v2, v3: v3)

            output += "  facet normal \(nx) \(ny) \(nz)\n"
            output += "    outer loop\n"
            output += "      vertex \(v1.x) \(v1.y) \(v1.z)\n"
            output += "      vertex \(v2.x) \(v2.y) \(v2.z)\n"
            output += "      vertex \(v3.x) \(v3.y) \(v3.z)\n"
            output += "    endloop\n"
            output += "  endfacet\n"
        }

        output += "endsolid fan\n"

        do {
            try output.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw STLExportError.writeFailed(error.localizedDescription)
        }
    }

    private func calculateNormal(v1: SCNVector3, v2: SCNVector3, v3: SCNVector3) -> (Double, Double, Double) {
        let ux = v2.x - v1.x
        let uy = v2.y - v1.y
        let uz = v2.z - v1.z

        let vx = v3.x - v1.x
        let vy = v3.y - v1.y
        let vz = v3.z - v1.z

        let nx = uy * vz - uz * vy
        let ny = uz * vx - ux * vz
        let nz = ux * vy - uy * vx

        let length = sqrt(nx * nx + ny * ny + nz * nz)
        guard length > 0 else { return (0, 0, 1) }

        return (nx / length, ny / length, nz / length)
    }
}
