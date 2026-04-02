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
    case purchase = "purchase"
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

class AudioManager {
    static let shared = AudioManager()

    // MARK: - Properties

    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var currentMusic: BackgroundMusic?

    // UserDefaults keys for settings
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

    // MARK: - Init

    private init() {
        setupAudioSession()
        preloadAllSFX()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioManager: Failed to setup audio session: \(error)")
        }
    }

    // MARK: - 音效预加载（合成音）

    private func preloadAllSFX() {
        // 使用系统合成音效代替实际音频文件
        // 预加载所有音效的audioPlayer（用于获取时长信息）
        for effect in SoundEffect.allCases {
            sfxPlayers[effect.rawValue] = nil // 占位，后续按需生成
        }
    }

    // MARK: - 播放音效

    func play(_ effect: SoundEffect) {
        guard isSFXEnabled else { return }

        // 使用系统合成音效
        playSystemSound(for: effect)
    }

    private func playSystemSound(for effect: SoundEffect) {
        // 根据不同音效类型播放对应的系统合成音效
        // 利用 AudioServicesCreateSystemSoundID 和短促的合成音

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
        case .purchase:
            playTone(frequency: 1047, duration: 0.15, volume: sfxVolume)
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

    // MARK: - 音频合成方法

    /// 播放指定频率的纯音
    private func playTone(frequency: Float, duration: Float, volume: Float) {
        let sampleRate: Float = 44100
        let frameCount = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            let time = Float(i) / sampleRate
            let envelope = min(1.0, min(time * 50, (duration - time) * 50)) // ADSR简化版
            audioData[i] = sin(2.0 * .pi * frequency * time) * envelope * volume
        }

        playGeneratedAudio(audioData, sampleRate: sampleRate)
    }

    /// 播放粉红噪声（用于爆炸/破碎声）
    private func playNoise(duration: Float, volume: Float) {
        let sampleRate: Float = 44100
        let frameCount = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: frameCount)
        var b0: Float = 0, b1: Float = 0, b2: Float = 0

        for i in 0..<frameCount {
            let white = Float.random(in: -1...1)
            // 简单的低通滤波产生粉红噪声
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            let pink = (b0 + b1 + b2 + white * 0.5362) * 0.11
            let envelope = min(1.0, min(Float(i) * 20, Float(frameCount - i) * 10))
            audioData[i] = pink * envelope * volume
        }

        playGeneratedAudio(audioData, sampleRate: sampleRate)
    }

    /// 播放风声（企鹅飞行）
    private func playWindSound(volume: Float) {
        let sampleRate: Float = 44100
        let duration: Float = 0.3
        let frameCount = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: frameCount)
        var b0: Float = 0, b1: Float = 0

        for i in 0..<frameCount {
            let white = Float.random(in: -1...1)
            b0 = 0.999 * b0 + white * 0.6
            b1 = 0.995 * b1 + b0 * 0.3
            let wind = (b0 + b1) * 0.4
            let time = Float(i) / sampleRate
            let modulation = sin(2.0 * .pi * 3.0 * time) * 0.3 + 0.7
            let envelope = sin(.pi * time / duration) // 渐入渐出
            audioData[i] = wind * modulation * envelope * volume
        }

        playGeneratedAudio(audioData, sampleRate: sampleRate)
    }

    /// 播放旋律（游戏胜利/失败音效）
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

    /// 将生成的音频数据转换为AudioBuffer并播放
    private func playGeneratedAudio(_ audioData: [Float], sampleRate: Float) {
        guard !audioData.isEmpty else { return }

        // 转换为 16-bit PCM
        var pcmData = Data()
        for sample in audioData {
            let clamped = max(-1.0, min(1.0, sample))
            let int16 = Int16(clamped * Float(Int16.max))
            var littleEndian = int16.littleEndian
            pcmData.append(Data(bytes: &littleEndian, count: 2))
        }

        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "temp_audio_\(UUID().uuidString).wav"
        let fileURL = tempDir.appendingPathComponent(fileName)

        // 写入WAV文件
        var header = createWAVHeader(dataSize: UInt32(pcmData.count), sampleRate: UInt32(sampleRate), numChannels: 1, bitsPerSample: 16)
        let headerData = Data(bytes: &header, count: 44)

        do {
            try headerData.write(to: fileURL)
            try pcmData.write(to: fileURL, options: .atomic)

            // 使用AVAudioPlayer播放
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.volume = sfxVolume
            player.play()

            // 播放完成后删除临时文件
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(audioData.count) / Double(sampleRate) + 0.5) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("AudioManager: Failed to play generated audio: \(error)")
        }
    }

    /// 创建WAV文件头
    private struct WAVEHeader {
        var chunkID: UInt32 = 0x52494646  // "RIFF"
        var chunkSize: UInt32 = 0
        var format: UInt32 = 0x57415645  // "WAVE"
        var subchunk1ID: UInt32 = 0x666D7420  // "fmt "
        var subchunk1Size: UInt32 = 16
        var audioFormat: UInt16 = 1  // PCM
        var numChannels: UInt16 = 1
        var sampleRate: UInt32 = 44100
        var byteRate: UInt32 = 44100 * 2
        var blockAlign: UInt16 = 2
        var bitsPerSample: UInt16 = 16
        var subchunk2ID: UInt32 = 0x64617461  // "data"
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

    // MARK: - 背景音乐

    func playMusic(_ music: BackgroundMusic, loop: Bool = true) {
        guard isMusicEnabled else { return }

        // 如果当前正在播放同一首音乐，不重复启动
        if currentMusic == music, musicPlayer?.isPlaying == true {
            return
        }

        currentMusic = music

        // 停止当前音乐
        musicPlayer?.stop()

        // 使用简单合成音作为背景音乐（MIDI风格循环）
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
            // 欢快的8-bit风格菜单音乐
            // C大调，循环小节：Bach风格的简单旋律
            let melody: [(Float, Float)] = [
                (523, 0.2), (659, 0.2), (784, 0.2), (659, 0.2), (523, 0.2), (440, 0.2), (523, 0.4),
                (523, 0.2), (659, 0.2), (784, 0.2), (880, 0.2), (784, 0.2), (659, 0.2), (523, 0.2), (440, 0.2), (392, 0.4)
            ]
            let loopCount = 2
            for _ in 0..<loopCount {
                for (freq, duration) in melody {
                    let frames = Int(sampleRate * duration)
                    for i in 0..<frames {
                        let time = Float(i) / sampleRate
                        let envelope = min(1.0, min(Float(i) * 30, Float(frames - i) * 15))
                        let sample = sin(2.0 * .pi * freq * time) * envelope * 0.3
                        // 添加一点谐波让声音更丰富
                        let harmonic2 = sin(2.0 * .pi * freq * 2.0 * time) * envelope * 0.05
                        audioData.append(sample + harmonic2)
                    }
                }
            }

        case .game:
            // 游戏背景音乐 - 稍快节奏，轻快活泼
            let melody: [(Float, Float)] = [
                (392, 0.15), (440, 0.15), (494, 0.15), (523, 0.15), (494, 0.15), (440, 0.15), (392, 0.3),
                (523, 0.15), (494, 0.15), (440, 0.15), (392, 0.3), (440, 0.15), (494, 0.15), (523, 0.3)
            ]
            let loopCount = 3
            for _ in 0..<loopCount {
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

        // 转换为 16-bit PCM
        var pcmData = Data()
        for sample in audioData {
            let clamped = max(-1.0, min(1.0, sample))
            let int16 = Int16(clamped * Float(Int16.max))
            var littleEndian = int16.littleEndian
            pcmData.append(Data(bytes: &littleEndian, count: 2))
        }

        // 创建临时WAV文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "music_\(UUID().uuidString).wav"
        let fileURL = tempDir.appendingPathComponent(fileName)

        var header = createWAVHeader(dataSize: UInt32(pcmData.count), sampleRate: UInt32(sampleRate), numChannels: 1, bitsPerSample: 16)
        let headerData = Data(bytes: &header, count: 44)

        do {
            try headerData.write(to: fileURL)
            try pcmData.write(to: fileURL, options: .atomic)
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.prepareToPlay()
            return player
        } catch {
            print("AudioManager: Failed to create music player: \(error)")
            return nil
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        currentMusic = nil
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func resumeMusic() {
        guard isMusicEnabled else { return }
        musicPlayer?.play()
    }

    // MARK: - 快捷方法

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

    // MARK: - 游戏事件集成

    func playLaunchSound() { play(.slingshotLaunch) }
    func playIceHitSound() { play(.iceHit) }
    func playIceBreakSound() { play(.iceBreak) }
    func playPenguinFlySound() { play(.penguinFly) }
    func playGameFailSound() { play(.gameFail) }
    func playGameWinSound() { play(.gameWin) }
    func playPurchaseSound() { play(.purchase) }
    func playStaminaEmptySound() { play(.staminaEmpty) }
    func playComboSound() { play(.combo) }
    func playExplosionSound() { play(.explosion) }
    func playButtonTapSound() { play(.buttonTap) }
}
