//
//  QuizResultSoundPlayer.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import AVFoundation
import Foundation

final class QuizResultSoundPlayer {
    static let shared = QuizResultSoundPlayer()

    private var pinponPlayer: AVAudioPlayer?
    private var buzzerPlayer: AVAudioPlayer?

    private init() {}

    func playCorrect() {
        play(resourceCandidates: ["PINPON", "Pinpon", "pinpon"], target: .correct)
    }

    func playWrong() {
        play(resourceCandidates: ["Buzzer", "BUZZER", "buzzer"], target: .wrong)
    }

    private enum Target {
        case correct
        case wrong
    }

    private func play(resourceCandidates: [String], target: Target) {
        guard let url = findURL(resourceCandidates: resourceCandidates) else { return }
        configureAudioSessionIfNeeded()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()

            switch target {
            case .correct:
                pinponPlayer = player
            case .wrong:
                buzzerPlayer = player
            }
        } catch {
            // 効果音失敗時も処理は継続
        }
    }

    private func findURL(resourceCandidates: [String]) -> URL? {
        let exts = ["mp3", "m4a", "wav", "caf", "aac", "aif", "aiff"]
        for baseName in resourceCandidates {
            for ext in exts {
                if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                    return url
                }
            }
        }

        let lowerNames = Set(resourceCandidates.map { $0.lowercased() })
        return Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil)?
            .first(where: { lowerNames.contains($0.deletingPathExtension().lastPathComponent.lowercased()) })
    }

    private func configureAudioSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            // セッション設定失敗時も再生は試みる
        }
    }
}
