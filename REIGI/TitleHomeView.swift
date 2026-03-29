//
//  TitleHomeView.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import SwiftUI

struct TitleHomeView: View {
    @ObservedObject private var historyStore = PlayHistoryStore.shared
    @State private var showMenu = false
    @State private var animateTitle = false
    @State private var animateButton = false
    @State private var float3D = false
    @AppStorage("reigi.bgmMuted") private var bgmMuted = false

    let startGame: () -> Void
    let startFromStage: (Int) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            japaneseBackground
                .ignoresSafeArea()

            fullScreenLogo

            decorativeStickers

            VStack(spacing: 24) {
                topBar

                Spacer()

                VStack(spacing: 14) {
                    Text("礼儀")
                        .font(.system(size: 56, weight: .black, design: .serif))
                        .foregroundStyle(Color(red: 0.20, green: 0.08, blue: 0.08))
                        .opacity(animateTitle ? 1 : 0)
                        .offset(y: animateTitle ? 0 : 10)

                    Text("REIGI QUEST")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.52, green: 0.16, blue: 0.16))
                    

                    Text("日本の礼儀作法をゲームで学ぶ")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)

                historyCard
                    .padding(.horizontal, 20)

                Button {
                    startGame()
                } label: {
                    Text("START")
                        .font(.title2.weight(.heavy))
                        .kerning(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(alignment: .center) {
                            ZStack {
                                LinearGradient(
                                    colors: [Color(red: 0.67, green: 0.14, blue: 0.14), Color(red: 0.45, green: 0.09, blue: 0.09)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                LinearGradient(
                                    colors: [Color.white.opacity(0.40), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            }
                        }
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .scaleEffect(animateButton ? 1.02 : 0.98)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.65).opacity(0.45), radius: 16, y: 4)
                .padding(.horizontal, 28)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateButton)
                .rotation3DEffect(
                    .degrees(float3D ? 7 : 2),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.7
                )

                Text("左端からスワイプ または 左上メニューでステージ一覧")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()

            if showMenu {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        closeMenu()
                    }
                    .zIndex(1)
            }

            StageDrawerMenu(
                isOpen: showMenu,
                stages: stages,
                bgmMuted: $bgmMuted,
                startFromStage: { index in
                    closeMenu()
                    startFromStage(index)
                }
            )
            .allowsHitTesting(showMenu)
            .zIndex(2)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateTitle = true
            }
            animateButton = true
            float3D = true
            MainBGMPlayer.shared.playMainLoop()
        }
        .onDisappear {
            MainBGMPlayer.shared.stop()
        }
        .onChange(of: bgmMuted) { _, muted in
            AudioMuteState.setMuted(muted)
            if !muted {
                MainBGMPlayer.shared.playMainLoop()
            }
        }
        .simultaneousGesture(menuDragGesture, including: showMenu ? .none : .all)
    }

    private var menuDragGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                if value.startLocation.x < 24, value.translation.width > 40 {
                    openMenu()
                } else if value.translation.width < -40 {
                    closeMenu()
                }
            }
    }

    private func openMenu() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            showMenu = true
        }
    }

    private func closeMenu() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            showMenu = false
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                showMenu ? closeMenu() : openMenu()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.44, green: 0.12, blue: 0.12))
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.65), lineWidth: 1)
                    )
            }

            Spacer()

            Text("TITLE")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private var japaneseBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.99, green: 0.97, blue: 0.92), Color(red: 0.98, green: 0.89, blue: 0.90), Color(red: 0.91, green: 0.93, blue: 0.99)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.22)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            VStack(spacing: 0) {
                ForEach(0..<14, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { col in
                            Rectangle()
                                .stroke(Color(red: 0.73, green: 0.58, blue: 0.40).opacity((row + col).isMultiple(of: 2) ? 0.14 : 0.06), lineWidth: 0.5)
                                .frame(height: 32)
                        }
                    }
                }
            }
            .opacity(0.4)
        }
    }

    private var decorativeStickers: some View {
        ZStack {
            Circle()
                .fill(Color(red: 1.0, green: 0.83, blue: 0.62).opacity(0.32))
                .frame(width: 180, height: 180)
                .blur(radius: 0.5)
                .offset(x: 150, y: -270)
                .shadow(color: Color(red: 1.0, green: 0.83, blue: 0.62).opacity(0.35), radius: 22, y: 8)
            Circle()
                .fill(Color(red: 0.92, green: 0.65, blue: 0.65).opacity(0.30))
                .frame(width: 220, height: 220)
                .offset(x: -165, y: -185)
                .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
            Circle()
                .fill(Color(red: 0.71, green: 0.84, blue: 1.0).opacity(0.22))
                .frame(width: 130, height: 130)
                .offset(x: 145, y: 228)
            Circle()
                .fill(Color(red: 0.86, green: 0.96, blue: 0.78).opacity(0.16))
                .frame(width: 260, height: 260)
                .offset(x: 188, y: 28)
            Circle()
                .fill(Color(red: 1.0, green: 0.73, blue: 0.73).opacity(0.16))
                .frame(width: 112, height: 112)
                .offset(x: -22, y: -305)
            Circle()
                .fill(Color(red: 0.85, green: 0.78, blue: 1.0).opacity(0.15))
                .frame(width: 86, height: 86)
                .offset(x: -188, y: 94)
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 74, height: 74)
                .offset(x: 20, y: -228)
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 52, height: 52)
                .offset(x: -120, y: 255)
            Circle()
                .stroke(Color.white.opacity(0.24), lineWidth: 1.4)
                .frame(width: 160, height: 160)
                .offset(x: 36, y: 246)
        }
        .rotation3DEffect(
            .degrees(float3D ? 8 : 3),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.7
        )
        .allowsHitTesting(false)
    }

    private var fullScreenLogo: some View {
        Image("礼儀")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(0.20)
            .padding(.horizontal, 8)
            .allowsHitTesting(false)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("履歴", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0.52, green: 0.16, blue: 0.16))
                Spacer()
            }

            if historyStore.entries.isEmpty {
                Text("まだ履歴がありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(historyStore.entries.prefix(3))) { entry in
                    historyRow(entry)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.58), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private func historyRow(_ entry: PlayHistoryEntry) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.stageTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(entry.playMode.rawValue) • \(entry.correct)/\(entry.total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(entry.accuracyText)
                .font(.caption.weight(.bold))
                .foregroundStyle(entry.didSkip ? .orange : .green)
        }
        .padding(.vertical, 2)
    }
}

private struct StageDrawerMenu: View {
    let isOpen: Bool
    let stages: [StageInfo]
    @Binding var bgmMuted: Bool
    let startFromStage: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ステージ一覧")
                .font(.title3.weight(.bold))
            Text("途中から開始できます")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(stages) { stage in
                Button {
                    startFromStage(stage.id)
                } label: {
                    HStack(spacing: 10) {
                        if let emoji = stage.emoji {
                            Text(emoji)
                                .font(.title3)
                        } else if let icon = stage.icon {
                            Image(systemName: icon)
                                .foregroundStyle(Color(red: 0.55, green: 0.15, blue: 0.15))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.title)
                                .font(.subheadline.weight(.semibold))
                            Text(stage.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.58), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                bgmMuted.toggle()
            } label: {
                HStack {
                    Image(systemName: bgmMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    Text(bgmMuted ? "BGM ONにする" : "BGM OFFにする")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.60), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 18)
        }
        .padding(.top, 80)
        .padding(.horizontal, 14)
        .frame(width: 280)
        .frame(maxHeight: .infinity)
        .background(.regularMaterial)
        .overlay(
            LinearGradient(
                colors: [Color.white.opacity(0.35), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .allowsHitTesting(false)
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1)
                .allowsHitTesting(false),
            alignment: .trailing
        )
        .contentShape(Rectangle())
        .offset(x: isOpen ? 0 : -300)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: isOpen)
    }
}
