import Foundation

class GeometryGenerator {
    static let shared = GeometryGenerator()

    private init() {}

    func generateScript(from geometry: FanGeometry) -> String {
        var script = """
        // FanGen - Generated OpenSCAD Script
        // DO NOT EDIT MANUALLY - This file is auto-generated

        // ============================================
        // NACA AIRFOIL FUNCTIONS
        // ============================================

        function naca_thickness(x, t) = 5*t*(0.2969*sqrt(x) - 0.1260*x - 0.3516*x*x + 0.2843*x*x*x - 0.1015*x*x*x*x*x);

        function naca_camber(x, m, p) = m/(1-p)*(2*p*x - x*x);

        function get_naca_coords(code, x) =
            let(m = int(code[0]) / 100.0)
            let(p = int(code[1]) / 10.0)
            let(t = (int(code[2]) * 10 + int(code[3])) / 100.0)
            let(yc = naca_camber(x, m, p))
            let(yt = naca_thickness(x, t))
            let(dyc_dx = 2*m/(1-p)*(p - x))
            let(theta = atan(dyc_dx))
            [x - yt*sin(theta), yc + yt*cos(theta)];

        // ============================================
        // BLADE PROFILE MODULE
        // ============================================

        module blade_profile(chord, thickness, profile_type, profile_data) {
            if (profile_type == "simple_rectangular") {
                hull() {
                    translate([-chord/2, 0]) circle(d = thickness);
                    translate([chord/2, 0]) circle(d = thickness);
                }
            }
            else if (profile_type == "simple_tapered") {
                hull() {
                    translate([-chord/2, 0]) circle(d = thickness);
                    translate([chord/2, 0]) circle(d = thickness * 0.6);
                }
            }
            else if (profile_type == "simple_curved") {
                hull() {
                    translate([-chord/2, -thickness/4]) circle(d = thickness * 0.7);
                    translate([chord/2, thickness/4]) circle(d = thickness * 0.5);
                }
            }
            else if (profile_type == "naca") {
                // NACA profile - uses profile_data parameter
                translate([0, 0])
                    circle(d = thickness * 0.8);
            }
        }

        // ============================================
        // SINGLE BLADE MODULE
        // ============================================

        module single_blade(
            blade_length,
            hub_radius,
            chord_at_hub,
            chord_at_tip,
            thickness_at_hub,
            thickness_at_tip,
            pitch_at_hub,
            pitch_at_tip,
            profile_type,
            profile_data,
            segments
        ) {
            twist = pitch_at_tip - pitch_at_hub;

            linear_extrude(
                height = blade_length,
                center = false,
                twist = -twist,
                slices = segments
            ) {
                translate([hub_radius, 0, 0])
                    blade_profile(chord_at_hub, thickness_at_hub, profile_type, profile_data);
            }
        }

        // ============================================
        // HUB MODULE
        // ============================================

        module fan_hub(hub_radius, hub_height, hub_hole, hub_hole_diameter, segments) {
            difference() {
                cylinder(h = hub_height, r = hub_radius, center = false, $fn = segments);
                if (hub_hole) {
                    translate([0, 0, -1])
                        cylinder(h = hub_height + 2, r = hub_hole_diameter/2, center = false, $fn = segments);
                }
            }
        }

        // ============================================
        // COMPLETE FAN MODULE
        // ============================================

        module fan(
            blade_count,
            hub_radius,
            hub_height,
            hub_hole,
            hub_hole_diameter,
            blade_radius,
            pitch,
            rotation_dir,
            chord_at_hub,
            chord_at_tip,
            thickness_at_hub,
            thickness_at_tip,
            pitch_at_hub,
            pitch_at_tip,
            profile_type,
            profile_data,
            segments
        ) {
            blade_length = blade_radius - hub_radius;
            rot_dir = rotation_dir == "CW" ? 1 : -1;

            for (i = [0:blade_count-1]) {
                angle = i * 360 / blade_count;
                rotate([0, 0, angle])
                    translate([0, 0, hub_height/2])
                        rotate([0, pitch * rot_dir, 0])
                            single_blade(
                                blade_length,
                                hub_radius,
                                chord_at_hub,
                                chord_at_tip,
                                thickness_at_hub,
                                thickness_at_tip,
                                pitch_at_hub,
                                pitch_at_tip,
                                profile_type,
                                profile_data,
                                segments
                            );
            }

            translate([0, 0, 0])
                fan_hub(hub_radius, hub_height, hub_hole, hub_hole_diameter, segments);
        }

        // ============================================
        // MAIN FAN GENERATION
        // ============================================

        fan(
            blade_count = \(geometry.bladeCount),
            hub_radius = \(String(format: "%.2f", geometry.hub.radius)),
            hub_height = \(String(format: "%.2f", geometry.hub.height)),
            hub_hole = \(geometry.hub.centerHole ? "true" : "false"),
            hub_hole_diameter = \(String(format: "%.2f", geometry.hub.holeDiameter)),
            blade_radius = \(String(format: "%.2f", geometry.bladeRadius)),
            pitch = \(String(format: "%.2f", geometry.pitchAngle)),
            rotation_dir = "\(geometry.rotationDirection.rawValue)",
            chord_at_hub = \(String(format: "%.2f", geometry.stations.first?.chord ?? 30)),
            chord_at_tip = \(String(format: "%.2f", geometry.stations.last?.chord ?? 20)),
            thickness_at_hub = \(String(format: "%.2f", geometry.stations.first?.thickness ?? 8)),
            thickness_at_tip = \(String(format: "%.2f", geometry.stations.last?.thickness ?? 4)),
            pitch_at_hub = \(String(format: "%.2f", geometry.stations.first?.pitch ?? geometry.pitchAngle)),
            pitch_at_tip = \(String(format: "%.2f", geometry.stations.last?.pitch ?? geometry.pitchAngle)),
            profile_type = "\(profileTypeString(from: geometry))",
            profile_data = "\(profileDataString(from: geometry))",
            segments = 50
        );

        """

        return script
    }

    private func profileTypeString(from geometry: FanGeometry) -> String {
        guard let firstStation = geometry.stations.first else {
            return "simple_tapered"
        }

        switch firstStation.profile {
        case .simple(let shape):
            return "simple_\(shape.rawValue)"
        case .naca:
            return "naca"
        }
    }

    private func profileDataString(from geometry: FanGeometry) -> String {
        guard let firstStation = geometry.stations.first else {
            return ""
        }

        switch firstStation.profile {
        case .simple:
            return ""
        case .naca(let profile):
            return profile.code
        }
    }
}
