import SwiftUI

struct FanPreviewView: NSViewRepresentable {
    let sceneController: SceneController

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = sceneController.scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = NSColor(hex: "#1E1E1E")
        scnView.antialiasingMode = .multisampling4X
        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        if nsView.scene !== sceneController.scene {
            nsView.scene = sceneController.scene
        }
    }
}

class SCNViewWrapper: NSView {
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.keyCode {
            case 126: // up arrow
                subviews.forEach { $0.removeFromSuperview() }
            default:
                super.keyDown(with: event)
            }
        } else {
            super.keyDown(with: event)
        }
    }
}
