import SceneKit
import SwiftUI
import UIKit

struct RoomModelQuickLookPreview: UIViewControllerRepresentable {
    let modelURL: URL
    var spatialHighlight: SpatialHighlight? = nil
    var placementRequest: SpatialPlacementRequest? = nil
    var onPoseSelected: ((SpatialModelPose) -> Void)? = nil

    func makeUIViewController(context: Context) -> RoomModelPreviewController {
        RoomModelPreviewController(modelURL: modelURL)
    }

    func updateUIViewController(_ uiViewController: RoomModelPreviewController, context: Context) {
        uiViewController.updateSpatialHighlight(spatialHighlight)
        uiViewController.updatePlacement(request: placementRequest, onPoseSelected: onPoseSelected)
    }
}

final class RoomModelPreviewController: UIViewController {
    private let modelURL: URL
    private var scene: SCNScene?
    private weak var sceneView: SCNView?
    private var placementRequest: SpatialPlacementRequest?
    private var onPoseSelected: ((SpatialModelPose) -> Void)?
    private var selectedPlacementMarker: SCNNode?

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
        sceneView.addGestureRecognizer(placementTap)

        addCamera(to: scene)
        addLighting(to: scene)
        addModelReference(to: scene)
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
        instructionLabel.text = "Drag to rotate • Pinch to zoom"
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
        placementRequest = request
        self.onPoseSelected = onPoseSelected
        sceneView?.allowsCameraControl = request == nil
    }

    @objc private func handlePlacementTap(_ recognizer: UITapGestureRecognizer) {
        guard placementRequest != nil, let sceneView else { return }
        guard let result = sceneView.hitTest(recognizer.location(in: sceneView), options: [.searchMode: SCNHitTestSearchMode.closest.rawValue]).first,
              isImportedModelNode(result.node) else { return }
        let point = result.worldCoordinates
        showPlacementMarker(at: point, normal: result.worldNormal)
        onPoseSelected?(SpatialModelPose(x: point.x, y: point.y, z: point.z, surface: abs(result.worldNormal.y) > 0.8 ? "floor" : "wall"))
        if placementRequest?.kind != .routePoint {
            placementRequest = nil
            sceneView.allowsCameraControl = true
        }
    }

    private func isImportedModelNode(_ node: SCNNode) -> Bool {
        var current: SCNNode? = node
        while let candidate = current {
            if candidate.name?.hasPrefix("spatial-") == true || candidate.name?.hasPrefix("model-reference-") == true || candidate.camera != nil || candidate.light != nil { return false }
            current = candidate.parent
        }
        return true
    }

    private func showPlacementMarker(at point: SCNVector3, normal: SCNVector3) {
        selectedPlacementMarker?.removeFromParentNode()
        let marker = SCNNode(geometry: SCNPlane(width: 0.24, height: 0.24))
        marker.name = "spatial-placement-marker"
        marker.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
        marker.geometry?.firstMaterial?.emission.contents = UIColor.systemYellow
        marker.geometry?.firstMaterial?.transparency = 0.9
        marker.position = SCNVector3(point.x + normal.x * 0.006, point.y + normal.y * 0.006, point.z + normal.z * 0.006)
        marker.look(at: SCNVector3(point.x + normal.x, point.y + normal.y, point.z + normal.z))
        scene?.rootNode.addChildNode(marker)
        selectedPlacementMarker = marker
    }

    private func addCamera(to scene: SCNScene) {
        let (minimum, maximum) = scene.rootNode.boundingBox
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
    }

    private func addLighting(to scene: SCNScene) {
        let (minimum, maximum) = scene.rootNode.boundingBox
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
        ambient.light?.color = UIColor(white: 0.42, alpha: 1)
        ambient.light?.intensity = 450
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .omni
        key.light?.color = UIColor(red: 0.86, green: 0.93, blue: 1, alpha: 1)
        key.light?.intensity = 1_300
        key.light?.castsShadow = true
        key.position = SCNVector3(center.x + extent, center.y + extent * 1.3, center.z + extent)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .omni
        fill.light?.color = UIColor(red: 1, green: 0.76, blue: 0.56, alpha: 1)
        fill.light?.intensity = 550
        fill.position = SCNVector3(center.x - extent, center.y + extent * 0.5, center.z - extent)
        scene.rootNode.addChildNode(fill)
    }

    func updateSpatialHighlight(_ highlight: SpatialHighlight?) {
        guard let scene else { return }
        scene.rootNode.childNode(withName: "spatial-highlight", recursively: false)?.removeFromParentNode()
        guard let highlight else { return }

        let (minimum, maximum) = scene.rootNode.boundingBox
        let center = SCNVector3(
            (minimum.x + maximum.x) / 2,
            (minimum.y + maximum.y) / 2,
            (minimum.z + maximum.z) / 2
        )
        let extent = max(maximum.x - minimum.x, maximum.z - minimum.z, 1)
        let marker = SCNNode(geometry: SCNSphere(radius: CGFloat(extent * 0.07)))
        marker.name = "spatial-highlight"
        marker.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
        marker.geometry?.firstMaterial?.emission.contents = UIColor.systemYellow
        marker.geometry?.firstMaterial?.transparency = 0.8
        marker.position = switch highlight.reference {
        case .north: SCNVector3(center.x, center.y + extent * 0.12, maximum.z)
        case .east: SCNVector3(maximum.x, center.y + extent * 0.12, center.z)
        case .south: SCNVector3(center.x, center.y + extent * 0.12, minimum.z)
        case .west: SCNVector3(minimum.x, center.y + extent * 0.12, center.z)
        case .center: SCNVector3(center.x, center.y + extent * 0.12, center.z)
        }
        scene.rootNode.addChildNode(marker)
        addLabel(text: highlight.label, at: SCNVector3(0, 0, 0), to: marker)
    }

    private func addModelReference(to scene: SCNScene) {
        let (minimum, maximum) = scene.rootNode.boundingBox
        let center = SCNVector3(
            (minimum.x + maximum.x) / 2,
            (minimum.y + maximum.y) / 2,
            (minimum.z + maximum.z) / 2
        )
        let extent = max(maximum.x - minimum.x, maximum.z - minimum.z, 1)
        let labels: [(String, SCNVector3)] = [
            ("N", SCNVector3(center.x, center.y + extent * 0.08, maximum.z)),
            ("E", SCNVector3(maximum.x, center.y + extent * 0.08, center.z)),
            ("S", SCNVector3(center.x, center.y + extent * 0.08, minimum.z)),
            ("W", SCNVector3(minimum.x, center.y + extent * 0.08, center.z)),
        ]
        for (text, position) in labels {
            let node = SCNNode()
            node.name = "model-reference-\(text)"
            node.position = position
            addLabel(text: text, at: SCNVector3(0, 0, 0), to: node)
            scene.rootNode.addChildNode(node)
        }
    }

    private func addLabel(text: String, at position: SCNVector3, to parent: SCNNode) {
        let geometry = SCNText(string: text, extrusionDepth: 0.01)
        geometry.font = UIFont.preferredFont(forTextStyle: .headline)
        geometry.flatness = 0.1
        geometry.firstMaterial?.diffuse.contents = UIColor.white
        geometry.firstMaterial?.emission.contents = UIColor.systemIndigo
        let label = SCNNode(geometry: geometry)
        label.position = position
        label.scale = SCNVector3(0.08, 0.08, 0.08)
        parent.addChildNode(label)
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