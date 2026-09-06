@preconcurrency import AVFoundation
import Foundation
@MainActor
final class RealtimeSessionClient: NSObject, ObservableObject {
    @Published private(set) var status = "Disconnected"
    @Published private(set) var transcript = ""
    @Published private(set) var responseText = ""
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published private(set) var isListening = false
    @Published private(set) var evidencePhotoRequest: EvidencePhotoRequest?
    @Published private(set) var spatialHighlight: SpatialHighlight?
    @Published private(set) var spatialPlacementRequest: SpatialPlacementRequest?
    @Published private(set) var isLevel2EVChargerAssessmentActive = false

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let realtimeAudioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24_000, channels: 1, interleaved: true)!
    private var inputConverter: AVAudioConverter?
    private var webSocket: URLSessionWebSocketTask?
    private var pendingEvidencePhotoRequest: EvidencePhotoRequest?
    private var pendingSpatialPlacementRequest: SpatialPlacementRequest?
    private var activeServerBaseURL: URL?
    private var activeAssessmentId: String?

    override init() {
        super.init()
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: realtimeAudioFormat)
    }

    func connect(
        serverBaseURL: URL,
        demoToken: String,
        assessmentId: String,
        assessmentContext: RealtimeAssessmentContext
    ) async {
        guard !isConnecting, !isConnected else { return }
        guard !demoToken.isEmpty else {
            status = "Enter the Realtime demo token configured on the server."
            return
        }
        isConnecting = true
        status = "Connecting to the guide…"
        do {
            let secret = try await mintClientSecret(
                serverBaseURL: serverBaseURL,
                demoToken: demoToken,
                assessmentId: assessmentId,
                assessmentContext: assessmentContext
            )
            var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime?model=gpt-realtime-2.1-mini")!)
            request.setValue("Bearer \(secret.clientSecret)", forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.webSocketTask(with: request)
            webSocket = task
            activeServerBaseURL = serverBaseURL
            activeAssessmentId = assessmentId
            task.resume()
            receiveNextEvent()
        } catch {
            status = "Realtime connection failed: \(error.localizedDescription)"
            isConnected = false
            isConnecting = false
        }
    }

    func disconnect() {
        stopListening()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        playerNode.stop()
        audioEngine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isConnected = false
        isConnecting = false
        evidencePhotoRequest = nil
        pendingEvidencePhotoRequest = nil
        spatialHighlight = nil
        spatialPlacementRequest = nil
        pendingSpatialPlacementRequest = nil
        activeServerBaseURL = nil
        activeAssessmentId = nil
        isLevel2EVChargerAssessmentActive = false
        status = "Disconnected"
    }

    func startListening() {
        guard isConnected else {
            status = "Connect the Realtime guide before starting voice input."
            return
        }
        guard !isListening else { return }
        isListening = true
        status = "Listening now. Tap Stop talking when you finish your question."
        beginAudioTurn()
    }

    func finishListening() {
        guard isListening else { return }
        stopMicrophone()
        sendEvent(["type": "input_audio_buffer.commit"])
        if isLevel2EVChargerAssessmentActive {
            requestResponse()
        } else {
            requestResponse(requiringTool: "activate_level_2_ev_charger_assessment")
        }
        status = "Thinking…"
    }

    func stopListening() {
        stopMicrophone()
    }

    func connectionFailed(_ message: String) {
        disconnect()
        status = message
    }

    private func stopMicrophone() {
        guard isListening else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false
    }

    func sendPanelImage(_ imageData: Data) {
        sendEvidenceImage(imageData, fulfilling: evidencePhotoRequest)
    }

    func sendEvidenceImage(_ imageData: Data, fulfilling request: EvidencePhotoRequest?) {
        guard isConnected else { return }
        let imageURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
        sendEvent([
            "type": "conversation.item.create",
            "item": [
                "type": "message",
                "role": "user",
                "content": [
                    ["type": "input_text", "text": "Analyze this requested evidence photo now. In your next response, explain the visible non-authoritative observations you can make and ask only for the clarification needed to continue the Level 2 EV charger assessment."],
                    ["type": "input_image", "image_url": imageURL],
                ],
            ],
        ])
        if let request {
            sendEvent([
                "type": "conversation.item.create",
                "item": [
                    "type": "function_call_output",
                    "call_id": request.callId,
                    "output": "{\"captured\":true,\"evidenceKind\":\"\(request.evidenceKind.rawValue)\"}",
                ],
            ])
            evidencePhotoRequest = nil
        }
        requestResponse()
        status = "Evidence photo sent to the Realtime guide for proposed observations."
    }

    func cancelEvidencePhotoRequest() {
        guard let request = evidencePhotoRequest else { return }
        sendEvent([
            "type": "conversation.item.create",
            "item": [
                "type": "function_call_output",
                "call_id": request.callId,
                "output": "{\"captured\":false,\"reason\":\"The user cancelled the photo request.\"}",
            ],
        ])
        evidencePhotoRequest = nil
        requestResponse()
        status = "Photo request cancelled."
    }

    func completeSpatialPlacement(_ pose: SpatialModelPose) {
        guard let request = spatialPlacementRequest else { return }
        let output = "{\"placed\":true,\"kind\":\"\(request.kind.rawValue)\",\"label\":\"\(request.label)\",\"positionMeters\":{\"x\":\(pose.x),\"y\":\(pose.y),\"z\":\(pose.z)},\"surface\":\"\(pose.surface)\",\"engineeringUse\":\"not_eligible\",\"meaning\":\"User-selected model reference only; it is not a feasibility, route-length, code, or approval finding.\"}"
        sendEvent(["type": "conversation.item.create", "item": ["type": "function_call_output", "call_id": request.callId, "output": output]])
        spatialPlacementRequest = nil
        requestResponse()
        status = "Spatial placement shared with the guide as a proposed model reference."
    }

    private func beginAudioTurn() {
        do {
            try configureRealtimeAudioSession()
            transcript = ""
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            guard let converter = AVAudioConverter(from: format, to: realtimeAudioFormat) else {
                status = "Could not convert microphone audio for Realtime."
                stopListening()
                return
            }
            inputConverter = converter
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                Task { @MainActor [weak self] in
                    guard let self, self.isListening, let audio = self.realtimePCMData(from: buffer) else { return }
                    self.sendEvent([
                        "type": "input_audio_buffer.append",
                        "audio": audio.base64EncodedString(),
                    ])
                }
            }
            audioEngine.prepare()
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
        } catch {
            status = "Could not start Realtime voice input: \(error.localizedDescription)"
            stopListening()
        }
    }

    private func realtimePCMData(from input: AVAudioPCMBuffer) -> Data? {
        guard let converter = inputConverter else { return nil }
        let capacity = AVAudioFrameCount((Double(input.frameLength) * realtimeAudioFormat.sampleRate / input.format.sampleRate).rounded(.up))
        guard let output = AVAudioPCMBuffer(pcmFormat: realtimeAudioFormat, frameCapacity: capacity) else { return nil }
        var consumed = false
        var conversionError: NSError?
        let conversionStatus = converter.convert(to: output, error: &conversionError) { _, outputStatus in
            if consumed {
                outputStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outputStatus.pointee = .haveData
            return input
        }
        guard conversionStatus != .error, conversionError == nil, let channel = output.int16ChannelData?[0] else { return nil }
        return Data(bytes: channel, count: Int(output.frameLength) * MemoryLayout<Int16>.size)
    }

    private func requestResponse(requiringTool toolName: String? = nil) {
        responseText = ""
        var response: [String: Any] = [:]
        if let toolName {
            response["tool_choice"] = [
                "type": "function",
                "name": toolName,
            ]
        }
        sendEvent(["type": "response.create", "response": response])
    }

    private func configureRealtimeAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        try session.overrideOutputAudioPort(.speaker)
    }

    private func completeMechanicalAssessmentGate(callId: String) async {
        guard let activeServerBaseURL, let activeAssessmentId else {
            status = "The assessment gate is unavailable until the guide is connected to an assessment."
            return
        }
        var request = URLRequest(url: activeServerBaseURL.appendingPathComponent("api/assessments").appendingPathComponent(activeAssessmentId).appendingPathComponent("assessment-gate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "RealtimeSession", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            sendEvent(["type": "conversation.item.create", "item": ["type": "function_call_output", "call_id": callId, "output": String(decoding: data, as: UTF8.self)]])
            requestResponse()
        } catch {
            status = "The deterministic assessment gate failed: \(error.localizedDescription)"
        }
    }

    private func sendEvent(_ event: [String: Any]) {
        guard let webSocket else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: event)
            webSocket.send(.string(String(decoding: data, as: UTF8.self))) { [weak self] error in
                if let error {
                    Task { @MainActor in self?.status = "Realtime send failed: \(error.localizedDescription)" }
                }
            }
        } catch {
            status = "Could not encode Realtime event: \(error.localizedDescription)"
        }
    }

    private func receiveNextEvent() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let message):
                    self.handle(message)
                    self.receiveNextEvent()
                case .failure(let error):
                    guard self.webSocket != nil else { return }
                    self.status = "Realtime connection ended: \(error.localizedDescription)"
                    self.isConnected = false
                    self.isConnecting = false
                    self.webSocket = nil
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .data(let value): data = value
        case .string(let value): data = Data(value.utf8)
        @unknown default: return
        }
        guard let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["type"] as? String else { return }
        switch type {
        case "session.created":
            isConnecting = false
            isConnected = true
            status = "Connected. Tap Talk to stream directly to the spatial guide."
            sendEvent([
                "type": "session.update",
                "session": [
                    "type": "realtime",
                    "output_modalities": ["audio"],
                    "audio": [
                        "input": [
                            "format": ["type": "audio/pcm", "rate": 24_000],
                            "turn_detection": NSNull(),
                        ],
                        "output": [
                            "format": ["type": "audio/pcm", "rate": 24_000],
                            "voice": "marin",
                        ],
                    ],
                ],
            ])
        case "response.output_audio_transcript.delta", "response.output_text.delta":
            responseText += event["delta"] as? String ?? ""
        case "response.function_call_arguments.done":
            guard let name = event["name"] as? String, let callId = event["call_id"] as? String else {
                status = "The guide sent an invalid tool request."
                return
            }
            if name == "activate_level_2_ev_charger_assessment" {
                isLevel2EVChargerAssessmentActive = true
                sendEvent([
                    "type": "conversation.item.create",
                    "item": [
                        "type": "function_call_output",
                        "call_id": callId,
                        "output": "{\"activated\":true,\"capability\":\"level_2_ev_charger\"}",
                    ],
                ])
                requestResponse()
                status = "Level 2 EV charger assessment activated."
                return
            }
            if name == "check_mechanical_assessment_gate" {
                Task { await self.completeMechanicalAssessmentGate(callId: callId) }
                return
            }
            if name == "highlight_spatial_reference" {
                guard
                    let arguments = event["arguments"] as? String,
                    let data = arguments.data(using: .utf8),
                    let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let reference = payload["reference"] as? String,
                    let typedReference = SpatialReference(rawValue: reference),
                    let label = payload["label"] as? String
                else {
                    status = "The guide sent an invalid spatial highlight."
                    return
                }
                spatialHighlight = SpatialHighlight(reference: typedReference, label: label)
                sendEvent([
                    "type": "conversation.item.create",
                    "item": [
                        "type": "function_call_output",
                        "call_id": callId,
                        "output": "{\"highlighted\":true,\"reference\":\"\(reference)\"}",
                    ],
                ])
                requestResponse()
                return
            }
            if name == "request_spatial_placement" {
                guard
                    let arguments = event["arguments"] as? String,
                    let data = arguments.data(using: .utf8),
                    let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let kind = payload["kind"] as? String,
                    let typedKind = SpatialPlacementKind(rawValue: kind),
                    let label = payload["label"] as? String,
                    let instruction = payload["instruction"] as? String
                else {
                    status = "The guide sent an invalid spatial placement request."
                    return
                }
                pendingSpatialPlacementRequest = SpatialPlacementRequest(callId: callId, kind: typedKind, label: label, instruction: instruction)
                return
            }
            guard
                name == "request_evidence_photo",
                let arguments = event["arguments"] as? String,
                let data = arguments.data(using: .utf8),
                let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let evidenceKind = payload["evidenceKind"] as? String,
                let typedEvidenceKind = EvidencePhotoKind(rawValue: evidenceKind),
                let reason = payload["reason"] as? String
            else {
                status = "The guide sent an invalid evidence-photo request."
                return
            }
            pendingEvidencePhotoRequest = EvidencePhotoRequest(callId: callId, evidenceKind: typedEvidenceKind, reason: reason)
        case "response.output_audio.delta":
            if let encoded = event["delta"] as? String, let audio = Data(base64Encoded: encoded) {
                playRealtimePCM(audio)
            }
        case "response.done":
            if let pendingSpatialPlacementRequest {
                spatialPlacementRequest = pendingSpatialPlacementRequest
                self.pendingSpatialPlacementRequest = nil
                status = "The guide is ready for a \(spatialPlacementRequest?.kind.displayName ?? "") placement."
                return
            }
            if let pendingEvidencePhotoRequest {
                evidencePhotoRequest = pendingEvidencePhotoRequest
                self.pendingEvidencePhotoRequest = nil
                status = "The guide needs a \(evidencePhotoRequest?.evidenceKind.displayName ?? "") photo."
                return
            }
            status = "Guide response ready."
        case "error":
            status = "Realtime error: \((event["error"] as? [String: Any])?["message"] as? String ?? "unknown error")"
        default:
            break
        }
    }

    private func playRealtimePCM(_ data: Data) {
        let frameCount = AVAudioFrameCount(data.count / MemoryLayout<Int16>.size)
        guard frameCount > 0, let buffer = AVAudioPCMBuffer(pcmFormat: realtimeAudioFormat, frameCapacity: frameCount), let channel = buffer.int16ChannelData?[0] else { return }
        buffer.frameLength = frameCount
        channel.withMemoryRebound(to: UInt8.self, capacity: data.count) { destination in
            data.copyBytes(to: destination, count: data.count)
        }
        if !audioEngine.isRunning {
            do {
                try configureRealtimeAudioSession()
                audioEngine.prepare()
                try audioEngine.start()
            } catch {
                status = "Could not play Realtime audio: \(error.localizedDescription)"
                return
            }
        }
        if !playerNode.isPlaying { playerNode.play() }
        playerNode.scheduleBuffer(buffer)
    }

    private func mintClientSecret(
        serverBaseURL: URL,
        demoToken: String,
        assessmentId: String,
        assessmentContext: RealtimeAssessmentContext
    ) async throws -> RealtimeClientSecretResponse {
        var request = URLRequest(url: serverBaseURL.appendingPathComponent("api/realtime/session"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RealtimeClientSecretRequest(
            assessmentId: assessmentId,
            demoToken: demoToken,
            assessmentContext: assessmentContext
        ))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "RealtimeSession", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Could not mint a Realtime client secret."])
        }
        return try JSONDecoder().decode(RealtimeClientSecretResponse.self, from: data)
    }
}

struct EvidencePhotoRequest: Identifiable {
    let callId: String
    let evidenceKind: EvidencePhotoKind
    let reason: String

    var id: String { callId }
}

enum EvidencePhotoKind: String {
    case electricalPanel = "electrical_panel"
    case chargerLocation = "charger_location"
    case routeObstacle = "route_obstacle"
    case equipmentNameplate = "equipment_nameplate"

    var displayName: String { rawValue.replacingOccurrences(of: "_", with: " ") }
}

enum SpatialReference: String {
    case north
    case east
    case south
    case west
    case center
}

struct SpatialHighlight: Equatable {
    let reference: SpatialReference
    let label: String
}

enum SpatialPlacementKind: String {
    case electricalPanel = "electrical_panel"
    case evse
    case routePoint = "route_point"

    var displayName: String { rawValue.replacingOccurrences(of: "_", with: " ") }
}

struct SpatialPlacementRequest: Identifiable {
    let callId: String
    let kind: SpatialPlacementKind
    let label: String
    let instruction: String

    var id: String { callId }
}

struct SpatialModelPose {
    let x: Float
    let y: Float
    let z: Float
    let surface: String
}

private struct RealtimeClientSecretRequest: Encodable {
    let assessmentId: String
    let demoToken: String
    let assessmentContext: RealtimeAssessmentContext
}

struct RealtimeAssessmentContext: Encodable {
    let propertyAddress: String
    let vehicleIntent: String
    let chargingIntent: String
}

private struct RealtimeClientSecretResponse: Decodable {
    let clientSecret: String
    let expiresAt: Int
    let sessionId: String
}
