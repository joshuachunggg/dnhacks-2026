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
    @Published private(set) var panelFactRequest: PanelFactRequest?
    @Published private(set) var spatialHighlight: SpatialHighlight?
    @Published private(set) var spatialPlacementRequest: SpatialPlacementRequest?
    @Published private(set) var isLevel2EVChargerAssessmentActive = false
    @Published private(set) var isAdjacentRoomExpansionAssessmentActive = false
    @Published private(set) var roomExpansionSummary: String?
    @Published private(set) var roomExpansionInputs: RoomExpansionInputs?
    @Published private(set) var isGuideSpeaking = false
    @Published private(set) var routeWaypointCount = 0

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let realtimeAudioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24_000, channels: 1, interleaved: true)!
    private var inputConverter: AVAudioConverter?
    private var webSocket: URLSessionWebSocketTask?
    private var pendingEvidencePhotoRequest: EvidencePhotoRequest?
    private var pendingPanelFactRequest: PanelFactRequest?
    private var pendingSpatialPlacementRequest: SpatialPlacementRequest?
    private var activeServerBaseURL: URL?
    private var activeAssessmentId: String?
    private var initialCapabilityTool = "activate_level_2_ev_charger_assessment"
    private var routePoses: [SpatialModelPose] = []
    private var hasPlacedElectricalPanel = false
    private var hasPlacedEVSE = false
    private var pendingTranscript = ""
    private var responseDidFinish = false
    private var responseAudioDidFinish = false
    private var scheduledPlaybackBufferCount = 0
    private var playbackGeneration = 0
    private let transcriptCharactersPerSecond = 16.0

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
        initialCapabilityTool = assessmentContext.assessmentFocus.activationToolName
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
        panelFactRequest = nil
        pendingPanelFactRequest = nil
        spatialHighlight = nil
        spatialPlacementRequest = nil
        pendingSpatialPlacementRequest = nil
        activeServerBaseURL = nil
        activeAssessmentId = nil
        routePoses = []
        routeWaypointCount = 0
        hasPlacedElectricalPanel = false
        hasPlacedEVSE = false
        resetResponsePlayback()
        isGuideSpeaking = false
        isLevel2EVChargerAssessmentActive = false
        isAdjacentRoomExpansionAssessmentActive = false
        roomExpansionSummary = nil
        roomExpansionInputs = nil
        status = "Disconnected"
    }

    func startListening() {
        guard isConnected else {
            status = "Connect the Realtime guide before starting voice input."
            return
        }
        guard !isListening else { return }
        interruptGuide()
        isListening = true
        status = "Listening now. Tap Stop talking when you finish your question."
        beginAudioTurn()
    }

    func finishListening() {
        guard isListening else { return }
        stopMicrophone()
        sendEvent(["type": "input_audio_buffer.commit"])
        if isLevel2EVChargerAssessmentActive || isAdjacentRoomExpansionAssessmentActive {
            requestResponse()
        } else {
            requestResponse(requiringTool: initialCapabilityTool)
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
                    ["type": "input_text", "text": "Analyze this requested evidence photo now. In your next response, say only whether the information needed for the current step is sufficient. Do not describe scene details, labels, colors, handwriting, or the panel door. If more information is needed, ask for exactly one missing fact or a clearer photo, then direct the user to that action."],
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

    func completePanelFactRequest(recorded: Bool, message: String) {
        guard let request = panelFactRequest else { return }
        sendEvent([
            "type": "conversation.item.create",
            "item": [
                "type": "function_call_output",
                "call_id": request.callId,
                "output": "{\"recorded\":\(recorded),\"field\":\"\(request.field.rawValue)\",\"certainty\":\"\(request.certainty.rawValue)\",\"message\":\"\(message)\"}",
            ],
        ])
        panelFactRequest = nil
        status = message
        if recorded {
            Task { await advanceLevel2EVWorkflow() }
        } else {
            requestResponse()
        }
    }

    func completeSpatialPlacement(_ pose: SpatialModelPose) {
        guard let request = spatialPlacementRequest else { return }
        let output = "{\"placed\":true,\"kind\":\"\(request.kind.rawValue)\",\"label\":\"\(request.label)\",\"positionMeters\":{\"x\":\(pose.x),\"y\":\(pose.y),\"z\":\(pose.z)},\"surface\":\"\(pose.surface)\",\"engineeringUse\":\"not_eligible\",\"meaning\":\"User-selected model reference only; it is not a feasibility, route-length, code, or approval finding.\"}"
        sendEvent(["type": "conversation.item.create", "item": ["type": "function_call_output", "call_id": request.callId, "output": output]])
        spatialPlacementRequest = nil
        if request.kind == .electricalPanel {
            hasPlacedElectricalPanel = true
        } else if request.kind == .evse {
            hasPlacedEVSE = true
        }
        status = "Spatial placement shared with the guide as a proposed model reference."
        Task { await advanceLevel2EVWorkflow() }
    }

    func completeConceptualOpening(_ pose: SpatialModelPose) {
        guard let request = spatialPlacementRequest else { return }
        let output = "{\"placed\":true,\"kind\":\"candidate_opening\",\"label\":\"\(request.label)\",\"positionMeters\":{\"x\":\(pose.x),\"y\":\(pose.y),\"z\":\(pose.z)},\"meaning\":\"User-selected conceptual opening only; it is not a structural finding, demolition instruction, permit approval, or feasibility conclusion.\"}"
        sendEvent(["type": "conversation.item.create", "item": ["type": "function_call_output", "call_id": request.callId, "output": output]])
        spatialPlacementRequest = nil
        roomExpansionSummary = "Candidate opening shown on the scanned divider wall. A licensed structural professional and permit authority must verify load-bearing conditions, utilities, and approvals before any removal."
        requestResponse()
        status = "Conceptual opening shared with the guide. Structural feasibility remains unverified."
    }

    func addRouteWaypoint(_ pose: SpatialModelPose) {
        routePoses.append(pose)
        routeWaypointCount = routePoses.count
        status = "Route point \(routeWaypointCount) recorded. Add another point or finish the route."
    }

    func finishRouteWaypoints() -> [SpatialModelPose]? {
        guard routePoses.count >= 2 else {
            status = "Add at least two route points before finishing."
            return nil
        }
        let poses = routePoses
        routePoses = []
        routeWaypointCount = 0
        return poses
    }

    func completeRouteWaypoints(_ poses: [SpatialModelPose]) {
        guard let request = spatialPlacementRequest else { return }
        sendEvent(["type": "conversation.item.create", "item": ["type": "function_call_output", "call_id": request.callId, "output": "{\"recorded\":true,\"waypointCount\":\(poses.count)}"]])
        spatialPlacementRequest = nil
        Task { await advanceLevel2EVWorkflow() }
        status = "Route waypoints were recorded and converted to a feet-based route measurement."
    }

    func spatialPlacementFailed(_ message: String) { status = message }

    func interruptGuide() {
        guard isGuideSpeaking else { return }
        sendEvent(["type": "response.cancel"])
        playerNode.stop()
        resetResponsePlayback()
        isGuideSpeaking = false
        status = "Guide interrupted."
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

    private func requestResponse(requiringTool toolName: String? = nil, instructions: String? = nil) {
        responseText = ""
        resetResponsePlayback()
        var response: [String: Any] = [:]
        if let toolName {
            response["tool_choice"] = [
                "type": "function",
                "name": toolName,
            ]
        }
        if let instructions {
            response["instructions"] = instructions
        }
        sendEvent(["type": "response.create", "response": response])
    }

    private func configureRealtimeAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
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

    private func advanceLevel2EVWorkflow() async {
        guard isLevel2EVChargerAssessmentActive,
              let activeServerBaseURL,
              let activeAssessmentId
        else {
            requestResponse()
            return
        }
        var request = URLRequest(url: activeServerBaseURL
            .appendingPathComponent("api/assessments")
            .appendingPathComponent(activeAssessmentId)
            .appendingPathComponent("assessment-gate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "RealtimeSession", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            let gate = try JSONDecoder().decode(MechanicalAssessmentGateResponse.self, from: data).gate
            switch gate.nextAction {
            case "capture_panel_image":
                requestResponse(
                    requiringTool: "request_evidence_photo",
                    instructions: "Say only: ‘Take or upload a clear photo of the electrical panel now.’ Then call request_evidence_photo for electrical_panel in this same response. Do not say that you are moving to another step."
                )
            case "confirm_panel_facts":
                requestResponse(instructions: "Ask only for the next missing panel value. Name the value and ask the user to say it now; do not say that the workflow can move on. When the user supplies or confirms a number, immediately call record_panel_fact; do not ask a separate confirmation question.")
            case "place_panel_location":
                requestResponse(
                    requiringTool: "request_spatial_placement",
                    instructions: "Say only: ‘Tap the electrical panel on the room model now.’ Then call request_spatial_placement for electrical_panel in this same response. Do not say that you are moving to another step."
                )
            case "place_evse_location":
                requestResponse(
                    requiringTool: "request_spatial_placement",
                    instructions: "Say only: ‘Tap the proposed charger location on the room model now.’ Then call request_spatial_placement for evse in this same response. Do not say that you are moving to another step."
                )
            case "record_route_waypoints":
                requestResponse(
                    requiringTool: "request_spatial_placement",
                    instructions: "Say only: ‘Tap the cable route on the room model, then tap Finish route.’ Then call request_spatial_placement for route_point in this same response. Do not say that you are moving to another step."
                )
            case "finish_and_review":
                requestResponse(instructions: "State the deterministic planning result concisely and tell the user to tap Finish and review.")
            default:
                requestResponse()
            }
        } catch {
            status = "Could not advance the assessment workflow: \(error.localizedDescription)"
            requestResponse()
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
            pendingTranscript += event["delta"] as? String ?? ""
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
                requestResponse(
                    requiringTool: "request_evidence_photo",
                    instructions: "Say only: ‘Take or upload a clear photo of the electrical panel now.’ Then call request_evidence_photo for electrical_panel in this same response. Do not say that you are moving to another step."
                )
                status = "Level 2 EV charger assessment activated."
                return
            }
            if name == "activate_adjacent_room_expansion_assessment" {
                isAdjacentRoomExpansionAssessmentActive = true
                sendEvent([
                    "type": "conversation.item.create",
                    "item": [
                        "type": "function_call_output",
                        "call_id": callId,
                        "output": "{\"activated\":true,\"capability\":\"adjacent_room_expansion\",\"claimBoundary\":\"conceptual only; no structural feasibility, demolition, permit, or approval finding\"}",
                    ],
                ])
                requestResponse()
                status = "Conceptual adjacent-room expansion review activated."
                return
            }
            if name == "check_mechanical_assessment_gate" {
                Task { await self.completeMechanicalAssessmentGate(callId: callId) }
                return
            }
            if name == "record_room_expansion_inputs" {
                guard
                    isAdjacentRoomExpansionAssessmentActive,
                    let arguments = event["arguments"] as? String,
                    let data = arguments.data(using: .utf8),
                    let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let utilities = payload["sharedWallUtilities"] as? String,
                    let typedUtilities = RoomExpansionAnswer(rawValue: utilities),
                    let exteriorPossible = payload["exteriorExpansionPossible"] as? Bool,
                    let loadBearing = payload["loadBearingKnowledge"] as? String,
                    let typedLoadBearing = RoomExpansionAnswer(rawValue: loadBearing)
                else {
                    status = "The guide sent invalid room-expansion inputs."
                    return
                }
                let inputs = RoomExpansionInputs(sharedWallUtilities: typedUtilities, exteriorExpansionPossible: exteriorPossible, loadBearingKnowledge: typedLoadBearing)
                roomExpansionInputs = inputs
                let recommendation = inputs.recommendsSharedWallOpening ? "shared_wall_opening" : "compare_exterior_expansion"
                sendEvent(["type": "conversation.item.create", "item": [
                    "type": "function_call_output",
                    "call_id": callId,
                    "output": "{\"recorded\":true,\"recommendation\":\"\(recommendation)\",\"claimBoundary\":\"conceptual option only; structural feasibility and utilities remain unverified\"}",
                ]])
                requestResponse()
                return
            }
            if name == "record_panel_fact" {
                guard
                    let arguments = event["arguments"] as? String,
                    let data = arguments.data(using: .utf8),
                    let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let field = payload["field"] as? String,
                    let typedField = PanelFactField(rawValue: field),
                    let value = payload["value"] as? Int,
                    let certainty = payload["certainty"] as? String,
                    let typedCertainty = PanelFactCertainty(rawValue: certainty)
                else {
                    status = "The guide sent an invalid panel fact."
                    return
                }
                pendingPanelFactRequest = PanelFactRequest(callId: callId, field: typedField, value: value, certainty: typedCertainty)
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
                if let active = spatialPlacementRequest ?? pendingSpatialPlacementRequest {
                    sendEvent([
                        "type": "conversation.item.create",
                        "item": [
                            "type": "function_call_output",
                            "call_id": callId,
                            "output": "{\"accepted\":false,\"reason\":\"Already waiting for the user to place \(active.kind.rawValue).\"}",
                        ],
                    ])
                    status = "Finish the current \(active.kind.displayName) placement before asking for another one."
                    return
                }
                if typedKind == .evse, !hasPlacedElectricalPanel {
                    sendEvent([
                        "type": "conversation.item.create",
                        "item": [
                            "type": "function_call_output",
                            "call_id": callId,
                            "output": "{\"accepted\":false,\"reason\":\"The electrical panel must be placed on the model before the proposed charger location.\"}",
                        ],
                    ])
                    status = "Place the electrical panel on the model before placing the proposed charger."
                    requestResponse()
                    return
                }
                if typedKind == .candidateOpening, !isAdjacentRoomExpansionAssessmentActive || roomExpansionInputs?.recommendsSharedWallOpening != true {
                    sendEvent(["type": "conversation.item.create", "item": [
                        "type": "function_call_output",
                        "call_id": callId,
                        "output": "{\"accepted\":false,\"reason\":\"Record the three room-expansion inputs first; only a no-exterior option may show a conceptual shared-wall cutaway.\"}",
                    ]])
                    requestResponse()
                    return
                }
                if (typedKind == .electricalPanel && hasPlacedElectricalPanel) || (typedKind == .evse && hasPlacedEVSE) {
                    sendEvent([
                        "type": "conversation.item.create",
                        "item": [
                            "type": "function_call_output",
                            "call_id": callId,
                            "output": "{\"accepted\":false,\"reason\":\"That model reference is already placed. Ask for the next missing action.\"}",
                        ],
                    ])
                    requestResponse()
                    return
                }
                pendingSpatialPlacementRequest = SpatialPlacementRequest(callId: callId, kind: typedKind, label: label, instruction: instruction)
                return
            }
            if name == "request_evidence_photo", isAdjacentRoomExpansionAssessmentActive {
                sendEvent(["type": "conversation.item.create", "item": [
                    "type": "function_call_output",
                    "call_id": callId,
                    "output": "{\"accepted\":false,\"reason\":\"Room expansion uses only the three typed questions and a user-selected wall; no photo, nameplate, or label is needed.\"}",
                ]])
                requestResponse()
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
            if isLevel2EVChargerAssessmentActive, typedEvidenceKind != .electricalPanel {
                sendEvent(["type": "conversation.item.create", "item": [
                    "type": "function_call_output",
                    "call_id": callId,
                    "output": "{\"accepted\":false,\"reason\":\"Only the electrical-panel photo is supported in this EV assessment. Use the room-model tap flow for the charger area and route.\"}",
                ]])
                requestResponse()
                return
            }
            pendingEvidencePhotoRequest = EvidencePhotoRequest(callId: callId, evidenceKind: typedEvidenceKind, reason: reason)
        case "response.output_audio.delta":
            if let encoded = event["delta"] as? String, let audio = Data(base64Encoded: encoded) {
                playRealtimePCM(audio)
            }
        case "response.output_audio.done":
            responseAudioDidFinish = true
            finishResponseAfterPlayback()
        case "response.done":
            responseDidFinish = true
            if !responseContainsOutputAudio(event) {
                responseAudioDidFinish = true
            }
            finishResponseAfterPlayback()
        case "error":
            status = "Realtime error: \((event["error"] as? [String: Any])?["message"] as? String ?? "unknown error")"
        default:
            break
        }
    }

    private func playRealtimePCM(_ data: Data) {
        let frameCount = AVAudioFrameCount(data.count / MemoryLayout<Int16>.size)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: realtimeAudioFormat, frameCapacity: frameCount),
              let channel = buffer.int16ChannelData?[0]
        else { return }
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
        let generation = playbackGeneration
        scheduledPlaybackBufferCount += 1
        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in
                guard let self, generation == self.playbackGeneration else { return }
                self.scheduledPlaybackBufferCount = max(0, self.scheduledPlaybackBufferCount - 1)
                self.drainTranscript(for: Double(frameCount) / self.realtimeAudioFormat.sampleRate)
                self.finishResponseAfterPlayback()
            }
        }
        isGuideSpeaking = true
    }

    private func drainTranscript(for audioSeconds: Double) {
        guard !pendingTranscript.isEmpty else { return }
        let count = min(pendingTranscript.count, max(1, Int((audioSeconds * transcriptCharactersPerSecond).rounded(.up))))
        let end = pendingTranscript.index(pendingTranscript.startIndex, offsetBy: count)
        responseText += String(pendingTranscript[..<end])
        pendingTranscript.removeSubrange(..<end)
    }

    private func responseContainsOutputAudio(_ event: [String: Any]) -> Bool {
        guard let response = event["response"] as? [String: Any],
              let output = response["output"] as? [[String: Any]] else { return false }
        return output.contains { item in
            guard let content = item["content"] as? [[String: Any]] else { return false }
            return content.contains { ($0["type"] as? String) == "output_audio" }
        }
    }

    private func resetResponsePlayback() {
        playbackGeneration += 1
        pendingTranscript = ""
        responseDidFinish = false
        responseAudioDidFinish = false
        scheduledPlaybackBufferCount = 0
    }

    private func finishResponseAfterPlayback() {
        guard responseDidFinish, responseAudioDidFinish, scheduledPlaybackBufferCount == 0 else { return }
        if !pendingTranscript.isEmpty {
            responseText += pendingTranscript
            pendingTranscript = ""
        }
        isGuideSpeaking = false
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
        if let pendingPanelFactRequest {
            panelFactRequest = pendingPanelFactRequest
            self.pendingPanelFactRequest = nil
            status = "Recording the guide-confirmed \(panelFactRequest?.field.displayName ?? "") panel fact."
            return
        }
        status = "Guide response ready."
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

private struct MechanicalAssessmentGateResponse: Decodable {
    let gate: MechanicalAssessmentGate
}

private struct MechanicalAssessmentGate: Decodable {
    let nextAction: String
}

enum PanelFactField: String {
    case serviceAmps = "service_amps"
    case busRatingAmps = "bus_rating_amps"
    case spareBreakerSpaces = "spare_breaker_spaces"

    var displayName: String { rawValue.replacingOccurrences(of: "_", with: " ") }
    var unit: String? { self == .spareBreakerSpaces ? nil : "A" }
}

enum PanelFactCertainty: String {
    case known
    case approximation
}

struct PanelFactRequest: Identifiable {
    let callId: String
    let field: PanelFactField
    let value: Int
    let certainty: PanelFactCertainty

    var id: String { callId }
}

enum EvidencePhotoKind: String {
    case electricalPanel = "electrical_panel"
    case chargerLocation = "charger_location"
    case routeObstacle = "route_obstacle"
    case equipmentNameplate = "equipment_nameplate"

    var displayName: String { rawValue.replacingOccurrences(of: "_", with: " ") }
}

enum RoomExpansionAnswer: String {
    case yes
    case no
    case unknown
}

struct RoomExpansionInputs: Equatable {
    let sharedWallUtilities: RoomExpansionAnswer
    let exteriorExpansionPossible: Bool
    let loadBearingKnowledge: RoomExpansionAnswer

    var recommendsSharedWallOpening: Bool { !exteriorExpansionPossible }
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
    case candidateOpening = "candidate_opening"

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
    let normalX: Float
    let normalY: Float
    let normalZ: Float
    let surface: String
    let modelRelativeWall: String?
    let alongWallMeters: Float?
    let heightAboveModelFloorMeters: Float?
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
    let assessmentFocus: AssessmentFocus
}

enum AssessmentFocus: String, CaseIterable, Identifiable, Encodable {
    case evCharger = "level_2_ev_charger"
    case roomExpansion = "adjacent_room_expansion"

    var id: String { rawValue }
    var displayName: String {
        self == .evCharger ? "EV charger placement" : "Adjacent-room expansion"
    }
    var activationToolName: String {
        self == .evCharger ? "activate_level_2_ev_charger_assessment" : "activate_adjacent_room_expansion_assessment"
    }
}

private struct RealtimeClientSecretResponse: Decodable {
    let clientSecret: String
    let expiresAt: Int
    let sessionId: String
}
