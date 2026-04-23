# FanGen - Parametric Fan STL Generator

## Project Overview

**Name:** FanGen
**Bundle ID:** com.fangen.macos
**License:** MIT
**macOS Target:** 14.0+ (Sonoma, Apple Silicon & Intel)

### Core Functionality
A native macOS application providing real-time 3D preview of parametric fan geometries with support for both simple blade shapes and NACA airfoil profiles at multiple radial stations. Exports watertight STL files suitable for CAD, CFD, and 3D printing.

### Architecture
Hybrid approach: Swift/SwiftUI for GUI and scene rendering + OpenSCAD CLI as geometry engine backend.

```
┌─────────────────────────────────────────────────┐
│                FanGen App (macOS)               │
├─────────────────────────────────────────────────┤
│  SwiftUI Controls    │    SceneKit Preview      │
│  - Multi-station     │    - 3D fan rendering    │
│    parameters       │    - Real-time update     │
│  - Sliders/Numbers  │    - Orbit camera        │
├─────────────────────────────────────────────────┤
│              OpenSCAD Controller                │
│  - Custom fan_gen.scad script                   │
│  - Generates watertight STL                     │
├─────────────────────────────────────────────────┤
│  STL Export → Binary STL for CAD/CFD/meshing    │
└─────────────────────────────────────────────────┘
```

---

## Features

### Multi-Station Blade Parameters
- Users can define blade properties at multiple radial stations (hub to tip)
- Each station supports:
  - Chord width (mm)
  - Pitch angle (degrees)
  - Thickness (mm)
  - Profile type (Simple: rectangular/tapered/curved, or NACA airfoil)
  - Airfoil angle offset
- Interpolation between stations for smooth geometry
- Add/remove stations dynamically

### Profile Types
1. **Simple Profiles**
   - Rectangular: constant chord width
   - Tapered: linear taper from hub to tip
   - Curved: swept curve with bezier path

2. **NACA Airfoil Profiles**
   - 4-digit NACA codes (e.g., 2412, 0010)
   - Multiple sections with interpolation
   - Configurable angle of attack per section

### Preview Modes
- **Apply Mode (Default)**: Updates 3D preview only when Apply button is pressed
- **Live Preview**: Debounced updates (0.3s) as sliders are adjusted
- User can toggle between modes

### Hub Design
- Simple cylinder
- Configurable radius and height
- Optional center mounting hole

### Export
- Binary STL (standard for CAD/CFD)
- ASCII STL (human-readable)
- Watertight mesh guaranteed by OpenSCAD CSG

---

## Directory Structure

```
FanGen/
├── Sources/
│   ├── App/
│   │   ├── main.swift              # Manual app entry point
│   │   └── FanGenApp.swift        # @main SwiftUI Application
│   ├── Models/
│   │   ├── FanGeometry.swift      # Core parameters
│   │   ├── BladeProfile.swift      # Profile definitions
│   │   ├── BladeStation.swift     # Single station parameters
│   │   ├── HubParameters.swift    # Hub configuration
│   │   └── PreviewSettings.swift   # Preview mode settings
│   ├── Views/
│   │   ├── ContentView.swift       # Main window layout
│   │   ├── ParameterPanel.swift   # Left: station controls
│   │   ├── StationEditor.swift    # Per-station parameter editor
│   │   ├── FanPreviewView.swift   # Center: SceneKit 3D
│   │   ├── ExportPanel.swift      # Export options
│   │   └── Components/
│   │       ├── LabeledSlider.swift
│   │       ├── LabeledNumberField.swift
│   │       └── ApplyButton.swift
│   ├── Controllers/
│   │   ├── OpenSCADController.swift  # OpenSCAD process management
│   │   ├── SceneController.swift     # SceneKit scene management
│   │   └── GeometryGenerator.swift  # Parameters → OpenSCAD script
│   └── Utilities/
│       ├── STLExporter.swift        # Binary STL writing
│       ├── NACAProfileCalculator.swift
│       └── Extensions/
│           └── Double+Formatting.swift
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   └── Colors/
│   └── Scripts/
│       └── fan_gen.scad             # Custom OpenSCAD fan generator
├── project.yml                      # XcodeGen configuration
├── SPEC.md                          # This document
├── README.md                        # User documentation
└── LICENSE                          # MIT license
```

---

## Models

### FanGeometry
```swift
struct FanGeometry: Codable, Equatable {
    var bladeCount: Int = 5                    // 2-9
    var hub: HubParameters = HubParameters()
    var bladeRadius: Double = 100.0           // mm
    var pitchAngle: Double = 25.0             // degrees
    var rotationDirection: RotationDirection = .clockwise
    var profileType: ProfileType = .simple(.tapered)
    var twistDistribution: TwistDistribution = .linear

    @Observable var stations: [BladeStation] = [
        BladeStation(radius: 0.0, chord: 40, pitch: 25, thickness: 8, profile: .simple(.tapered)),
        BladeStation(radius: 0.5, chord: 35, pitch: 20, thickness: 6, profile: .simple(.tapered)),
        BladeStation(radius: 1.0, chord: 25, pitch: 15, thickness: 4, profile: .simple(.tapered))
    ]
}
```

### BladeStation
```swift
struct BladeStation: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var radius: Double              // 0.0 (hub) to 1.0 (tip)
    var chord: Double              // mm
    var pitch: Double              // degrees
    var thickness: Double          // mm
    var profile: StationProfile
}

enum StationProfile: Codable, Equatable {
    case simple(SimpleShape)
    case naca(NACAProfile)
}

enum SimpleShape: String, Codable, CaseIterable {
    case rectangular
    case tapered
    case curved
}

struct NACAProfile: Codable, Equatable {
    var code: String = "2412"      // 4-digit NACA code
    var angleOffset: Double = 0.0   // degrees
}
```

### HubParameters
```swift
struct HubParameters: Codable, Equatable {
    var radius: Double = 15.0      // mm
    var height: Double = 10.0      // mm
    var centerHole: Bool = false
    var holeDiameter: Double = 5.0 // mm
}
```

---

## UI Layout

### ContentView
```
┌─────────────────────────────────────────────────────────────┐
│ Toolbar: [Preview: Apply ▼] [Apply] [Export ▼]            │
├─────────────────┬─────────────────────────┬───────────────┤
│                 │                         │               │
│  PARAMETERS     │                         │   EXPORT      │
│                 │                         │               │
│  ─────────────  │      3D PREVIEW         │   Format:     │
│  Geometry       │      (SceneKit)         │   [Binary ▼] │
│                 │                         │               │
│  Blade Count: 5 │                         │   [Export]    │
│                 │          ↻              │               │
│  Hub Radius: 15 │                         │   ─────────   │
│  Hub Height: 10 │                         │   Info        │
│                 │                         │   • 5 blades  │
│  Blade Radius:  │                         │   • Ø100mm    │
│    [===100==]   │                         │   • 15mm hub │
│                 │                         │               │
│  Pitch Angle:   │                         │   [Copy]      │
│    [==25°===]   │                         │               │
│                 │                         │               │
│  ─────────────  │                         │               │
│  Stations       │                         │               │
│                 │                         │               │
│  [+ Add Station]│                         │               │
│                 │                         │               │
│  ○ Hub (0%)    ─────────────────────────│               │
│  ● 50%         ─────────────────────────│               │
│  ● Tip (100%)  ─────────────────────────│               │
│                 │                         │               │
│  Station @ 50%: │                         │               │
│  Chord: [==35mm=] 40mm                   │               │
│  Pitch: [==20°==] 20°                    │               │
│  Thickness: [=6mm=] 8mm                  │               │
│  Profile: [Simple ▼]                     │               │
│                 │                         │               │
│  ─────────────  │                         │               │
│  [   APPLY   ] │                         │               │
│                 │                         │               │
├─────────────────┴─────────────────────────┴───────────────┤
│ Status: Ready │ OpenSCAD: Found │ Last: fan_v1.stl          │
└─────────────────────────────────────────────────────────────┘
```

---

## OpenSCAD Script (fan_gen.scad)

### Parameters
- `blade_count` (integer 2-9)
- `hub_radius` (mm)
- `hub_height` (mm)
- `hub_hole` (boolean)
- `hub_hole_diameter` (mm)
- `blade_radius` (mm)
- `stations` (array of station parameters)
- `segments` (mesh quality)
- `rotation_dir` ("CW" or "CCW")

### Geometry Generation
1. Calculate blade span = blade_radius - hub_radius
2. For each blade:
   - Generate cross-section profiles at each station
   - Interpolate between stations
   - Extrude along sweep path
   - Apply twist based on pitch gradient
3. Generate hub as cylinder with optional hole
4. Rotate blades around hub center
5. Output watertight STL

---

## Implementation Phases

### Phase 1: Project Setup
- [x] Create XcodeGen project.yml
- [x] Set up directory structure
- [ ] Build empty shell, verify compilation

### Phase 2: Core Models
- [ ] FanGeometry, BladeStation, BladeProfile
- [ ] HubParameters, PreviewSettings
- [ ] Add Codable conformance
- [ ] Add validation

### Phase 3: OpenSCAD Integration
- [ ] Create fan_gen.scad template
- [ ] Implement OpenSCADController
- [ ] Implement GeometryGenerator
- [ ] Test STL generation

### Phase 4: SceneKit Preview
- [ ] SceneController
- [ ] FanPreviewView
- [ ] Load and display STL
- [ ] Camera controls, auto-rotation

### Phase 5: UI Controls
- [ ] ParameterPanel with station editor
- [ ] LabeledSlider, LabeledNumberField
- [ ] Apply button
- [ ] Preview mode toggle

### Phase 6: Export
- [ ] STLExporter
- [ ] Export panel
- [ ] Save dialog

### Phase 7: Polish & GitHub
- [ ] App icon
- [ ] OpenSCAD detection
- [ ] README.md
- [ ] GitHub repository

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| OpenSCAD not installed | Show alert with download link |
| STL generation fails | Show error in status bar |
| Invalid parameters | Inline validation, disable Apply |
| SceneKit load fails | Show placeholder |
| Export fails | Alert with error |

---

## Dependencies

### External (User Must Install)
- **OpenSCAD** (https://openscad.org) - Geometry engine

### Bundled
- None required (custom OpenSCAD script)

### System Frameworks
- SwiftUI
- SceneKit
- Foundation
- AppKit
- Combine

---

## License

MIT License - See LICENSE file

OpenSCAD is used as an external dependency and is licensed under GPL v2.
