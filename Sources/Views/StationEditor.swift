import SwiftUI
import Combine

struct StationEditor: View {
    @Binding var station: BladeStation
    let onDelete: (() -> Void)?
    let canDelete: Bool

    init(
        station: Binding<BladeStation>,
        onDelete: (() -> Void)? = nil,
        canDelete: Bool = true
    ) {
        self._station = station
        self.onDelete = onDelete
        self.canDelete = canDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(station.displayName)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                if let onDelete = onDelete, canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            VStack(spacing: 8) {
                HStack {
                    Text("Position")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(station.radius * 100))%")
                        .font(.system(size: 12, design: .monospaced))
                }

                Slider(value: Binding(
                    get: { station.radius },
                    set: { station.radius = $0 }
                ), in: 0...1, step: 0.05)
            }

            VStack(spacing: 8) {
                LabeledSlider(
                    label: "Chord",
                    value: Binding(
                        get: { station.chord },
                        set: { station.chord = $0 }
                    ),
                    range: 10...80,
                    step: 1,
                    unit: "mm"
                )
            }

            VStack(spacing: 8) {
                LabeledSlider(
                    label: "Pitch",
                    value: Binding(
                        get: { station.pitch },
                        set: { station.pitch = $0 }
                    ),
                    range: 0...60,
                    step: 1,
                    unit: "°"
                )
            }

            VStack(spacing: 8) {
                LabeledSlider(
                    label: "Thickness",
                    value: Binding(
                        get: { station.thickness },
                        set: { station.thickness = $0 }
                    ),
                    range: 2...20,
                    step: 0.5,
                    unit: "mm"
                )
            }

            HStack {
                Text("Profile")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()

                Picker("", selection: Binding(
                    get: { profileKind },
                    set: { newKind in
                        switch newKind {
                        case .simple:
                            station.profile = .simple(.tapered)
                        case .naca:
                            station.profile = .naca(NACAProfile())
                        }
                    }
                )) {
                    Text("Simple").tag(ProfileKind.simple)
                    Text("NACA").tag(ProfileKind.naca)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            switch station.profile {
            case .simple(let shape):
                Picker("Shape", selection: Binding(
                    get: { shape },
                    set: { station.profile = .simple($0) }
                )) {
                    ForEach(SimpleShape.allCases) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                .pickerStyle(.menu)

            case .naca(let profile):
                HStack {
                    Text("Code")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    TextField("2412", text: Binding(
                        get: { profile.code },
                        set: { station.profile = .naca(NACAProfile(code: $0, angleOffset: profile.angleOffset)) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .font(.system(size: 12, design: .monospaced))
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var profileKind: ProfileKind {
        switch station.profile {
        case .simple: return .simple
        case .naca: return .naca
        }
    }

    private enum ProfileKind {
        case simple
        case naca
    }
}
