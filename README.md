# FanGen

A native macOS application for generating parametric fan STL files with real-time 3D preview.

## Features

- **Multi-Station Blade Parameters**: Define blade properties at multiple radial stations from hub to tip
- **Profile Types**: Support for simple blade shapes (rectangular, tapered, curved) and NACA airfoils
- **Flexible Preview**: Choose between live preview (debounced updates) or apply-on-click mode
- **3D Preview**: Real-time SceneKit rendering with orbit camera and auto-rotation
- **STL Export**: Binary and ASCII STL output for CAD, CFD, and 3D printing
- **OpenSCAD Backend**: Utilizes OpenSCAD as the geometry engine for watertight mesh generation

## Requirements

- **macOS 14.0+** (Sonoma or later)
- **OpenSCAD** must be installed (external dependency)

### Installing OpenSCAD

1. Download OpenSCAD from [https://openscad.org/downloads.html](https://openscad.org/downloads.html)
2. Install the application to `/Applications/OpenSCAD.app`
3. FanGen will automatically detect the installation on launch

## Building from Source

### Prerequisites

- Xcode 15.0 or later
- XcodeGen (`brew install xcodegen`)

### Build Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/<username>/FanGen.git
   cd FanGen
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open the project in Xcode:
   ```bash
   open FanGen.xcodeproj
   ```

4. Build and run from Xcode (Cmd+R)

## Usage

### Parameter Panel

- **Blade Count**: Number of blades (2-9)
- **Blade Radius**: Overall blade radius in mm
- **Pitch Angle**: Blade pitch in degrees
- **Rotation Direction**: Clockwise or Counter-Clockwise

### Hub Parameters

- **Radius**: Hub radius (5-50mm)
- **Height**: Hub height (5-30mm)
- **Center Hole**: Optional mounting hole with configurable diameter

### Blade Stations

Each station defines blade properties at a specific radial position:

- **Position**: Radial position (0% = hub, 100% = tip)
- **Chord**: Blade chord width in mm
- **Pitch**: Local pitch angle in degrees
- **Thickness**: Blade thickness in mm
- **Profile**: Simple shape or NACA airfoil

Add stations by clicking the **+** button. Stations can be deleted if more than 2 exist.

### Preview Mode

Toggle between:
- **On Apply**: Updates preview only when Apply button is clicked
- **Live Preview**: Debounced updates as parameters are adjusted

### Export

1. Select STL format (Binary or ASCII)
2. Click "Export STL"
3. Choose save location

## Architecture

```
┌─────────────────────────────────────────────────┐
│                FanGen App                       │
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

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+E | Export STL |
| Cmd+W | Close window |
| Cmd+M | Minimize window |
| Space | Reset camera view |

## Troubleshooting

### OpenSCAD Not Found

If FanGen shows "OpenSCAD: Not Found":
1. Ensure OpenSCAD is installed in `/Applications/OpenSCAD.app`
2. Or install via Homebrew: `brew install --cask openscad`

### Preview Not Updating

- Ensure "Apply" button is clicked after changing parameters
- Check the status bar for error messages
- Verify OpenSCAD is running without errors

## License

MIT License - see [LICENSE](LICENSE) file

---

This software uses **OpenSCAD** (https://openscad.org) as an external dependency, licensed under GPL v2.
