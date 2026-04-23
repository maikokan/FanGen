import SwiftUI
import Combine

struct ParameterPanel: View {
    @Binding var geometry: FanGeometry
    @Binding var previewSettings: PreviewSettings
    let onApply: () -> Void
    let isGenerating: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection

                Divider()

                geometrySection

                Divider()

                hubSection

                Divider()

                stationsSection

                Divider()

                applySection
            }
            .padding()
        }
        .frame(minWidth: 280, maxWidth: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FanGen")
                .font(.system(size: 20, weight: .bold))

            Picker("Preview Mode", selection: $previewSettings.mode) {
                ForEach(PreviewMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Auto Rotate", isOn: $previewSettings.autoRotate)
                .font(.system(size: 12))
        }
    }

    private var geometrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Geometry")
                .font(.system(size: 14, weight: .semibold))

            LabeledIntSlider(
                label: "Blade Count",
                value: $geometry.bladeCount,
                range: FanGeometry.bladeCountRange
            )

            LabeledSlider(
                label: "Blade Radius",
                value: $geometry.bladeRadius,
                range: FanGeometry.bladeRadiusRange,
                step: 1,
                unit: "mm"
            )

            LabeledSlider(
                label: "Pitch Angle",
                value: $geometry.pitchAngle,
                range: FanGeometry.pitchAngleRange,
                step: 1,
                unit: "°"
            )

            HStack {
                Text("Rotation")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Spacer()

                Picker("", selection: $geometry.rotationDirection) {
                    ForEach(RotationDirection.allCases) { dir in
                        Text(dir.displayName).tag(dir)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
    }

    private var hubSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hub")
                .font(.system(size: 14, weight: .semibold))

            LabeledSlider(
                label: "Radius",
                value: $geometry.hub.radius,
                range: HubParameters.radiusRange,
                step: 0.5,
                unit: "mm"
            )

            LabeledSlider(
                label: "Height",
                value: $geometry.hub.height,
                range: HubParameters.heightRange,
                step: 0.5,
                unit: "mm"
            )

            Toggle("Center Hole", isOn: $geometry.hub.centerHole)
                .font(.system(size: 12))

            if geometry.hub.centerHole {
                LabeledSlider(
                    label: "Hole Diameter",
                    value: $geometry.hub.holeDiameter,
                    range: HubParameters.holeDiameterRange,
                    step: 0.5,
                    unit: "mm"
                )
            }
        }
    }

    private var stationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Blade Stations")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                Button(action: addStation) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            if geometry.stations.count > 2 {
                ForEach(Array(geometry.stations.enumerated()), id: \.element.id) { index, station in
                    StationEditor(
                        station: $geometry.stations[index],
                        onDelete: { removeStation(at: index) },
                        canDelete: geometry.stations.count > 2
                    )
                }
            }

            ForEach(Array(geometry.stations.enumerated()), id: \.element.id) { index, station in
                StationEditor(
                    station: $geometry.stations[index],
                    onDelete: { removeStation(at: index) },
                    canDelete: geometry.stations.count > 2
                )
            }
        }
    }

    private var applySection: some View {
        ApplyButton(action: onApply, isEnabled: true, isLoading: isGenerating)
    }

    private func addStation() {
        let newRadius = findBestNewStationRadius()
        geometry.addStation(at: newRadius)
    }

    private func removeStation(at index: Int) {
        geometry.removeStation(at: index)
    }

    private func findBestNewStationRadius() -> Double {
        let sorted = geometry.stations.sorted { $0.radius < $1.radius }
        var maxGap: Double = 0
        var bestRadius: Double = 0.5

        for i in 0..<(sorted.count - 1) {
            let gap = sorted[i + 1].radius - sorted[i].radius
            if gap > maxGap {
                maxGap = gap
                bestRadius = sorted[i].radius + gap / 2
            }
        }

        return bestRadius
    }
}
