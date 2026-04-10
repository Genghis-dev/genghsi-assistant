import Foundation
import AVFoundation

@Observable
final class SpeechSynthesizer {
    static let shared = SpeechSynthesizer()

    var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private let delegate = SynthesizerDelegate()

    private init() {
        synthesizer.delegate = delegate
        delegate.onFinish = { [weak self] in
            DispatchQueue.main.async {
                self?.isSpeaking = false
            }
        }
    }

    func speak(_ text: String) {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8

        // Use a natural-sounding voice if available
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}

private class SynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
}
