import SwiftUI

enum ExportFormat: String, CaseIterable {
    case binary = "Binary STL"
    case ascii = "ASCII STL"

    var fileExtension: String {
        switch self {
        case .binary, .ascii:
            return "stl"
        }
    }
}

struct ExportPanel: View {
    let geometry: FanGeometry
    let onExport: (ExportFormat) -> Void

    @State private var selectedFormat: ExportFormat = .binary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Format")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Button(action: { onExport(selectedFormat) }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export STL")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Divider()

            fanInfoSection
        }
        .padding()
    }

    private var fanInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fan Info")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Group {
                infoRow(label: "Blades", value: "\(geometry.bladeCount)")
                infoRow(label: "Diameter", value: "\(Int(geometry.bladeRadius * 2))mm")
                infoRow(label: "Hub", value: "\(Int(geometry.hub.radius * 2))mm")
                infoRow(label: "Pitch", value: "\(Int(geometry.pitchAngle))°")
            }
            .font(.system(size: 11, design: .monospaced))
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
