//
//  IdeaSuggestionStore.swift
//  REIGI
//

import Foundation
import SwiftUI
import Combine

struct IdeaSuggestionEntry: Codable, Identifiable {
    let id: UUID
    let text: String
    let createdAt: Date
}

final class IdeaSuggestionStore: ObservableObject {
    static let shared = IdeaSuggestionStore()

    @Published private(set) var entries: [IdeaSuggestionEntry] = []

    private let key = "reigi.ideaSuggestion.entries"
    private let maxEntryCount = 20

    private init() {
        load()
    }

    func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = IdeaSuggestionEntry(id: UUID(), text: trimmed, createdAt: Date())
        entries.insert(entry, at: 0)
        if entries.count > maxEntryCount {
            entries = Array(entries.prefix(maxEntryCount))
        }
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func removeAll() {
        entries.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([IdeaSuggestionEntry].self, from: data)
        else {
            entries = []
            return
        }
        entries = decoded
    }
}
