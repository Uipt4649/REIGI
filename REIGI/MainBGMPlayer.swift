//
//  MainBGMPlayer.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import AVFoundation
import Foundation

final class MainBGMPlayer {
    static let shared = MainBGMPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    func playMainLoop() {
        guard !AudioMuteState.isMuted else { return }
        configureAudioSessionIfNeeded()
        guard let url = findMainAudioURL() else { return }

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
            // BGM再生失敗時はアプリ進行を止めない。
        }
    }

    func stop() {
        player?.stop()
    }

    private func findMainAudioURL() -> URL? {
        let baseName = "REIGImain"
        let exts = ["mp3", "m4a", "wav", "caf", "aac", "aif", "aiff"]

        for ext in exts {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                return url
            }
        }

        return Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil)?
            .first(where: { $0.deletingPathExtension().lastPathComponent == baseName })
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
