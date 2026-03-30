//
//  ShrineStageView.swift
//  REIGI
//

import SwiftUI
import Combine
import CoreMotion

struct ShrineStageView: View {
    @StateObject private var motion = HaizenMotionService()

    @State private var phase: Phase = .intro
    @State private var phaseOpacity = 0.0
    @State private var readyCountdown = 3
    @State private var roundIndex = 0
    @State private var score = 0
    @State private var combo = 0
    @State private var correctCount = 0
    @State private var resultOverlay: RoundResult?
    @State private var stageResultSent = false
    @State private var scheduledItems: [DispatchWorkItem] = []
    @State private var roundLocked = false
    @State private var quickAction: QuickActionKind?
    @State private var quickActionSuccessCount = 0
    @State private var quickActionTimeoutItem: DispatchWorkItem?
    @State private var pulse = false
    @State private var drift = false
    @State private var showClearBurst = false

    let onStageClear: () -> Void
    let onStageSkip: () -> Void
    let onStageResult: (_ correct: Int, _ total: Int, _ didSkip: Bool) -> Void
    let onReturnHome: () -> Void

    private let totalRounds = 3
    private let requiredQuickActionsPerRound = 2

    var body: some View {
        ZStack {
            backgroundView
            ornaments

            content
                .opacity(phaseOpacity)
                .animation(.easeInOut(duration: 0.35), value: phaseOpacity)

            if let resultOverlay {
                resultOverlayView(resultOverlay)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            pulse = true
            drift = true
            motion.start()
            startFlow()
        }
        .onDisappear {
            motion.stop()
            cancelAllScheduled()
        }
        .onChange(of: motion.currentState) { _, state in
            if state == .success {
                handleRoundSuccess()
            } else if state == .failed {
                handleRoundFailure()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .intro:
            introView
        case .prompt:
            promptView
        case .ready:
            readyView
        case .play:
            playView
        case .finished:
            finishedView
        }
    }

    private var introView: some View {
        VStack(spacing: 14) {
            Text("🍵")
                .font(.system(size: 40))
            Text("ステージ2 配膳作法")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
            Text("丁寧に運び、静かに置け")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("iPadをお盆に見立て、こぼさずに配膳する")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.55), lineWidth: 1.2)
        )
    }

    private var promptView: some View {
        Text("配膳ミッション開始！")
            .font(.system(size: 52, weight: .black, design: .rounded))
            .foregroundStyle(.yellow)
            .shadow(color: .red.opacity(0.75), radius: 16)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .onAppear {
                PopSoundPlayer.shared.playOnce()
            }
    }

    private var readyView: some View {
        VStack(spacing: 12) {
            Text("準備")
                .font(.title.bold())
                .foregroundStyle(.white.opacity(0.88))
            Text("\(readyCountdown)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var playView: some View {
        VStack(spacing: 12) {
            HStack {
                Button("ホーム") { onReturnHome() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("ステージスキップ") {
                    sendResultIfNeeded(didSkip: true)
                    onStageSkip()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 14)

            HStack(spacing: 10) {
                statChip("ROUND", "\(roundIndex + 1)/\(totalRounds)")
                statChip("SCORE", "\(score)")
                statChip("COMBO", "x\(combo)")
            }
            .padding(.horizontal, 14)

            instructionCard
                .padding(.horizontal, 14)

            traySimulation

            progressBars
                .padding(.horizontal, 14)
        }
        .padding(.top, 8)
    }

    private func statChip(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2.bold()).foregroundStyle(.white.opacity(0.7))
            Text(value).font(.headline.bold()).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ミッション")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.75))

            if motion.currentState == .carrying {
                Text("傾けすぎずに運ぶ（安定ゲージを満タンに）")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            } else if motion.currentState == .placing {
                Text("前にゆっくり傾けて、静かに置く")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            } else if motion.currentState == .failed {
                Text("急な動きでこぼれました")
                    .font(.headline.bold())
                    .foregroundStyle(.orange)
            } else {
                Text("姿勢を整えて開始")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
    }

    private var traySimulation: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let centerY = geo.size.height / 2 + 8
            let trayW: CGFloat = min(geo.size.width * 0.85, 560)
            let trayH: CGFloat = 250

            ZStack {
                // Destination table target
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.cyan.opacity(0.8), style: StrokeStyle(lineWidth: 2.2, dash: [10, 8]))
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.cyan.opacity(0.12))
                    )
                    .frame(width: trayW * 0.55, height: 84)
                    .position(x: centerX, y: 46)
                    .opacity(motion.currentState == .placing ? 1 : 0.45)
                    .animation(.easeInOut(duration: 0.25), value: motion.currentState)

                // Tray
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.42, green: 0.29, blue: 0.18), Color(red: 0.30, green: 0.20, blue: 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.3)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)

                    // Cup + tea
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.92))
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(Color.black.opacity(0.24))
                            .frame(width: 92, height: 92)
                        Circle()
                            .fill(Color(red: 0.19, green: 0.45, blue: 0.25))
                            .frame(width: 88, height: 88)
                            .offset(motion.teaOffset)
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.75), value: motion.teaOffset)
                    }
                    .offset(y: -6)

                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .offset(x: -trayW * 0.25, y: 66)
                }
                .frame(width: trayW, height: trayH)
                .rotation3DEffect(.degrees(motion.visualPitch), axis: (x: 1, y: 0, z: 0), perspective: 0.65)
                .rotation3DEffect(.degrees(motion.visualRoll), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
                .position(x: centerX, y: centerY)
                .offset(y: motion.currentState == .placing ? -92 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: motion.currentState)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 18)
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            if value.translation.width > 0 {
                                performQuickAction(.swipeRight)
                            } else {
                                performQuickAction(.swipeLeft)
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        performQuickAction(.tap)
                    }
                )

                if motion.spillFlash {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.95), lineWidth: 12)
                        .padding(6)
                        .transition(.opacity)
                }
            }
        }
        .frame(height: 360)
    }

    private var progressBars: some View {
        VStack(spacing: 10) {
            gauge(title: "安定", value: motion.stabilityProgress, color: .green)
            gauge(title: "丁寧さ", value: motion.gentlePlacementProgress, color: .cyan)
            if let quickAction, motion.currentState == .carrying || motion.currentState == .placing {
                HStack(spacing: 8) {
                    Image(systemName: quickAction.iconName)
                        .font(.headline.bold())
                    Text("瞬間アクション: \(quickAction.label)")
                        .font(.headline.bold())
                    Spacer()
                    Text("\(quickActionSuccessCount)/\(requiredQuickActionsPerRound)")
                        .font(.subheadline.bold())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .foregroundStyle(.white)
                .background(Color.orange.opacity(0.30), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.9), lineWidth: 1.2)
                )
            }
            HStack {
                Text("傾き: \(motion.tiltText)")
                Spacer()
                Text("揺れ: \(motion.shakeText)")
            }
            .font(.caption.bold())
            .foregroundStyle(.white.opacity(0.82))
        }
    }

    private func gauge(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption.bold()).foregroundStyle(.white.opacity(0.82))
                Spacer()
                Text("\(Int(value * 100))%").font(.caption.bold()).foregroundStyle(.white.opacity(0.86))
            }
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.18)).frame(height: 12)
                Capsule()
                    .fill(color)
                    .frame(width: max(10, 320 * value), height: 12)
                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.78), value: value)
            }
            .frame(width: 320, height: 12)
        }
    }

    private func resultOverlayView(_ result: RoundResult) -> some View {
        VStack(spacing: 10) {
            Image(systemName: result.correct ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .font(.system(size: 78, weight: .bold))
                .foregroundStyle(result.correct ? .green : .red)
                .scaleEffect(pulse ? 1.07 : 0.95)
            Text(result.correct ? "成功" : "失敗")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(result.message)
                .font(.headline.bold())
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.58), lineWidth: 1.2)
        )
    }

    private var finishedView: some View {
        VStack(spacing: 16) {
            if showClearBurst {
                Text("STAGE CLEAR")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.28), radius: 12, y: 8)
                    .scaleEffect(pulse ? 1.04 : 0.96)
            }
            Text("配膳作法クリア")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("正解 \(correctCount) / \(totalRounds)")
                .font(.title3.bold())
                .foregroundStyle(.yellow)
            Text("最終スコア \(score)")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.92))
        }
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.14, blue: 0.26), Color(red: 0.24, green: 0.18, blue: 0.31), Color(red: 0.10, green: 0.25, blue: 0.33)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [Color.white.opacity(0.07), .clear, Color.yellow.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var ornaments: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.18))
                .frame(width: 200, height: 200)
                .offset(x: drift ? 170 : 150, y: drift ? -300 : -260)
            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 240, height: 240)
                .offset(x: drift ? -180 : -150, y: drift ? 260 : 220)
            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: 1.2)
                .frame(width: 170, height: 170)
                .offset(x: 130, y: 240)
        }
        .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: drift)
        .allowsHitTesting(false)
    }

    private func startFlow() {
        cancelAllScheduled()
        stageResultSent = false
        roundIndex = 0
        score = 0
        combo = 0
        correctCount = 0
        resultOverlay = nil
        showClearBurst = false
        roundLocked = false
        quickAction = nil
        quickActionSuccessCount = 0
        quickActionTimeoutItem?.cancel()
        quickActionTimeoutItem = nil
        motion.resetRound()
        animatePhaseChange(to: .intro)
        QuizAudioPlayer.shared.playOnce()
        schedule(after: 2.8) {
            animatePhaseChange(to: .prompt)
            schedule(after: 2.2) {
                readyCountdown = 3
                animatePhaseChange(to: .ready)
                CountdownSoundPlayer.shared.playOnce()
                tickReady()
            }
        }
    }

    private func tickReady() {
        if readyCountdown <= 1 {
            animatePhaseChange(to: .play)
            motion.beginRound()
            startQuickActionSequence()
            return
        }
        schedule(after: 1) {
            readyCountdown -= 1
            tickReady()
        }
    }

    private func handleRoundSuccess() {
        guard resultOverlay == nil, !roundLocked else { return }
        roundLocked = true
        clearQuickActionState()
        guard quickActionSuccessCount >= requiredQuickActionsPerRound else {
            combo = 0
            score = max(0, score - 20)
            resultOverlay = .init(correct: false, message: "動作は丁寧ですが、瞬間アクション不足")
            QuizResultSoundPlayer.shared.playWrong()
            schedule(after: 1.0) {
                resultOverlay = nil
                nextRoundOrFinish()
            }
            return
        }
        combo += 1
        correctCount += 1
        let roundBonus = Int((motion.stabilityProgress + motion.gentlePlacementProgress) * 40)
        score += 120 + combo * 15 + roundBonus
        resultOverlay = .init(correct: true, message: "丁寧な配膳でした")
        QuizResultSoundPlayer.shared.playCorrect()
        schedule(after: 1.0) {
            resultOverlay = nil
            nextRoundOrFinish()
        }
    }

    private func handleRoundFailure() {
        guard resultOverlay == nil, !roundLocked else { return }
        roundLocked = true
        clearQuickActionState()
        combo = 0
        score = max(0, score - 30)
        resultOverlay = .init(correct: false, message: "急な動きで作法が崩れました")
        QuizResultSoundPlayer.shared.playWrong()
        schedule(after: 1.0) {
            resultOverlay = nil
            nextRoundOrFinish()
        }
    }

    private func nextRoundOrFinish() {
        if roundIndex >= totalRounds - 1 {
            sendResultIfNeeded(didSkip: false)
            showClearBurst = true
            animatePhaseChange(to: .finished)
            schedule(after: 1.1) {
                onStageClear()
            }
            return
        }
        roundIndex += 1
        roundLocked = false
        quickActionSuccessCount = 0
        clearQuickActionState()
        motion.resetRound()
        animatePhaseChange(to: .play)
        motion.beginRound()
        startQuickActionSequence()
    }

    private func sendResultIfNeeded(didSkip: Bool) {
        guard !stageResultSent else { return }
        stageResultSent = true
        onStageResult(correctCount, totalRounds, didSkip)
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
        clearQuickActionState()
    }

    private func startQuickActionSequence() {
        quickActionSuccessCount = 0
        scheduleNextQuickAction()
    }

    private func scheduleNextQuickAction() {
        guard !roundLocked else { return }
        guard quickActionSuccessCount < requiredQuickActionsPerRound else {
            quickAction = nil
            return
        }
        let next = QuickActionKind.allCases.randomElement() ?? .tap
        quickAction = next
        quickActionTimeoutItem?.cancel()
        let item = DispatchWorkItem {
            guard !roundLocked else { return }
            if quickAction == next {
                handleFail("指示された瞬間アクションに失敗")
            }
        }
        quickActionTimeoutItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: item)
    }

    private func performQuickAction(_ action: QuickActionKind) {
        guard !roundLocked else { return }
        guard motion.currentState == .carrying || motion.currentState == .placing else { return }
        guard let expected = quickAction else { return }
        if expected == action {
            quickActionTimeoutItem?.cancel()
            quickActionTimeoutItem = nil
            quickActionSuccessCount += 1
            quickAction = nil
            if quickActionSuccessCount < requiredQuickActionsPerRound {
                schedule(after: 0.45) {
                    scheduleNextQuickAction()
                }
            }
        } else {
            handleFail("瞬間アクションが違います")
        }
    }

    private func handleFail(_ message: String) {
        guard !roundLocked, resultOverlay == nil else { return }
        roundLocked = true
        clearQuickActionState()
        motion.failExternally()
        combo = 0
        score = max(0, score - 30)
        resultOverlay = .init(correct: false, message: message)
        QuizResultSoundPlayer.shared.playWrong()
        schedule(after: 1.0) {
            resultOverlay = nil
            nextRoundOrFinish()
        }
    }

    private func clearQuickActionState() {
        quickActionTimeoutItem?.cancel()
        quickActionTimeoutItem = nil
        quickAction = nil
    }

    private enum Phase {
        case intro
        case prompt
        case ready
        case play
        case finished
    }
}

private enum QuickActionKind: CaseIterable {
    case tap
    case swipeLeft
    case swipeRight

    var label: String {
        switch self {
        case .tap:
            return "タップ"
        case .swipeLeft:
            return "左スワイプ"
        case .swipeRight:
            return "右スワイプ"
        }
    }

    var iconName: String {
        switch self {
        case .tap:
            return "hand.tap.fill"
        case .swipeLeft:
            return "arrow.left.circle.fill"
        case .swipeRight:
            return "arrow.right.circle.fill"
        }
    }
}

private struct RoundResult {
    let correct: Bool
    let message: String
}

final class HaizenMotionService: ObservableObject {
    enum RoundState {
        case idle
        case carrying
        case placing
        case success
        case failed
    }

    @Published var currentState: RoundState = .idle
    @Published var stabilityProgress: Double = 0
    @Published var gentlePlacementProgress: Double = 0
    @Published var visualRoll: Double = 0
    @Published var visualPitch: Double = 0
    @Published var teaOffset: CGSize = .zero
    @Published var spillFlash = false
    @Published var tiltText = "0°"
    @Published var shakeText = "0.00"

    private let motionManager = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "reigi.haizen.motion"
        return q
    }()

    private var baselineShake = 0.0
    private var spillCooldownUntil = Date.distantPast

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.handleMotion(motion)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    func beginRound() {
        DispatchQueue.main.async {
            self.currentState = .carrying
        }
    }

    func resetRound() {
        DispatchQueue.main.async {
            self.currentState = .idle
            self.stabilityProgress = 0
            self.gentlePlacementProgress = 0
            self.spillFlash = false
            self.visualRoll = 0
            self.visualPitch = 0
            self.teaOffset = .zero
            self.tiltText = "0°"
            self.shakeText = "0.00"
        }
        baselineShake = 0
    }

    func failExternally() {
        DispatchQueue.main.async {
            self.markFailed()
        }
    }

    private func handleMotion(_ motion: CMDeviceMotion) {
        let roll = motion.attitude.roll * 180 / .pi
        let pitch = motion.attitude.pitch * 180 / .pi
        let a = motion.userAcceleration
        let shake = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)

        if baselineShake == 0 {
            baselineShake = shake
        } else {
            baselineShake = baselineShake * 0.94 + shake * 0.06
        }
        let dynamicShake = max(0, shake - baselineShake)

        let tilt = max(abs(roll), abs(pitch))
        let stableNow = tilt < 16 && dynamicShake < 0.18
        let tooRough = tilt > 33 || dynamicShake > 0.95

        DispatchQueue.main.async {
            self.visualRoll = min(max(roll, -24), 24)
            self.visualPitch = min(max(pitch, -24), 24)
            self.teaOffset = CGSize(width: self.visualRoll * 0.48, height: self.visualPitch * 0.42)
            self.tiltText = "\(Int(tilt))"
            self.shakeText = String(format: "%.2f", dynamicShake)

            switch self.currentState {
            case .idle, .success, .failed:
                break

            case .carrying:
                if stableNow {
                    self.stabilityProgress = min(1.0, self.stabilityProgress + 0.022)
                } else {
                    self.stabilityProgress = max(0, self.stabilityProgress - 0.01)
                }
                if tooRough {
                    self.markFailed()
                    return
                }
                if self.stabilityProgress >= 1.0 {
                    self.currentState = .placing
                }

            case .placing:
                let placingAngleOK = pitch > 18 && pitch < 34
                let gentle = dynamicShake < 0.16 && abs(roll) < 14
                if placingAngleOK && gentle {
                    self.gentlePlacementProgress = min(1.0, self.gentlePlacementProgress + 0.03)
                } else {
                    self.gentlePlacementProgress = max(0, self.gentlePlacementProgress - 0.015)
                }
                if tooRough {
                    self.markFailed()
                    return
                }
                if self.gentlePlacementProgress >= 1.0 {
                    self.currentState = .success
                }
            }
        }
    }

    private func markFailed() {
        let now = Date()
        guard now >= spillCooldownUntil else { return }
        spillCooldownUntil = now.addingTimeInterval(0.8)
        currentState = .failed
        spillFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            self.spillFlash = false
        }
    }
}
