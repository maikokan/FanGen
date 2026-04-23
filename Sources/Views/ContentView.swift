import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var openSCADController = OpenSCADController()
    @StateObject private var sceneController = SceneController()

    @State private var geometry = FanGeometry.default
    @State private var previewSettings = PreviewSettings.default

    @State private var currentSTLURL: URL?
    @State private var statusMessage = "Ready"
    @State private var showOpenSCADAlert = false

    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        HSplitView {
            ParameterPanel(
                geometry: $geometry,
                previewSettings: $previewSettings,
                onApply: generateFan,
                isGenerating: openSCADController.isGenerating
            )

            VStack(spacing: 0) {
                FanPreviewView(sceneController: sceneController)
                    .frame(minWidth: 400)

                statusBar
            }

            ExportPanel(
                geometry: geometry,
                onExport: exportSTL
            )
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkOpenSCAD()
        }
        .alert("OpenSCAD Required", isPresented: $showOpenSCADAlert) {
            Button("Download OpenSCAD") {
                NSWorkspace.shared.open(URL(string: "https://openscad.org/downloads.html")!)
            }
            Button("Quit", role: .cancel) {
                NSApplication.shared.terminate(nil)
            }
        } message: {
            Text("FanGen requires OpenSCAD to generate fan geometry. Please install OpenSCAD from openscad.org")
        }
    }

    private var statusBar: some View {
        HStack {
            Image(systemName: openSCADController.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(openSCADController.isInstalled ? .green : .red)

            Text(openSCADController.isInstalled ? "OpenSCAD: Found" : "OpenSCAD: Not Found")
                .font(.system(size: 11))

            Spacer()

            Text(statusMessage)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func checkOpenSCAD() {
        openSCADController.checkInstallation()

        if !openSCADController.isInstalled {
            showOpenSCADAlert = true
        }
    }

    private func generateFan() {
        debounceTask?.cancel()

        openSCADController.isGenerating = true
        statusMessage = "Generating..."

        let script = GeometryGenerator.shared.generateScript(from: geometry)

        Task {
            do {
                let stlURL = try await openSCADController.generateSTL(from: geometry, script: script)

                await MainActor.run {
                    currentSTLURL = stlURL

                    do {
                        try sceneController.loadMesh(from: stlURL)

                        if previewSettings.autoRotate {
                            sceneController.startAutoRotation(speed: previewSettings.rotationSpeed)
                        }

                        statusMessage = "Generated successfully"
                    } catch {
                        statusMessage = "Preview failed: \(error.localizedDescription)"
                    }

                    openSCADController.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Error: \(error.localizedDescription)"
                    openSCADController.isGenerating = false
                }
            }
        }
    }

    private func triggerLivePreviewIfEnabled() {
        guard previewSettings.mode == .live else { return }

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(previewSettings.livePreviewDelay * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    generateFan()
                }
            }
        }
    }

    private func exportSTL(_ format: ExportFormat) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.data]
        panel.nameFieldStringValue = "fan_export.\(format.fileExtension)"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            guard let fanNode = sceneController.fanNode,
                  let geometry = fanNode.geometry else {
                statusMessage = "No geometry to export"
                return
            }

            do {
                try STLExporter.shared.export(mesh: geometry, format: format, to: url)
                statusMessage = "Exported to \(url.lastPathComponent)"
            } catch {
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}
