//
//  CountdownSoundPlayer.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import AVFoundation
import Foundation

final class CountdownSoundPlayer {
    static let shared = CountdownSoundPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    func playOnce() {
        guard let url = findURL() else { return }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = 0
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            // 効果音失敗時も処理は継続
        }
    }

    private func findURL() -> URL? {
        let baseCandidates = ["countdown", "Countdown", "COUNTDOWN"]
        let exts = ["mp3", "m4a", "wav", "caf", "aac", "aif", "aiff"]
        for base in baseCandidates {
            for ext in exts {
                if let url = Bundle.main.url(forResource: base, withExtension: ext) {
                    return url
                }
            }
        }
        return Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil)?
            .first(where: { $0.deletingPathExtension().lastPathComponent.lowercased() == "countdown" })
    }
}
