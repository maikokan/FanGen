import Foundation
import SceneKit
import Combine

@MainActor
final class SceneController: ObservableObject {
    @Published var scene: SCNScene
    @Published var fanNode: SCNNode?
    @Published var isLoading: Bool = false
    @Published var lastError: String?

    private var autoRotationAction: SCNAction?

    init() {
        scene = SCNScene()
        setupScene()
    }

    private func setupScene() {
        scene.background.contents = NSColor(hex: "#1E1E1E")

        addAmbientLight()
        addDirectionalLights()
        addCamera()
    }

    private func addAmbientLight() {
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = NSColor(white: 0.3, alpha: 1.0)
        ambientLight.name = "ambientLight"
        scene.rootNode.addChildNode(ambientLight)
    }

    private func addDirectionalLights() {
        let directionalLight1 = SCNNode()
        directionalLight1.light = SCNLight()
        directionalLight1.light?.type = .directional
        directionalLight1.light?.color = NSColor(white: 0.8, alpha: 1.0)
        directionalLight1.position = SCNVector3(x: 5, y: 10, z: 5)
        directionalLight1.look(at: SCNVector3(x: 0, y: 0, z: 0))
        directionalLight1.name = "directionalLight1"
        scene.rootNode.addChildNode(directionalLight1)

        let directionalLight2 = SCNNode()
        directionalLight2.light = SCNLight()
        directionalLight2.light?.type = .directional
        directionalLight2.light?.color = NSColor(white: 0.4, alpha: 1.0)
        directionalLight2.position = SCNVector3(x: -5, y: 5, z: -5)
        directionalLight2.look(at: SCNVector3(x: 0, y: 0, z: 0))
        directionalLight2.name = "directionalLight2"
        scene.rootNode.addChildNode(directionalLight2)
    }

    private func addCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 1
        cameraNode.camera?.zFar = 1000
        cameraNode.position = SCNVector3(x: 0, y: 50, z: 150)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)
    }

    func loadMesh(from url: URL) throws {
        isLoading = true
        lastError = nil

        fanNode?.removeFromParentNode()

        let loadedScene = try SCNScene(url: url, options: [
            .checkConsistency: true,
            .flattenScene: false
        ])

        let containerNode = SCNNode()
        containerNode.name = "fanContainer"

        for child in loadedScene.rootNode.childNodes {
            child.removeFromParentNode()
            containerNode.addChildNode(child)
        }

        centerAndScaleNode(containerNode)

        let material = SCNMaterial()
        material.diffuse.contents = NSColor(hex: "#4A90D9")
        material.specular.contents = NSColor.white
        material.shininess = 0.5
        material.lightingModel = .phong

        containerNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                geometry.materials = [material]
            }
        }

        scene.rootNode.addChildNode(containerNode)
        fanNode = containerNode

        isLoading = false
    }

    private func centerAndScaleNode(_ node: SCNNode) {
        var minBound = SCNVector3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var maxBound = SCNVector3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)

        node.enumerateChildNodes { child, _ in
            let (bMin, bMax) = child.boundingBox
            minBound.x = min(minBound.x, bMin.x)
            minBound.y = min(minBound.y, bMin.y)
            minBound.z = min(minBound.z, bMin.z)
            maxBound.x = max(maxBound.x, bMax.x)
            maxBound.y = max(maxBound.y, bMax.y)
            maxBound.z = max(maxBound.z, bMax.z)
        }

        let centerX = (minBound.x + maxBound.x) / 2
        let centerY = (minBound.y + maxBound.y) / 2
        let centerZ = (minBound.z + maxBound.z) / 2

        let sizeX = maxBound.x - minBound.x
        let sizeY = maxBound.y - minBound.y
        let sizeZ = maxBound.z - minBound.z
        let maxSize = max(sizeX, max(sizeY, sizeZ))
        let targetSize: CGFloat = 100.0
        let scale = CGFloat(targetSize / maxSize)

        node.position = SCNVector3(x: -centerX * scale, y: -centerY * scale, z: -centerZ * scale)
        node.scale = SCNVector3(x: scale, y: scale, z: scale)
    }

    func startAutoRotation(speed: Double = 0.5) {
        guard fanNode != nil else { return }

        stopAutoRotation()

        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 2.0 / speed)
        let repeatAction = SCNAction.repeatForever(rotation)
        fanNode?.runAction(repeatAction, forKey: "autoRotation")
    }

    func stopAutoRotation() {
        fanNode?.removeAction(forKey: "autoRotation")
    }

    func resetCamera() {
        guard let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: false) else { return }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        cameraNode.position = SCNVector3(x: 0, y: 50, z: 150)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        SCNTransaction.commit()
    }

    func clearScene() {
        fanNode?.removeFromParentNode()
        fanNode = nil
    }
}
