//
//  GameFlowView.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import SwiftUI

struct GameFlowView: View {
    @State private var stageIndex: Int
    @State private var showHomeConfirm = false
    let playMode: PlayMode
    let onReturnHome: () -> Void

    init(startStageIndex: Int, playMode: PlayMode, onReturnHome: @escaping () -> Void) {
        _stageIndex = State(initialValue: max(0, min(stages.count - 1, startStageIndex)))
        self.playMode = playMode
        self.onReturnHome = onReturnHome
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                if stageIndex == 0 {
                    BowQuizView(
                        onStageClear: advanceStage,
                        onStageSkip: advanceStage,
                        onStageResult: { correct, total, didSkip in
                            recordStageResult(correct: correct, total: total, didSkip: didSkip)
                        },
                        onReturnHome: { showHomeConfirm = true }
                    )
                } else {
                    GenericStageView(
                        stage: stages[stageIndex],
                        onNext: advanceStage,
                        onReturnHome: { showHomeConfirm = true }
                    )
                }
            }
            .navigationBarBackButtonHidden(true)

            Button {
                showHomeConfirm = true
            } label: {
                Label("ホーム", systemImage: "house.fill")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.top, 10)
            .padding(.leading, 10)
        }
        .confirmationDialog("ホーム画面に戻りますか？", isPresented: $showHomeConfirm, titleVisibility: .visible) {
            Button("ホームに戻る", role: .destructive) {
                onReturnHome()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在の進行状況はこのステージから離れます。")
        }
    }

    private func advanceStage() {
        if stageIndex < stages.count - 1 {
            stageIndex += 1
        } else {
            onReturnHome()
        }
    }

    private func recordStageResult(correct: Int, total: Int, didSkip: Bool) {
        guard stages.indices.contains(stageIndex) else { return }
        let stage = stages[stageIndex]
        PlayHistoryStore.shared.add(
            stageID: stage.id,
            stageTitle: stage.title,
            playMode: playMode,
            correct: correct,
            total: total,
            didSkip: didSkip
        )
    }
}
