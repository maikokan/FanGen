import Foundation
import Combine

enum OpenSCADError: LocalizedError {
    case notInstalled
    case generationFailed(String)
    case timeout
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "OpenSCAD is not installed. Please download from https://openscad.org"
        case .generationFailed(let message):
            return "STL generation failed: \(message)"
        case .timeout:
            return "STL generation timed out after 10 seconds"
        case .invalidOutput:
            return "Generated STL file is invalid or empty"
        }
    }
}

@MainActor
class OpenSCADController: ObservableObject {
    @Published var isInstalled: Bool = false
    @Published var isGenerating: Bool = false
    @Published var lastError: String?

    private let openSCADPaths = [
        "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
        "/usr/local/bin/openscad",
        "/opt/homebrew/bin/openscad"
    ]

    init() {
        checkInstallation()
    }

    func checkInstallation() {
        for path in openSCADPaths {
            if FileManager.default.fileExists(atPath: path) {
                isInstalled = true
                return
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["openscad"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            isInstalled = process.terminationStatus == 0
        } catch {
            isInstalled = false
        }
    }

    func generateSTL(
        from geometry: FanGeometry,
        script: String
    ) async throws -> URL {
        guard isInstalled else {
            throw OpenSCADError.notInstalled
        }

        isGenerating = true
        lastError = nil

        defer { isGenerating = false }

        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("fan_temp_\(UUID().uuidString).scad")
        let outputURL = tempDir.appendingPathComponent("fan_output_\(UUID().uuidString).stl")

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)

            let result = try await runOpenSCAD(script: scriptURL, output: outputURL)

            if !result.success {
                throw OpenSCADError.generationFailed(result.error ?? "Unknown error")
            }

            let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
            if let size = attributes[.size] as? Int, size == 0 {
                throw OpenSCADError.invalidOutput
            }

            try? FileManager.default.removeItem(at: scriptURL)

            return outputURL
        } catch {
            try? FileManager.default.removeItem(at: scriptURL)
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }
    }

    private func runOpenSCAD(script: URL, output: URL) async throws -> (success: Bool, error: String?) {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: openSCADPaths.first { FileManager.default.fileExists(atPath: $0) } ?? "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD")
            process.arguments = ["-o", output.path, script.path]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            var timedOut = false
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if !Task.isCancelled {
                    timedOut = true
                    process.terminate()
                }
            }

            process.terminationHandler = { proc in
                timeoutTask.cancel()
                let success = proc.terminationStatus == 0 && !timedOut

                var errorMessage: String? = nil
                if !success {
                    let errorData = errorPipe.fileHandleForReading.availableData
                    errorMessage = String(data: errorData, encoding: .utf8)
                }

                continuation.resume(returning: (success, errorMessage))
            }

            do {
                try process.run()
            } catch {
                timeoutTask.cancel()
                continuation.resume(throwing: error)
            }
        }
    }
}
