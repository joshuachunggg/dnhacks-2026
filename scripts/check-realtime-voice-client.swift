import Foundation

@main
struct RealtimeVoiceClientCheck {
    static func main() throws {
        let sourceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("apps/ios/RealtimeSessionClient.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        precondition(!source.contains("SFSpeechRecognizer"), "Realtime audio must not use on-device speech recognition.")
        precondition(!source.contains("AVSpeechSynthesizer"), "Realtime audio must not fall back to native text-to-speech.")
        precondition(source.contains("input_audio_buffer.append"), "Microphone PCM must stream directly to Realtime.")
        precondition(source.contains("input_audio_buffer.commit"), "Releasing Talk must commit the captured Realtime audio turn.")
        precondition(source.contains("isListening = true\n        status = \"Listening now."), "Talk must visibly enter the listening state before microphone startup completes.")
        precondition(source.contains("isConnecting"), "Connection state must be distinct from a ready voice connection.")
        precondition(source.contains("audioEngine.stop()"), "Disconnect must stop active Realtime audio capture and playback.")
        precondition(source.contains("webSocket = nil"), "Disconnect must release the Realtime WebSocket.")
        precondition(source.contains("response.output_audio.delta"), "Realtime output PCM must be played directly.")
        precondition(source.contains("requiringTool: \"activate_level_2_ev_charger_assessment\""), "The first supported voice turn must activate the typed EV charger assessment through its native tool.")
        precondition(source.contains("pendingEvidencePhotoRequest"), "The native camera transition must wait until the guide's spoken response completes.")
        precondition(source.contains("highlight_spatial_reference"), "The client must render the guide's typed model-reference highlights.")
        precondition(source.contains("assessmentContext: RealtimeAssessmentContext"), "Realtime minting must include typed assessment context.")
        precondition(source.contains("Analyze this requested evidence photo now."), "Requested evidence photos must prompt an immediate visual response.")
        precondition(source.contains("overrideOutputAudioPort(.speaker)"), "Realtime playback must route to the device loudspeaker instead of the receiver.")
        precondition(!source.contains("mode: .voiceChat"), "Realtime playback must not use phone-call audio routing.")
        precondition(source.contains("\"type\": \"realtime\""), "Realtime session updates must declare the required session type.")
        precondition(source.contains("\"output\": [\n                            \"format\": [\"type\": \"audio/pcm\", \"rate\": 24_000]"), "PCM output format must declare its required sample rate.")
        precondition(
            source.contains("webSocket.send(.string(String(decoding: data, as: UTF8.self)))"),
            "Realtime JSON events must use text WebSocket frames."
        )
        print("Realtime voice turn delivery check passed.")
    }
}
