import AVFoundation
import SpriteKit

class AudioManager {
    static let shared = AudioManager()
    
    var isSoundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "SoundEnabled") == nil { return true }
            return UserDefaults.standard.bool(forKey: "SoundEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "SoundEnabled")
            ICloudSyncManager.shared.pushValue(newValue, forKey: "SoundEnabled")
            if !newValue {
                backgroundMusicPlayer?.pause()
            } else {
                backgroundMusicPlayer?.play()
            }
        }
    }
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    private init() {
        setupAudioSession()
        setupAudioEngine()
        registerAudioNotifications()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("AudioManager: Failed to configure audio session: \(error)")
            #endif
        }
    }


    private func registerAudioNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            break
        case .ended:
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            guard options.contains(.shouldResume) else { return }
            DispatchQueue.main.async { [weak self] in
                self?.reactivateAudioSession()
                self?.resumeAfterInterruption()
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        switch reason {
        case .oldDeviceUnavailable, .newDeviceAvailable, .override, .categoryChange:
            DispatchQueue.main.async { [weak self] in
                self?.reactivateAudioSession()
                self?.resumeAfterInterruption()
            }
        default:
            break
        }
    }

    private func reactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("AudioManager: Failed to reactivate audio session: \(error)")
            #endif
        }
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                #if DEBUG
                print("AudioManager: Failed to restart audio engine: \(error)")
                #endif
            }
        }
    }

    private func resumeAfterInterruption() {
        guard isSoundEnabled, let player = backgroundMusicPlayer else { return }
        if !player.isPlaying {
            player.play()
        }
    }
    
    private func setupAudioEngine() {
        engine.attach(playerNode)
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            #if DEBUG
            print("Audio engine failed to start: \(error)")
            #endif
        }
    }
    
    
    enum SoundType {
        case jump
        case coin
        case switchColor
        case die
    }
    
    func playSound(_ type: SoundType, pitchMultiplier: Float = 1.0) {
        guard isSoundEnabled else { return }
        
        let frequency: Float
        let duration: TimeInterval
        
        switch type {
        case .jump:
            frequency = 440.0
            duration = 0.1
        case .coin:
            frequency = 880.0 * pitchMultiplier
            duration = 0.15
        case .switchColor:
            frequency = 660.0
            duration = 0.1
        case .die:
            frequency = 110.0
            duration = 0.4
        }
        
        generateTone(frequency: frequency, duration: duration)
    }
    
    func playTone(frequency: Float, duration: TimeInterval) {
        guard isSoundEnabled else { return }
        generateTone(frequency: frequency, duration: duration)
    }
    
    private func generateTone(frequency: Float, duration: TimeInterval) {
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate
        let channelCount = outputFormat.channelCount
        guard sampleRate > 0, channelCount > 0 else { return }
        let bufferCapacity = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferCapacity) else { return }
        
        buffer.frameLength = bufferCapacity
        
        for c in 0..<Int(channelCount) {
            if let channelData = buffer.floatChannelData?[c] {
                for i in 0..<Int(bufferCapacity) {
                    let val = sinf(Float(i) * 2.0 * .pi * frequency / Float(sampleRate))
                    let envelope = 1.0 - Float(i) / Float(bufferCapacity)
                    channelData[i] = val * envelope * 0.2
                }
            }
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionCallbackType: .dataPlayedBack) { _ in }
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    func startBackgroundMusic(filename: String = "bgm", ext: String = "mp3") {
        guard isSoundEnabled else { return }
        guard backgroundMusicPlayer == nil || backgroundMusicPlayer?.isPlaying == false else { return }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            #if DEBUG
            print("AudioManager: Background music file '\(filename).\(ext)' not found in bundle.")
            #endif
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.volume = 0.3
            backgroundMusicPlayer?.play()
            #if DEBUG
            print("AudioManager: Background music started.")
            #endif
        } catch {
            #if DEBUG
            print("AudioManager: Failed to play background music: \(error.localizedDescription)")
            #endif
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
}
