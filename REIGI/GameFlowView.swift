//
//  GameFlowView.swift
//  REIGI
//

import SwiftUI

struct GameFlowView: View {
    @State private var stageIndex: Int
    @State private var showHomeConfirm = false
    let onReturnHome: () -> Void

    init(startStageIndex: Int, onReturnHome: @escaping () -> Void) {
        _stageIndex = State(initialValue: max(0, min(stages.count - 1, startStageIndex)))
        self.onReturnHome = onReturnHome
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                if stageIndex == 0 {
                    BowQuizView(
                        onStageClear: advanceStage,
                        onStageSkip: advanceStage,
                        onReturnHome: { showHomeConfirm = true }
                    )
                } else if stageIndex == 1 {
                    ShrineStageView(
                        onStageClear: advanceStage,
                        onStageSkip: advanceStage,
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
}
