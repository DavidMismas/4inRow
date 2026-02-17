import AVFoundation

/// Synthesizes sound effects using AVFoundation tone generation.
/// No external audio files needed.
@MainActor
final class SoundService {

    static let shared = SoundService()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    private init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            audioEngine = engine
            playerNode = player
        } catch {
            // Audio unavailable — game still works without sound
        }
    }

    // MARK: - Sound Effects

    /// Short percussive "thud" for disc landing.
    func playDrop() {
        playTone(frequency: 220, duration: 0.08, fadeOut: true)
    }

    /// Ascending triumphant chord.
    func playWin() {
        playTone(frequency: 523, duration: 0.12, fadeOut: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.playTone(frequency: 659, duration: 0.12, fadeOut: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [weak self] in
            self?.playTone(frequency: 784, duration: 0.2, fadeOut: true)
        }
    }

    /// Descending sad tones.
    func playLose() {
        playTone(frequency: 392, duration: 0.15, fadeOut: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.playTone(frequency: 330, duration: 0.15, fadeOut: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.playTone(frequency: 262, duration: 0.25, fadeOut: true)
        }
    }

    /// Flat tone for draw.
    func playDraw() {
        playTone(frequency: 349, duration: 0.3, fadeOut: true)
    }

    /// Short buzz for invalid move.
    func playInvalid() {
        playTone(frequency: 150, duration: 0.1, fadeOut: true)
    }

    // MARK: - Tone Synthesis

    private func playTone(frequency: Double, duration: Double, fadeOut: Bool) {
        guard let engine = audioEngine, let player = playerNode, engine.isRunning else { return }

        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData?[0] else { return }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample = Float(sin(2.0 * .pi * frequency * t))

            // Envelope: quick attack, optional fade-out
            let position = Double(i) / Double(frameCount)
            let attack = min(Float(position / 0.01), 1.0)
            let release: Float = fadeOut ? Float(1.0 - position) : 1.0
            sample *= attack * release * 0.3  // 0.3 = volume

            data[i] = sample
        }

        if player.isPlaying {
            player.stop()
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }
}
