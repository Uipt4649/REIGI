//
//  BowQuizView.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import SwiftUI

struct BowQuizView: View {
    @StateObject private var monitor = BowMonitoringService()
    @State private var questionIndex = 1
    @State private var questions: [BowQuestion] = BowQuestion.bank.shuffled()
    @State private var currentQuestion = BowQuestion.bank[0]
    @State private var score = 0
    @State private var combo = 0
    @State private var feedback = ""
    @State private var phase: Phase = .introTitle
    @State private var phaseOpacity: Double = 0
    @State private var readyCountdown = 3
    @State private var monitoringCountdown = 5
    @State private var detectionCounts: [BowAngle: Int] = [:]
    @State private var scheduledItems: [DispatchWorkItem] = []
    @State private var openingShown = false
    @State private var resultPulse = false
    @State private var correctAnswers = 0

    private var totalQuestions: Int { questions.count }
    let onStageClear: () -> Void
    let onStageSkip: () -> Void
    let onStageResult: (_ correct: Int, _ total: Int, _ didSkip: Bool) -> Void
    let onReturnHome: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.17, green: 0.12, blue: 0.29), Color(red: 0.36, green: 0.18, blue: 0.24), Color(red: 0.12, green: 0.28, blue: 0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            Color.white.opacity(0.06).ignoresSafeArea()
            phaseView
                .opacity(phaseOpacity)
                .animation(.easeInOut(duration: 0.35), value: phaseOpacity)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            questions = BowQuestion.bank.shuffled()
            currentQuestion = questions[0]
            questionIndex = 1
            feedback = ""
            correctAnswers = 0
            monitor.start()
            startFlowForCurrentQuestion()
        }
        .onDisappear {
            cancelAllScheduled()
            ThinkingTimePlayer.shared.stop()
            monitor.stop()
        }
    }

    @ViewBuilder
    private var phaseView: some View {
        switch phase {
        case .introTitle:
            introTitleView
        case .introPrompt:
            introPromptView
        case .introSituation:
            introSituationView
        case .readyCountdown:
            readyCountdownView
        case .monitoring:
            monitoringFullView
        case .resultCorrect:
            correctResultView
        case .resultWrong:
            wrongResultView
        }
    }

    private var introTitleView: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let titleSize = min(max(w * 0.10, 44), 64)
            let subtitleSize = min(max(w * 0.045, 18), 28)
            let chipSize = min(max(w * 0.042, 15), 24)
            let imageWidth = min(w * 0.92, 560)
            let imageHeight = min(max(h * 0.36, 230), 380)

            VStack(spacing: 14) {
                Text("正しいお辞儀をマスターせよ")
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Image("礼儀")
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.60), lineWidth: 1.4)
                    )
                    .shadow(color: .black.opacity(0.30), radius: 12, y: 6)

                Text("お辞儀の説明画像を参考に、場面に合う角度を選ぼう")
                    .font(.system(size: subtitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.94))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        guideChip("会釈 15°", size: chipSize)
                        guideChip("敬礼 30°", size: chipSize)
                    }
                    HStack(spacing: 10) {
                        guideChip("最敬礼 90°", size: chipSize)
                        guideChip("土下座", size: chipSize)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Text("第1ステージ")
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.86))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
    }

    private func guideChip(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.20), in: Capsule())
    }

    private var introPromptView: some View {
        Text("お辞儀しろ！")
            .font(.system(size: 50, weight: .black, design: .rounded))
            .foregroundStyle(.yellow)
            .shadow(color: .red.opacity(0.7), radius: 14)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .onAppear {
                PopSoundPlayer.shared.playOnce()
            }
    }

    private var introSituationView: some View {
        VStack(spacing: 18) {
            Text("問題 \(questionIndex) / \(totalQuestions)")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
            Image(systemName: currentQuestion.symbol)
                .font(.system(size: 72))
                .foregroundStyle(.white)
            Text(currentQuestion.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(currentQuestion.description)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if !feedback.isEmpty {
                Text(feedback)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(feedback.contains("正解") ? .green : .orange)
            }
        }
    }

    private var readyCountdownView: some View {
        VStack(spacing: 14) {
            Text("準備")
                .font(.title.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
            Text("\(readyCountdown)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var monitoringFullView: some View {
        ZStack(alignment: .topLeading) {
            CameraPreviewView(session: monitor.session)
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.55), .clear, .black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Spacer()
                    Button("問題をスキップ") {
                        skipCurrentQuestion()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("5秒間でお辞儀をしてください")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text("残り \(monitoringCountdown) 秒")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)

                if let detected = monitor.detectedBow {
                    Text("現在検出: \(detected.label)")
                        .foregroundStyle(.cyan)
                } else {
                    Text("姿勢検出中...")
                        .foregroundStyle(.white.opacity(0.8))
                }

                if let angle = monitor.estimatedAngle {
                    Text("推定角度: \(Int(angle))°")
                        .foregroundStyle(.white.opacity(0.85))
                }

                Text("Score \(score)  Combo x\(combo)")
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()
            }
            .padding()

            VStack {
                HStack {
                    Spacer()
                    Image("礼儀")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 164)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                }
                Spacer()
            }
            .padding(.top, 56)
            .padding(.trailing, 14)
            .allowsHitTesting(false)
        }
    }

    private var correctResultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 90))
                .foregroundStyle(.green)
                .scaleEffect(resultPulse ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true), value: resultPulse)
            Text("正解！")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("次の問題へ進みます")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .onAppear {
            resultPulse = true
            QuizResultSoundPlayer.shared.playCorrect()
        }
    }

    private var wrongResultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 90))
                .foregroundStyle(.red)
                .rotationEffect(.degrees(resultPulse ? 8 : -8))
                .animation(.easeInOut(duration: 0.12).repeatCount(6, autoreverses: true), value: resultPulse)
            Text("不正解")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("次の問題に進みます")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .onAppear {
            resultPulse = true
            QuizResultSoundPlayer.shared.playWrong()
        }
    }

    private func startFlowForCurrentQuestion() {
        cancelAllScheduled()
        animatePhaseChange(to: openingShown ? .introSituation : .introTitle)
        if openingShown {
            schedule(after: 5) {
                startReadyCountdown()
            }
        } else {
            QuizAudioPlayer.shared.playOnce()
            schedule(after: 5) {
                animatePhaseChange(to: .introPrompt)
                schedule(after: 3) {
                    animatePhaseChange(to: .introSituation)
                    schedule(after: 5) {
                        startReadyCountdown()
                    }
                }
            }
            openingShown = true
        }
    }

    private func startReadyCountdown() {
        readyCountdown = 3
        animatePhaseChange(to: .readyCountdown)
        CountdownSoundPlayer.shared.playOnce()
        runReadyTick()
    }

    private func runReadyTick() {
        if readyCountdown <= 1 {
            startMonitoringRound()
            return
        }
        schedule(after: 1) {
            readyCountdown -= 1
            runReadyTick()
        }
    }

    private func startMonitoringRound() {
        monitoringCountdown = 5
        detectionCounts = [:]
        animatePhaseChange(to: .monitoring)
        ThinkingTimePlayer.shared.playLoop()
        runMonitoringTick()
    }

    private func runMonitoringTick() {
        if let detected = monitor.detectedBow {
            detectionCounts[detected, default: 0] += 1
        }

        if monitoringCountdown <= 1 {
            evaluateMonitoringResult()
            return
        }

        schedule(after: 1) {
            monitoringCountdown -= 1
            runMonitoringTick()
        }
    }

    private func evaluateMonitoringResult() {
        ThinkingTimePlayer.shared.stop()
        let correctCount = detectionCounts[currentQuestion.answer, default: 0]
        let isCorrect = correctCount > 0
        resultPulse = false
       
        if isCorrect {
            correctAnswers += 1
            combo += 1
            score += 100 + combo * 20
            animatePhaseChange(to: .resultCorrect)
            schedule(after: 1.2) { goNextQuestionOrClear() }
        } else {
            combo = 0
            score = max(0, score - 30)
            animatePhaseChange(to: .resultWrong)
            schedule(after: 1.2) { goNextQuestionOrClear() }
        }
    }

    private func goNextQuestionOrClear() {
        if questionIndex >= totalQuestions {
            onStageResult(correctAnswers, totalQuestions, false)
            onStageClear()
            return
        }
        questionIndex += 1
        currentQuestion = questions[questionIndex - 1]
        startFlowForCurrentQuestion()
    }

    private func skipCurrentQuestion() {
        cancelAllScheduled()
        ThinkingTimePlayer.shared.stop()
        if questionIndex >= totalQuestions {
            onStageResult(correctAnswers, totalQuestions, true)
            onStageSkip()
            return
        }
        questionIndex += 1
        currentQuestion = questions[questionIndex - 1]
        combo = 0
        feedback = "問題をスキップしました"
        startFlowForCurrentQuestion()
    }

    private func animatePhaseChange(to newPhase: Phase) {
        phaseOpacity = 0
        phase = newPhase
        withAnimation(.easeInOut(duration: 0.35)) {
            phaseOpacity = 1
        }
    }

    private func schedule(after seconds: Double, _ action: @escaping () -> Void) {
        let item = DispatchWorkItem(block: action)
        scheduledItems.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }

    private func cancelAllScheduled() {
        scheduledItems.forEach { $0.cancel() }
        scheduledItems.removeAll()
    }

    private enum Phase {
        case introTitle
        case introPrompt
        case introSituation
        case readyCountdown
        case monitoring
        case resultCorrect
        case resultWrong
    }
}
