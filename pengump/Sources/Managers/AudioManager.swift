import AVFoundation
import UIKit

// MARK: - 音效名称枚举

enum SoundEffect: String, CaseIterable {
    case slingshotLaunch = "slingshot_launch"
    case iceHit = "ice_hit"
    case iceBreak = "ice_break"
    case penguinFly = "penguin_fly"
    case gameFail = "game_fail"
    case gameWin = "game_win"
    case staminaEmpty = "stamina_empty"
    case combo = "combo"
    case explosion = "explosion"
    case buttonTap = "button_tap"
}

// MARK: - 背景音乐枚举

enum BackgroundMusic: String {
    case menu = "menu_music"
    case game = "game_music"
}

// MARK: - AudioManager

final class AudioManager {
    static let shared = AudioManager()

    private var activeSFXPlayers: [URL: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var currentMusic: BackgroundMusic?
    private var musicFileURL: URL?

    private enum Keys {
        static let musicEnabled = "audio_music_enabled"
        static let sfxEnabled = "audio_sfx_enabled"
        static let musicVolume = "audio_music_volume"
        static let sfxVolume = "audio_sfx_volume"
    }

    var isMusicEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.musicEnabled) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.musicEnabled)
            if newValue {
                musicPlayer?.play()
            } else {
                musicPlayer?.pause()
            }
        }
    }

    var isSFXEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.sfxEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.sfxEnabled) }
    }

    var musicVolume: Float {
        get { UserDefaults.standard.object(forKey: Keys.musicVolume) as? Float ?? 0.5 }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.musicVolume)
            musicPlayer?.volume = newValue
        }
    }

    var sfxVolume: Float {
        get { UserDefaults.standard.object(forKey: Keys.sfxVolume) as? Float ?? 0.7 }
        set { UserDefaults.standard.set(newValue, forKey: Keys.sfxVolume) }
    }

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioManager: Failed to setup audio session: \(error)")
        }
    }

    func play(_ effect: SoundEffect) {
        guard isSFXEnabled else { return }
        playSystemSound(for: effect)
    }

    private func playSystemSound(for effect: SoundEffect) {
        switch effect {
        case .slingshotLaunch:
            playTone(frequency: 880, duration: 0.08, volume: sfxVolume)
        case .iceHit:
            playTone(frequency: 440, duration: 0.05, volume: sfxVolume)
        case .iceBreak:
            playNoise(duration: 0.1, volume: sfxVolume)
        case .penguinFly:
            playWindSound(volume: sfxVolume)
        case .gameFail:
            playMelody(notes: [330, 294, 262], durations: [0.15, 0.15, 0.3], volume: sfxVolume)
        case .gameWin:
            playMelody(notes: [523, 659, 784, 1047], durations: [0.1, 0.1, 0.1, 0.3], volume: sfxVolume)
        case .staminaEmpty:
            playMelody(notes: [392, 330], durations: [0.2, 0.3], volume: sfxVolume)
        case .combo:
            playTone(frequency: 660, duration: 0.1, volume: sfxVolume)
        case .explosion:
            playNoise(duration: 0.2, volume: sfxVolume)
        case .buttonTap:
            playTone(frequency: 600, duration: 0.03, volume: sfxVolume)
        }
    }

    private func playTone(frequency: Float, duration: Float, volume: Float) {
        let sampleRate: Float = 44100
        let frameCount = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            let time = Float(i) / sampleRate
            let envelope = min(1.0, min(time * 50, (duration - time) * 50))
            audioData[i] = sin(2.0 * .pi * frequency * time) * envelope * volume
        }

        playGeneratedAudio(audioData, sampleRate: sampleRate)
    }

    private func playNoise(duration: Float, volume: Float) {
        let sampleRate: Float = 44100
        let frameCount = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: frameCount)
        var b0: Float = 0
        var b1: Float = 0
        var b2: Float = 0

        for i in 0..<frameCount {
            let white = Float.random(in: -1...1)
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            let pink = (b0 + b1 + b2 + white * 0.5362) * 0.11
            let envelope = min(1.0, min(Float(i) * 20, Float(frameCount - i) * 10))
            audioData[i] = pink * envelope * volume
        }

        playGeneratedAudio(audioData, sampleRate: sampleRate)
    }

    private func playWindSound(volume: Float) {
        let sampleRate: Float = 44100
        let duration: Float = 0.3
        let frameCount = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: frameCount)
        var b0: Float = 0
        var b1: Float = 0

        for i in 0..<frameCount {
            let white = Float.random(in: -1...1)
            b0 = 0.999 * b0 + white * 0.6
            b1 = 0.995 * b1 + b0 * 0.3
            let wind = (b0 + b1) * 0.4
            let time = Float(i) / sampleRate
            let modulation = sin(2.0 * .pi * 3.0 * time) * 0.3 + 0.7
            let envelope = sin(.pi * time / duration)
            audioData[i] = wind * modulation * envelope * volume
        }

        playGeneratedAudio(audioData, sampleRate: sampleRate)
    }

    private func playMelody(notes: [Float], durations: [Float], volume: Float) {
        let sampleRate: Float = 44100
        var audioData = [Float]()

        for (index, freq) in notes.enumerated() {
            let duration = index < durations.count ? durations[index] : 0.2
            let frameCount = Int(sampleRate * duration)
            let attackSamples = Int(sampleRate * 0.01)
            let releaseSamples = Int(sampleRate * 0.05)

            for i in 0..<frameCount {
                let time = Float(i) / sampleRate
                var envelope: Float = 1.0
                if i < attackSamples {
                    envelope = Float(i) / Float(attackSamples)
                } else if i > frameCount - releaseSamples {
                    envelope = Float(frameCount - i) / Float(releaseSamples)
                }
                let sample = sin(2.0 * .pi * freq * time) * envelope * volume
                audioData.append(sample)
            }
        }

        playGeneratedAudio(audioData, sampleRate: sampleRate)
    }

    private func playGeneratedAudio(_ audioData: [Float], sampleRate: Float) {
        guard !audioData.isEmpty else { return }

        do {
            let fileURL = try writeWAVFile(audioData: audioData, sampleRate: sampleRate, prefix: "temp_audio")
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.volume = sfxVolume
            player.prepareToPlay()
            activeSFXPlayers[fileURL] = player
            player.play()

            let lifetime = Double(audioData.count) / Double(sampleRate) + 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) { [weak self] in
                self?.cleanupSFXFile(fileURL)
            }
        } catch {
            print("AudioManager: Failed to play generated audio: \(error)")
        }
    }

    private func createPCMData(from audioData: [Float]) -> Data {
        var pcmData = Data()
        for sample in audioData {
            let clamped = max(-1.0, min(1.0, sample))
            let int16 = Int16(clamped * Float(Int16.max))
            var littleEndian = int16.littleEndian
            pcmData.append(Data(bytes: &littleEndian, count: 2))
        }
        return pcmData
    }

    private func writeWAVFile(audioData: [Float], sampleRate: Float, prefix: String) throws -> URL {
        let pcmData = createPCMData(from: audioData)
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(prefix)_\(UUID().uuidString).wav"
        let fileURL = tempDir.appendingPathComponent(fileName)

        var header = createWAVHeader(
            dataSize: UInt32(pcmData.count),
            sampleRate: UInt32(sampleRate),
            numChannels: 1,
            bitsPerSample: 16
        )
        let headerData = Data(bytes: &header, count: 44)

        var outputData = Data()
        outputData.append(headerData)
        outputData.append(pcmData)
        try outputData.write(to: fileURL, options: .atomic)

        return fileURL
    }

    private struct WAVEHeader {
        var chunkID: UInt32 = 0x52494646
        var chunkSize: UInt32 = 0
        var format: UInt32 = 0x57415645
        var subchunk1ID: UInt32 = 0x666D7420
        var subchunk1Size: UInt32 = 16
        var audioFormat: UInt16 = 1
        var numChannels: UInt16 = 1
        var sampleRate: UInt32 = 44100
        var byteRate: UInt32 = 44100 * 2
        var blockAlign: UInt16 = 2
        var bitsPerSample: UInt16 = 16
        var subchunk2ID: UInt32 = 0x64617461
        var subchunk2Size: UInt32 = 0
    }

    private func createWAVHeader(dataSize: UInt32, sampleRate: UInt32, numChannels: UInt16, bitsPerSample: UInt16) -> WAVEHeader {
        var header = WAVEHeader()
        header.chunkSize = 36 + dataSize
        header.audioFormat = 1
        header.numChannels = numChannels
        header.sampleRate = sampleRate
        header.byteRate = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        header.blockAlign = numChannels * (bitsPerSample / 8)
        header.bitsPerSample = bitsPerSample
        header.subchunk2Size = dataSize
        return header
    }

    func playMusic(_ music: BackgroundMusic, loop: Bool = true) {
        guard isMusicEnabled else { return }

        if currentMusic == music, musicPlayer?.isPlaying == true {
            return
        }

        currentMusic = music
        musicPlayer?.stop()
        cleanupMusicFile()

        let musicData = generateMusicLoop(for: music)
        if let player = createMusicPlayer(from: musicData, sampleRate: 44100) {
            musicPlayer = player
            musicPlayer?.volume = musicVolume
            musicPlayer?.numberOfLoops = loop ? -1 : 0
            musicPlayer?.play()
        }
    }

    private func generateMusicLoop(for music: BackgroundMusic) -> [Float] {
        let sampleRate: Float = 44100
        var audioData = [Float]()

        switch music {
        case .menu:
            let melody: [(Float, Float)] = [
                (523, 0.2), (659, 0.2), (784, 0.2), (659, 0.2), (523, 0.2), (440, 0.2), (523, 0.4),
                (523, 0.2), (659, 0.2), (784, 0.2), (880, 0.2), (784, 0.2), (659, 0.2), (523, 0.2), (440, 0.2), (392, 0.4)
            ]
            for _ in 0..<2 {
                for (freq, duration) in melody {
                    let frames = Int(sampleRate * duration)
                    for i in 0..<frames {
                        let time = Float(i) / sampleRate
                        let envelope = min(1.0, min(Float(i) * 30, Float(frames - i) * 15))
                        let sample = sin(2.0 * .pi * freq * time) * envelope * 0.3
                        let harmonic2 = sin(2.0 * .pi * freq * 2.0 * time) * envelope * 0.05
                        audioData.append(sample + harmonic2)
                    }
                }
            }

        case .game:
            let melody: [(Float, Float)] = [
                (392, 0.15), (440, 0.15), (494, 0.15), (523, 0.15), (494, 0.15), (440, 0.15), (392, 0.3),
                (523, 0.15), (494, 0.15), (440, 0.15), (392, 0.3), (440, 0.15), (494, 0.15), (523, 0.3)
            ]
            for _ in 0..<3 {
                for (freq, duration) in melody {
                    let frames = Int(sampleRate * duration)
                    for i in 0..<frames {
                        let time = Float(i) / sampleRate
                        let envelope = min(1.0, min(Float(i) * 40, Float(frames - i) * 20))
                        let sample = sin(2.0 * .pi * freq * time) * envelope * 0.25
                        let harmonic2 = sin(2.0 * .pi * freq * 2.0 * time) * envelope * 0.04
                        audioData.append(sample + harmonic2)
                    }
                }
            }
        }

        return audioData
    }

    private func createMusicPlayer(from audioData: [Float], sampleRate: Float) -> AVAudioPlayer? {
        guard !audioData.isEmpty else { return nil }

        do {
            let fileURL = try writeWAVFile(audioData: audioData, sampleRate: sampleRate, prefix: "music")
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.prepareToPlay()
            musicFileURL = fileURL
            return player
        } catch {
            print("AudioManager: Failed to create music player: \(error)")
            return nil
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusic = nil
        cleanupMusicFile()
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func resumeMusic() {
        guard isMusicEnabled else { return }
        musicPlayer?.play()
    }

    func toggleMusic() {
        isMusicEnabled.toggle()
        if isMusicEnabled {
            if let music = currentMusic {
                playMusic(music)
            }
        } else {
            stopMusic()
        }
    }

    func toggleSFX() {
        isSFXEnabled.toggle()
    }

    private func cleanupSFXFile(_ fileURL: URL) {
        activeSFXPlayers[fileURL]?.stop()
        activeSFXPlayers.removeValue(forKey: fileURL)
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func cleanupMusicFile() {
        if let url = musicFileURL {
            try? FileManager.default.removeItem(at: url)
            musicFileURL = nil
        }
    }

    func playLaunchSound() { play(.slingshotLaunch) }
    func playIceHitSound() { play(.iceHit) }
    func playIceBreakSound() { play(.iceBreak) }
    func playPenguinFlySound() { play(.penguinFly) }
    func playGameFailSound() { play(.gameFail) }
    func playGameWinSound() { play(.gameWin) }
    func playStaminaEmptySound() { play(.staminaEmpty) }
    func playComboSound() { play(.combo) }
    func playExplosionSound() { play(.explosion) }
    func playButtonTapSound() { play(.buttonTap) }
}
