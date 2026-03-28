//
//  ContentView.swift
//  REIGI
//
//  Created by 渡邉羽唯 on 2026/03/28.
//

import SwiftUI

struct ContentView: View {
    @State private var path: [AppScreen] = []

    var body: some View {
        NavigationStack(path: $path) {
            TitleHomeView(
                startGame: { path.append(.gameFlow(startAt: 0, mode: .fullRun)) },
                startFromStage: { index in path.append(.gameFlow(startAt: index, mode: .stageSelect)) }
            )
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .gameFlow(let index, let mode):
                    GameFlowView(startStageIndex: index, playMode: mode, onReturnHome: { path = [] })
                }
            }
        }
    }
}

#Preview("Title") {
    ContentView()
}
