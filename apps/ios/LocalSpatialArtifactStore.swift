import CryptoKit
import Foundation

final class LocalSpatialArtifactStore {
    private let directoryURL: URL

    init(directoryURL: URL) throws {
        self.directoryURL = directoryURL
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func persist(
        data: Data,
        id: String,
        kind: SpatialArtifact.Kind,
        contentType: String
    ) throws -> SpatialArtifact {
        precondition(!id.isEmpty, "Artifact ID must not be empty")
        let fileURL = directoryURL.appendingPathComponent("\(id).\(fileExtension(for: kind))")
        try data.write(to: fileURL, options: .atomic)

        return SpatialArtifact(
            id: id,
            kind: kind,
            uri: fileURL.absoluteString,
            contentType: contentType,
            byteLength: data.count,
            sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        )
    }

    static func isRetained(_ artifact: SpatialArtifact) -> Bool {
        guard let fileURL = artifact.localFileURL,
              let data = try? Data(contentsOf: fileURL),
              data.count == artifact.byteLength else {
            return false
        }
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return digest.caseInsensitiveCompare(artifact.sha256) == .orderedSame
    }

    private func fileExtension(for kind: SpatialArtifact.Kind) -> String {
        switch kind {
        case .roomPlanJSON:
            return "json"
        case .roomUSDZ:
            return "usdz"
        case .panelImage:
            return "jpg"
        case .roomPreview:
            return "png"
        }
    }
}
