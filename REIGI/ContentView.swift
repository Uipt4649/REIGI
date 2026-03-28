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
                startGame: { path.append(.gameFlow(startAt: 0)) },
                startFromStage: { index in path.append(.gameFlow(startAt: index)) }
            )
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .gameFlow(let index):
                    GameFlowView(startStageIndex: index, onReturnHome: { path = [] })
                }
            }
        }
    }
}

#Preview("Title") {
    ContentView()
}
