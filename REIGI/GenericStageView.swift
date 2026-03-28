//
//  GenericStageView.swift
//  REIGI
//  Created by 渡邉羽唯 on 2026/03/28.
//

import SwiftUI

struct GenericStageView: View {
    let stage: StageInfo
    let onNext: () -> Void
    let onReturnHome: () -> Void

    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.98, blue: 0.95), Color(red: 0.86, green: 0.93, blue: 0.87)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Button("ホーム") { onReturnHome() }
                        .buttonStyle(.bordered)
                    Spacer()
                }

                if let emoji = stage.emoji {
                    Text(emoji)
                        .font(.system(size: 64))
                        .scaleEffect(animate ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: animate)
                } else if let icon = stage.icon {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .scaleEffect(animate ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: animate)
                }

                Text(stage.title)
                    .font(.title.bold())
                Text(stage.subtitle)
                    .foregroundStyle(.secondary)

                Text("このステージはUIプレースホルダーです。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("次へ進む") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.12, green: 0.47, blue: 0.29))

                Spacer()
            }
            .padding()
        }
        .onAppear {
            animate = true
        }
    }
}
