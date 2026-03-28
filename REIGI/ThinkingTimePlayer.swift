//
//  ThinkingTimePlayer.swift
//  REIGI
//

import AVFoundation
import Foundation

final class ThinkingTimePlayer {
    static let shared = ThinkingTimePlayer()

    private var player: AVAudioPlayer?

    private init() {}

    func playLoop() {
        guard !AudioMuteState.isMuted else { return }
        configureAudioSessionIfNeeded()
        guard let url = findURL() else { return }

        if let player, player.url == url, player.isPlaying {
            return
        }

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
        } catch {
            // 音声再生失敗時は処理継続
        }
    }

    func stop() {
        player?.stop()
    }

    private func findURL() -> URL? {
        let baseCandidates = ["ThinkingTime", "thinkingTime"]
        let exts = ["mp3", "m4a", "wav", "caf", "aac", "aif", "aiff"]
        for baseName in baseCandidates {
            for ext in exts {
                if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                    return url
                }
            }
        }
        return Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil)?
            .first(where: { $0.deletingPathExtension().lastPathComponent.lowercased() == "thinkingtime" })
    }

    private func configureAudioSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            // セッション設定失敗時も再生は試みる。
        }
    }
}
