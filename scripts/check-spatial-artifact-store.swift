import Foundation

@main
struct SpatialArtifactStoreCheck {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("dnhacks-spatial-artifact-check-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try LocalSpatialArtifactStore(directoryURL: directory)
        let artifact = try store.persist(
            data: Data([0x01, 0x02, 0x03]),
            id: "artifact-room-001",
            kind: .roomUSDZ,
            contentType: "model/vnd.usdz+zip"
        )

        precondition(artifact.id == "artifact-room-001")
        precondition(artifact.kind == .roomUSDZ)
        precondition(artifact.byteLength == 3)
        precondition(artifact.sha256.count == 64)
        guard let localFileURL = artifact.localFileURL else {
            preconditionFailure("Persisted local artifact must expose a file URL for Quick Look preview")
        }
        precondition(FileManager.default.fileExists(atPath: localFileURL.path))
        print("Spatial artifact local persistence check passed.")
    }
}
