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
            StageMenuView(
                startBowStage: { path.append(.bowRound) },
                skipToNextStage: { path.append(.nextStage) }
            )
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .bowRound:
                    BowQuizView(
                        onStageClear: { path.append(.nextStage) },
                        onStageSkip: { path.append(.nextStage) }
                    )
                case .nextStage:
                    NextEtiquetteStageView()
                }
            }
        }
    }
}

private enum AppScreen: Hashable {
    case bowRound
    case nextStage
}

private struct StageMenuView: View {
    let startBowStage: () -> Void
    let skipToNextStage: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("REIGI")
                .font(.system(size: 44, weight: .black, design: .rounded))

            Text("ゲーム形式で日本の礼儀を学ぶ")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Label("第1ステージ: お辞儀の角度判定", systemImage: "figure.stand")
                Label("ランダム出題: 友人・面接会場・重要な取引先", systemImage: "shuffle")
                Label("正解で次の問題へ進行", systemImage: "checkmark.seal")
                Label("ステージスキップで次の礼儀へ", systemImage: "forward.fill")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )

            Button("お辞儀ステージを開始") {
                startBowStage()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button("このステージをスキップ") {
                skipToNextStage()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding()
    }
}

private struct BowQuizView: View {
    @State private var questionIndex = 1
    @State private var currentQuestion = BowQuestion.random()
    @State private var selectedAngle: BowAngle = .eishaku
    @State private var feedback = ""

    let totalQuestions = 5
    let onStageClear: () -> Void
    let onStageSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            header
            situationCard
            cameraMonitoringPlaceholder
            angleSelector
            actionButtons

            if !feedback.isEmpty {
                Text(feedback)
                    .font(.subheadline)
                    .foregroundStyle(feedback.contains("正解") ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("第1ステージ: お辞儀")
                    .font(.title3.bold())
                Text("問題 \(questionIndex) / \(totalQuestions)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("ステージスキップ") {
                onStageSkip()
            }
            .buttonStyle(.bordered)
        }
    }

    private var situationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("シチュエーション")
                .font(.headline)
            Text(currentQuestion.title)
                .font(.title3.weight(.semibold))
            Text(currentQuestion.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("正解角度: \(currentQuestion.answer.label)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var cameraMonitoringPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 40))
            Text("カメラモニタリング領域 (UI仮実装)")
                .font(.subheadline.bold())
            Text("将来的に姿勢推定モデルでお辞儀角度を判定")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [7]))
        )
    }

    private var angleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あなたのお辞儀角度")
                .font(.headline)
            Picker("角度", selection: $selectedAngle) {
                ForEach(BowAngle.allCases, id: \.self) { angle in
                    Text(angle.label).tag(angle)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("判定する") {
                submitAnswer()
            }
            .buttonStyle(.borderedProminent)

            Button("問題をスキップ") {
                nextQuestion()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func submitAnswer() {
        let isCorrect = selectedAngle == currentQuestion.answer
        feedback = isCorrect ? "正解です。次の問題へ進みます。" : "不正解です。もう一度試すか、スキップできます。"
        if isCorrect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                nextQuestion()
            }
        }
    }

    private func nextQuestion() {
        if questionIndex >= totalQuestions {
            onStageClear()
            return
        }
        questionIndex += 1
        currentQuestion = BowQuestion.random()
        selectedAngle = .eishaku
        feedback = ""
    }
}

private struct NextEtiquetteStageView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 50))
            Text("第1ステージ クリア")
                .font(.title.bold())
            Text("次のステージ: 別の礼儀作法へ")
                .font(.headline)
            Text("例: 名刺交換 / 訪問時の挨拶 / 席次マナー")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

private struct BowQuestion {
    let title: String
    let description: String
    let answer: BowAngle

    static let bank: [BowQuestion] = [
        .init(
            title: "友人に遭遇",
            description: "街中で友人とすれ違いました。軽く挨拶する場面です。",
            answer: .eishaku
        ),
        .init(
            title: "面接会場の入退場",
            description: "入室時と退室時に、丁寧な印象を与えるお辞儀が必要です。",
            answer: .keirei
        ),
        .init(
            title: "重要な取引先",
            description: "大切な商談の場。深い敬意を示す必要があります。",
            answer: .saikeirei
        )
    ]

    static func random() -> BowQuestion {
        bank.randomElement() ?? bank[0]
    }
}

private enum BowAngle: CaseIterable {
    case eishaku
    case keirei
    case saikeirei

    var label: String {
        switch self {
        case .eishaku:
            return "会釈 15°"
        case .keirei:
            return "敬礼 30°"
        case .saikeirei:
            return "最敬礼 45-90°"
        }
    }
}

#Preview("Menu") {
    ContentView()
}

#Preview("Bow Quiz") {
    BowQuizView(onStageClear: {}, onStageSkip: {})
}
