import SceneKit
import SwiftUI
import UIKit

struct RoomModelQuickLookPreview: UIViewControllerRepresentable {
    let modelURL: URL
    var spatialHighlight: SpatialHighlight? = nil
    var spatialVisuals = SpatialVisuals()
    var placementRequest: SpatialPlacementRequest? = nil
    var onPoseSelected: ((SpatialModelPose) -> Void)? = nil

    func makeUIViewController(context: Context) -> RoomModelPreviewController {
        RoomModelPreviewController(modelURL: modelURL)
    }

    func updateUIViewController(_ uiViewController: RoomModelPreviewController, context: Context) {
        uiViewController.updateSpatialHighlight(spatialHighlight)
        uiViewController.updateSpatialVisuals(spatialVisuals)
        uiViewController.updatePlacement(request: placementRequest, onPoseSelected: onPoseSelected)
    }
}

final class RoomModelPreviewController: UIViewController, UIGestureRecognizerDelegate {
    private let modelURL: URL
    private var scene: SCNScene?
    private weak var sceneView: SCNView?
    private var placementRequest: SpatialPlacementRequest?
    private var onPoseSelected: ((SpatialModelPose) -> Void)?
    private var acceptedPlacementCallId: String?
    private var placementPreviews: [String: SCNNode] = [:]
    private weak var cutawayWallNode: SCNNode?


    init(modelURL: URL) {
        self.modelURL = modelURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try configureModelView()
        } catch {
            configureErrorView(message: error.localizedDescription)
        }
    }

    private func configureModelView() throws {
        let scene = try SCNScene(url: modelURL, options: nil)
        let sceneView = SCNView(frame: .zero)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor(red: 0.055, green: 0.075, blue: 0.11, alpha: 1)
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X
        let placementTap = UITapGestureRecognizer(target: self, action: #selector(handlePlacementTap(_:)))
        placementTap.cancelsTouchesInView = false
        placementTap.delegate = self
        sceneView.addGestureRecognizer(placementTap)

        addCamera(to: scene, sceneView: sceneView)
        addLighting(to: scene)
        addModelRelativeWallLabels(to: scene)
        self.scene = scene
        self.sceneView = sceneView

        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let instructionLabel = UILabel()
        instructionLabel.text = "Model directions N/E/S/W • not compass • Drag or pinch to inspect • Tap to place when asked"
        instructionLabel.font = .preferredFont(forTextStyle: .footnote)
        instructionLabel.textColor = .white
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        instructionLabel.textAlignment = .center
        instructionLabel.layer.cornerRadius = 10
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            instructionLabel.heightAnchor.constraint(equalToConstant: 36),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }

    func updatePlacement(request: SpatialPlacementRequest?, onPoseSelected: ((SpatialModelPose) -> Void)?) {
        guard request?.callId != acceptedPlacementCallId || request?.kind == .routePoint else { return }
        placementRequest = request
        self.onPoseSelected = onPoseSelected
    }

    @objc private func handlePlacementTap(_ recognizer: UITapGestureRecognizer) {
        guard let request = placementRequest,
              request.callId != acceptedPlacementCallId || request.kind == .routePoint,
              let sceneView else { return }
        guard let result = sceneView.hitTest(recognizer.location(in: sceneView), options: [.searchMode: SCNHitTestSearchMode.closest.rawValue]).first,
              isImportedModelNode(result.node) else { return }
        let point = result.worldCoordinates
        let bounds = scene.map(modelBounds(in:))
        let isWall = abs(result.worldNormal.y) <= 0.8
        let modelRelativeWall = isWall ? wallReference(for: result.worldNormal) : nil
        let alongWallMeters: Float?
        if abs(result.worldNormal.x) >= abs(result.worldNormal.z) {
            alongWallMeters = bounds.map { point.z - $0.minimum.z }
        } else {
            alongWallMeters = bounds.map { point.x - $0.minimum.x }
        }
        let pose = SpatialModelPose(
            x: point.x,
            y: point.y,
            z: point.z,
            normalX: result.worldNormal.x,
            normalY: result.worldNormal.y,
            normalZ: result.worldNormal.z,
            surface: isWall ? "wall" : "floor",
            modelRelativeWall: modelRelativeWall,
            alongWallMeters: alongWallMeters,
            heightAboveModelFloorMeters: bounds.map { max(0, point.y - $0.minimum.y) }
        )
        if request.kind != .routePoint {
            acceptedPlacementCallId = request.callId
        }
        showPlacementPreview(for: request.kind, at: pose, selectedNode: result.node)
        onPoseSelected?(pose)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    private func isImportedModelNode(_ node: SCNNode) -> Bool {
        var current: SCNNode? = node
        while let candidate = current {
            if candidate.name?.hasPrefix("spatial-") == true || candidate.name?.hasPrefix("model-reference-") == true || candidate.camera != nil || candidate.light != nil { return false }
            current = candidate.parent
        }
        return true
    }

    func updateSpatialVisuals(_ spatialVisuals: SpatialVisuals) {
        guard let scene else { return }
        scene.rootNode.childNode(withName: "spatial-visuals", recursively: false)?.removeFromParentNode()
        let visualsNode = SCNNode()
        visualsNode.name = "spatial-visuals"
        if let panelPose = spatialVisuals.panelPose {
            visualsNode.addChildNode(enclosureNode(
                name: "spatial-panel-enclosure",
                pose: panelPose,
                width: 0.61,
                height: 0.91,
                depth: 0.28,
                color: .systemOrange
            ))
        }
        if let evsePose = spatialVisuals.evsePose {
            visualsNode.addChildNode(enclosureNode(
                name: "spatial-evse-enclosure",
                pose: evsePose,
                width: 0.30,
                height: 0.45,
                depth: 0.28,
                color: .systemTeal
            ))
        }
        for (start, end) in zip(spatialVisuals.routePoses, spatialVisuals.routePoses.dropFirst()) {
            if let segment = routeSegment(from: start, to: end, in: scene) {
                visualsNode.addChildNode(segment)
            }
        }
        if let candidateOpeningPose = spatialVisuals.candidateOpeningPose {
            visualsNode.addChildNode(candidateOpeningNode(pose: candidateOpeningPose))
        }
        guard !visualsNode.childNodes.isEmpty else { return }
        scene.rootNode.addChildNode(visualsNode)
    }

    private func showPlacementPreview(for kind: SpatialPlacementKind, at pose: SpatialModelPose, selectedNode: SCNNode? = nil) {
        let key = kind.rawValue
        placementPreviews[key]?.removeFromParentNode()
        if kind == .candidateOpening, let selectedNode {
            cutawayWallNode?.isHidden = false
            cutawayWallNode = selectedNode
            selectedNode.isHidden = true
        }
        let preview = switch kind {
        case .electricalPanel:
            worldPrismNode(name: "spatial-panel-preview", width: 0.61, height: 0.91, depth: 0.28, color: .systemOrange)
        case .evse:
            worldPrismNode(name: "spatial-evse-preview", width: 0.30, height: 0.45, depth: 0.28, color: .systemTeal)
        case .routePoint:
            SCNNode(geometry: SCNSphere(radius: 0.10))
        case .candidateOpening:
            candidateOpeningNode(pose: pose)
        }
        preview.name = "spatial-placement-preview-\(key)"
        if kind == .electricalPanel || kind == .evse {
            positionWallMountedPreview(preview, at: pose)
        } else if kind != .candidateOpening {
            preview.position = SCNVector3(pose.x, pose.y, pose.z)
        }
        if kind == .routePoint {
            preview.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
            preview.geometry?.firstMaterial?.emission.contents = UIColor.systemYellow
        }
        preview.geometry?.firstMaterial?.transparency = 0.95
        scene?.rootNode.addChildNode(preview)
        placementPreviews[key] = preview
    }

    private func positionWallMountedPreview(_ node: SCNNode, at pose: SpatialModelPose) {
        let normal = markerNormal(for: pose)
        let depth = Float(0.28 / 2 + 0.02)
        node.position = SCNVector3(
            pose.x + normal.x * depth,
            pose.y + normal.y * depth,
            pose.z + normal.z * depth
        )
        node.eulerAngles.y = atan2(normal.x, normal.z)
    }

    private func worldPrismNode(name: String, width: CGFloat, height: CGFloat, depth: CGFloat, color: UIColor) -> SCNNode {
        let node = SCNNode(geometry: SCNBox(width: width, height: height, length: depth, chamferRadius: 0.025))
        node.name = name
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.emission.contents = color.withAlphaComponent(0.75)
        material.lightingModel = .constant
        material.isDoubleSided = true
        node.geometry?.materials = Array(repeating: material, count: 6)
        return node
    }

    private func enclosureNode(name: String, pose: SpatialModelPose, width: CGFloat, height: CGFloat, depth: CGFloat, color: UIColor) -> SCNNode {
        let node = SCNNode(geometry: SCNBox(width: width, height: height, length: depth, chamferRadius: 0.025))
        node.name = name
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.emission.contents = color.withAlphaComponent(0.9)
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.readsFromDepthBuffer = false
        material.writesToDepthBuffer = false
        material.transparency = 1
        node.geometry?.materials = Array(repeating: material, count: 6)
        node.renderingOrder = 1_000
        let normal = markerNormal(for: pose)
        node.position = SCNVector3(
            pose.x + normal.x * Float(depth / 2 + 0.02),
            pose.y + normal.y * Float(depth / 2 + 0.02),
            pose.z + normal.z * Float(depth / 2 + 0.02)
        )
        if abs(normal.y) < 0.8 {
            node.eulerAngles.y = atan2(normal.x, normal.z)
        } else {
            node.eulerAngles.x = .pi / 2
        }
        return node
    }

    private func markerNormal(for pose: SpatialModelPose) -> SCNVector3 {
        let normal = SCNVector3(pose.normalX, pose.normalY, pose.normalZ)
        guard pose.surface == "wall" else { return normal }
        let wallNormal: SCNVector3
        if abs(normal.x) >= abs(normal.z) {
            wallNormal = SCNVector3(normal.x >= 0 ? 1 : -1, 0, 0)
        } else {
            wallNormal = SCNVector3(0, 0, normal.z >= 0 ? 1 : -1)
        }
        guard let camera = sceneView?.pointOfView else { return wallNormal }
        let cameraPosition = camera.presentation.worldPosition
        let toCamera = SCNVector3(cameraPosition.x - pose.x, cameraPosition.y - pose.y, cameraPosition.z - pose.z)
        let facesCamera = wallNormal.x * toCamera.x + wallNormal.y * toCamera.y + wallNormal.z * toCamera.z >= 0
        return facesCamera ? wallNormal : SCNVector3(-wallNormal.x, -wallNormal.y, -wallNormal.z)
    }

    private func wallReference(for normal: SCNVector3) -> String {
        if abs(normal.x) >= abs(normal.z) {
            return normal.x >= 0 ? "N" : "S"
        }
        return normal.z >= 0 ? "E" : "W"
    }

    private func routeSegment(from start: SpatialModelPose, to end: SpatialModelPose, in scene: SCNScene) -> SCNNode? {
        let delta = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
        let length = sqrt(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z)
        guard length > 0.01 else { return nil }
        let node = SCNNode(geometry: SCNCylinder(radius: 0.018, height: CGFloat(length)))
        node.name = "spatial-route-conduit"
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemIndigo
        node.geometry?.firstMaterial?.emission.contents = UIColor.systemIndigo.withAlphaComponent(0.25)
        node.position = SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2, (start.z + end.z) / 2)
        node.look(at: SCNVector3(end.x, end.y, end.z), up: scene.rootNode.worldUp, localFront: SCNVector3(0, 1, 0))
        return node
    }

    private func candidateOpeningNode(pose: SpatialModelPose) -> SCNNode {
        let node = enclosureNode(
            name: "spatial-candidate-opening",
            pose: pose,
            width: 1.8,
            height: 2.1,
            depth: 0.04,
            color: .systemMint
        )
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.transparency = 1
        node.geometry?.firstMaterial?.emission.contents = UIColor.systemMint
        return node
    }

    private func addCamera(to scene: SCNScene, sceneView: SCNView) {
        let (minimum, maximum) = modelBounds(in: scene)
        let center = SCNVector3(
            (minimum.x + maximum.x) / 2,
            (minimum.y + maximum.y) / 2,
            (minimum.z + maximum.z) / 2
        )
        let extent = max(
            max(maximum.x - minimum.x, maximum.y - minimum.y),
            max(maximum.z - minimum.z, 1)
        )

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 60
        camera.zNear = 0.01
        camera.zFar = Double(extent * 20)
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(center.x, center.y + extent * 0.2, center.z + extent * 1.7)
        cameraNode.look(at: center)
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        sceneView.defaultCameraController.target = center
    }

    private func addLighting(to scene: SCNScene) {
        let (minimum, maximum) = modelBounds(in: scene)
        let center = SCNVector3(
            (minimum.x + maximum.x) / 2,
            (minimum.y + maximum.y) / 2,
            (minimum.z + maximum.z) / 2
        )
        let extent = max(
            max(maximum.x - minimum.x, maximum.y - minimum.y),
            max(maximum.z - minimum.z, 1)
        )

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.58, alpha: 1)
        ambient.light?.intensity = 700
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .omni
        key.light?.color = UIColor(red: 0.86, green: 0.93, blue: 1, alpha: 1)
        key.light?.intensity = 900
        key.light?.castsShadow = true
        key.light?.shadowRadius = 12
        key.light?.shadowSampleCount = 16
        key.position = SCNVector3(center.x + extent, center.y + extent * 1.3, center.z + extent)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .omni
        fill.light?.color = UIColor(red: 0.82, green: 0.89, blue: 1, alpha: 1)
        fill.light?.intensity = 700
        fill.position = SCNVector3(center.x - extent, center.y + extent * 0.5, center.z - extent)
        scene.rootNode.addChildNode(fill)
    }

    private func addModelRelativeWallLabels(to scene: SCNScene) {
        let (minimum, maximum) = modelBounds(in: scene)
        let center = SCNVector3(
            (minimum.x + maximum.x) / 2,
            (minimum.y + maximum.y) / 2,
            (minimum.z + maximum.z) / 2
        )
        let roomRadius = max(maximum.x - minimum.x, maximum.z - minimum.z) / 2
        let labelRadius = max(roomRadius * 1.12, 1)
        let floorY = minimum.y + 0.02

        addModelRelativeWallLabel("N", at: SCNVector3(center.x + labelRadius, floorY, center.z), to: scene)
        addModelRelativeWallLabel("E", at: SCNVector3(center.x, floorY, center.z + labelRadius), to: scene)
        addModelRelativeWallLabel("S", at: SCNVector3(center.x - labelRadius, floorY, center.z), to: scene)
        addModelRelativeWallLabel("W", at: SCNVector3(center.x, floorY, center.z - labelRadius), to: scene)
    }

    private func addModelRelativeWallLabel(_ text: String, at position: SCNVector3, to scene: SCNScene) {
        let geometry = SCNText(string: text, extrusionDepth: 0.005)
        geometry.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        geometry.flatness = 0.1
        geometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.82)
        geometry.firstMaterial?.emission.contents = UIColor.systemIndigo.withAlphaComponent(0.5)

        let label = SCNNode(geometry: geometry)
        label.name = "model-reference-\(text)"
        label.position = position
        label.eulerAngles.x = -.pi / 2
        label.scale = SCNVector3(0.07, 0.07, 0.07)
        let (minimum, maximum) = label.boundingBox
        label.pivot = SCNMatrix4MakeTranslation(
            (minimum.x + maximum.x) / 2,
            (minimum.y + maximum.y) / 2,
            0
        )
        scene.rootNode.addChildNode(label)
    }

    private func modelBounds(in scene: SCNScene) -> (minimum: SCNVector3, maximum: SCNVector3) {
        var minimum: SCNVector3?
        var maximum: SCNVector3?

        scene.rootNode.enumerateChildNodes { node, _ in
            guard node.geometry != nil, node.camera == nil, node.light == nil else { return }
            let (nodeMinimum, nodeMaximum) = node.boundingBox
            for x in [nodeMinimum.x, nodeMaximum.x] {
                for y in [nodeMinimum.y, nodeMaximum.y] {
                    for z in [nodeMinimum.z, nodeMaximum.z] {
                        let point = node.convertPosition(SCNVector3(x, y, z), to: scene.rootNode)
                        if let currentMinimum = minimum, let currentMaximum = maximum {
                            minimum = SCNVector3(min(currentMinimum.x, point.x), min(currentMinimum.y, point.y), min(currentMinimum.z, point.z))
                            maximum = SCNVector3(max(currentMaximum.x, point.x), max(currentMaximum.y, point.y), max(currentMaximum.z, point.z))
                        } else {
                            minimum = point
                            maximum = point
                        }
                    }
                }
            }
        }

        return (minimum ?? SCNVector3(-0.5, -0.5, -0.5), maximum ?? SCNVector3(0.5, 0.5, 0.5))
    }

    func updateSpatialHighlight(_ highlight: SpatialHighlight?) {
        guard let scene else { return }
        scene.rootNode.childNode(withName: "spatial-highlight", recursively: false)?.removeFromParentNode()
    }

    private func configureErrorView(message: String) {
        let label = UILabel()
        label.text = "Unable to open the room model.\n\(message)"
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}