//
//  AudioMuteState.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import Foundation

enum AudioMuteState {
    private static let key = "reigi.bgmMuted"

    static var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func setMuted(_ muted: Bool) {
        isMuted = muted
        if muted {
            MainBGMPlayer.shared.stop()
            ThinkingTimePlayer.shared.stop()
            QuizAudioPlayer.shared.stop()
        }
    }
}
