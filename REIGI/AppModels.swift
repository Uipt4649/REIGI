//
//  AppModels.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import SwiftUI

enum PlayMode: String, Codable, Hashable {
    case fullRun = "通しプレイ"
    case stageSelect = "ステージ選択"
}

enum AppScreen: Hashable {
    case gameFlow(startAt: Int, mode: PlayMode)
}

struct StageInfo: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String?
    let emoji: String?
}

let stages: [StageInfo] = [
    .init(id: 0, title: "ステージ1 お辞儀", subtitle: "会釈・敬礼・最敬礼・土下座を判定", icon: "figure.stand", emoji: nil)
]

enum ShrinePathChoice: CaseIterable {
    case center
    case edge
    case anywhere

    var label: String {
        switch self {
        case .center:
            return "参道の真ん中を歩く"
        case .edge:
            return "参道の端を歩く"
        case .anywhere:
            return "空いている場所ならどこでも歩く"
        }
    }
}

struct BowQuestion {
    let title: String
    let description: String
    let answer: BowAngle
    let symbol: String

    static let bank: [BowQuestion] = [
        .init(
            title: "友人に遭遇",
            description: "街中で友人とすれ違いました。軽く挨拶する場面です。",
            answer: .eishaku,
            symbol: "person.2"
        ),
        .init(
            title: "面接会場の入退場",
            description: "入室時と退室時に、丁寧な印象を与えるお辞儀が必要です。",
            answer: .keirei,
            symbol: "door.left.hand.open"
        ),
        .init(
            title: "重大なミスの謝罪",
            description: "大きな失礼やミスをしてしまい、深い謝罪を示す場面です。",
            answer: .saikeirei,
            symbol: "exclamationmark.triangle"
        ),
        .init(
            title: "取り返しのつかない失敗の謝罪",
            description: "最大限の謝罪を示す必要があり、土下座で誠意を伝える場面です。",
            answer: .dogeza,
            symbol: "person.and.background.dotted"
        )
    ]
}

enum BowAngle: CaseIterable {
    case eishaku
    case keirei
    case saikeirei
    case dogeza

    var label: String {
        switch self {
        case .eishaku:
            return "会釈 15°"
        case .keirei:
            return "敬礼 30°"
        case .saikeirei:
            return "最敬礼 90°"
        case .dogeza:
            return "土下座"
        }
    }
}
