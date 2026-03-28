//
//  ShrineStageView.swift
//  REIGI
//

import SwiftUI

struct ShrineStageView: View {
    @StateObject private var monitor = BowMonitoringService()
    @State private var phase: Phase = .intro
    @State private var phaseOpacity = 0.0
    @State private var readyCountdown = 3
    @State private var monitoringCountdown = 15
    @State private var pathChoice: ShrinePathChoice?
    @State private var message = ""
    @State private var scheduledItems: [DispatchWorkItem] = []

    let onStageClear: () -> Void
    let onStageSkip: () -> Void
    let onReturnHome: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.23, blue: 0.17), Color(red: 0.36, green: 0.19, blue: 0.20), Color(red: 0.17, green: 0.24, blue: 0.39)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            Color.white.opacity(0.05).ignoresSafeArea()
            phaseView
                .opacity(phaseOpacity)
                .animation(.easeInOut(duration: 0.35), value: phaseOpacity)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            monitor.start()
            startRitualFlow()
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
        case .intro:
            ritualIntroView
        case .prompt:
            ritualPromptView
        case .readyCountdown:
            ritualCountdownView
        case .monitoring:
            ritualMonitoringView
        case .pathQuiz:
            pathQuizView
        }
    }

    private var ritualIntroView: some View {
        VStack(spacing: 12) {
            Text("⛩️")
                .font(.system(size: 34))
            Text("ステージ2 神社参拝")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
            Text("参拝時の礼儀をマスターせよ！")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
    }

    private var ritualCountdownView: some View {
        VStack(spacing: 14) {
            Text("準備")
                .font(.title.bold())
                .foregroundStyle(.white.opacity(0.85))
            Text("\(readyCountdown)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var ritualPromptView: some View {
        Text("二礼二拍手一礼しろ！！！")
            .font(.system(size: 50, weight: .black, design: .rounded))
            .foregroundStyle(.yellow)
            .shadow(color: .red.opacity(0.7), radius: 14)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .onAppear {
                PopSoundPlayer.shared.playOnce()
            }
    }

    private var ritualMonitoringView: some View {
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
                    Button("ステージスキップ") { onStageSkip() }
                        .buttonStyle(.borderedProminent)
                }

                Text("二礼二拍手一礼を15秒で行ってください")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text("残り \(monitoringCountdown) 秒")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)

                Text("礼カウント: \(monitor.bowEventCount) / 3")
                    .foregroundStyle(.white.opacity(0.9))
                Text("拍手カウント: \(monitor.clapEventCount) / 2")
                    .foregroundStyle(.white.opacity(0.9))

                if !message.isEmpty {
                    Text(message)
                        .font(.headline.bold())
                        .foregroundStyle(message.contains("正解") ? .green : .orange)
                }
                Spacer()
            }
            .padding()
        }
    }

    private var pathQuizView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.98, blue: 0.95), Color(red: 0.86, green: 0.93, blue: 0.87)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button("ホーム") { onReturnHome() }
                        .buttonStyle(.bordered)
                    Button("ステージスキップ") { onStageSkip() }
                        .buttonStyle(.bordered)
                    Spacer()
                }

                Text("⛩️")
                    .font(.system(size: 56))
                Text("第2問 参道クイズ")
                    .font(.title2.bold())
                Text("参拝道はどこを歩く？")
                    .font(.title3.weight(.semibold))

                ForEach(ShrinePathChoice.allCases, id: \.self) { choice in
                    Button {
                        selectPath(choice)
                    } label: {
                        HStack {
                            Text(choice.label)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.85))
                        )
                    }
                    .buttonStyle(.plain)
                }

                if !message.isEmpty {
                    Text(message)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(message.contains("正解") ? .green : .red)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding()
        }
    }

    private func startRitualFlow() {
        cancelAllScheduled()
        message = ""
        animatePhaseChange(to: .intro)
        QuizAudioPlayer.shared.playOnce()
        schedule(after: 3) {
            animatePhaseChange(to: .prompt)
            schedule(after: 3) {
                readyCountdown = 3
                animatePhaseChange(to: .readyCountdown)
                CountdownSoundPlayer.shared.playOnce()
                runReadyTick()
            }
        }
    }

    private func runReadyTick() {
        if readyCountdown <= 1 {
            startMonitoring()
            return
        }
        schedule(after: 1) {
            readyCountdown -= 1
            runReadyTick()
        }
    }

    private func startMonitoring() {
        cancelAllScheduled()
        monitoringCountdown = 15
        message = ""
        monitor.beginGestureTracking()
        animatePhaseChange(to: .monitoring)
        ThinkingTimePlayer.shared.playLoop()
        runMonitoringTick()
    }

    private func runMonitoringTick() {
        if monitoringCountdown <= 1 {
            evaluateRitual()
            return
        }
        schedule(after: 1) {
            monitoringCountdown -= 1
            runMonitoringTick()
        }
    }

    private func evaluateRitual() {
        ThinkingTimePlayer.shared.stop()
        let bowOK = monitor.bowEventCount >= 3
        let clapOK = monitor.clapEventCount >= 2
        let isCorrect = bowOK && clapOK
        message = isCorrect ? "正解！次は参道クイズです" : "不正解。二礼二拍手一礼をもう一度"

        if isCorrect {
            QuizResultSoundPlayer.shared.playCorrect()
            schedule(after: 1.0) {
                animatePhaseChange(to: .pathQuiz)
            }
        } else {
            QuizResultSoundPlayer.shared.playWrong()
            schedule(after: 1.0) {
                startRitualFlow()
            }
        }
    }

    private func selectPath(_ choice: ShrinePathChoice) {
        pathChoice = choice
        if choice == .edge {
            message = "正解！中央は神様の通り道なので、端を歩きます。"
            QuizResultSoundPlayer.shared.playCorrect()
            schedule(after: 1.1) {
                onStageClear()
            }
        } else {
            message = "不正解。中央は避けて、端を歩きましょう。"
            QuizResultSoundPlayer.shared.playWrong()
        }
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
        case intro
        case prompt
        case readyCountdown
        case monitoring
        case pathQuiz
    }
}
