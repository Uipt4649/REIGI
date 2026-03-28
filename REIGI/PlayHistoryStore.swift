//
//  PlayHistoryStore.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import Foundation
import SwiftUI
import Combine

struct PlayHistoryEntry: Codable, Identifiable {
    let id: UUID
    let stageID: Int
    let stageTitle: String
    let playMode: PlayMode
    let correct: Int
    let total: Int
    let didSkip: Bool
    let playedAt: Date

    var accuracyText: String {
        guard total > 0 else { return "-%" }
        let rate = Int((Double(correct) / Double(total) * 100).rounded())
        return "\(rate)%"
    }
}

final class PlayHistoryStore: ObservableObject {
    static let shared = PlayHistoryStore()

    @Published private(set) var entries: [PlayHistoryEntry] = []

    private let key = "reigi.playHistory.entries"
    private let maxEntryCount = 5

    private init() {
        load()
    }

    func add(stageID: Int, stageTitle: String, playMode: PlayMode, correct: Int, total: Int, didSkip: Bool) {
        let clampedCorrect = max(0, min(correct, total))
        let clampedTotal = max(total, 0)
        let entry = PlayHistoryEntry(
            id: UUID(),
            stageID: stageID,
            stageTitle: stageTitle,
            playMode: playMode,
            correct: clampedCorrect,
            total: clampedTotal,
            didSkip: didSkip,
            playedAt: Date()
        )
        entries.insert(entry, at: 0)
        if entries.count > maxEntryCount {
            entries = Array(entries.prefix(maxEntryCount))
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([PlayHistoryEntry].self, from: data)
        else {
            entries = []
            return
        }
        entries = decoded
    }
}

