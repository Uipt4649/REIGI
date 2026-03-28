//
//  BowMonitoringService.swift
//  REIGI
//
//  Created by Codex on 2026/03/28.
//

@preconcurrency import AVFoundation
import SwiftUI
import Combine
import UIKit
@preconcurrency import Vision
import ImageIO

final class BowMonitoringService: NSObject, ObservableObject {
    @Published var estimatedAngle: Double?
    @Published var detectedBow: BowAngle?
    @Published var statusText: String = "カメラ準備中..."
    @Published var bowEventCount: Int = 0
    @Published var clapEventCount: Int = 0

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "reigi.camera.session")
    private let videoQueue = DispatchQueue(label: "reigi.camera.video")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var configured = false
    private var smoothedAngle: Double?
    private var cameraPosition: AVCaptureDevice.Position = .front
    private var wasBowed = false
    private var clapClosed = false
    private var isTrackingGestures = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            prepareAndStartSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.prepareAndStartSession()
                } else {
                    DispatchQueue.main.async {
                        self.statusText = "カメラ利用が許可されていません"
                    }
                }
            }
        case .denied, .restricted:
            statusText = "設定からカメラ許可が必要です"
        @unknown default:
            statusText = "カメラ状態を確認できませんでした"
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func beginGestureTracking() {
        DispatchQueue.main.async {
            self.bowEventCount = 0
            self.clapEventCount = 0
        }
        wasBowed = false
        clapClosed = false
        isTrackingGestures = true
    }

    private func prepareAndStartSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.configured {
                self.configureSession()
            }

            guard self.configured else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            DispatchQueue.main.async {
                self.statusText = "人物を検出中..."
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
        }

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        else {
            DispatchQueue.main.async {
                self.statusText = "前面カメラを利用できません"
            }
            return
        }

        session.addInput(input)
        cameraPosition = input.device.position

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(videoOutput) else {
            DispatchQueue.main.async {
                self.statusText = "カメラ出力を設定できません"
            }
            return
        }
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = cameraPosition == .front
            }
        }

        configured = true
    }

    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch currentInterfaceOrientation() {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }

    private func currentInterfaceOrientation() -> UIInterfaceOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}

extension BowMonitoringService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if connection.isVideoOrientationSupported {
            let desired = currentVideoOrientation()
            if connection.videoOrientation != desired {
                connection.videoOrientation = desired
            }
        }

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: visionOrientation(
                videoOrientation: connection.videoOrientation,
                mirrored: connection.isVideoMirrored
            ),
            options: [:]
        )

        do {
            try handler.perform([request])
            guard
                let observation = request.results?.first
            else {
                DispatchQueue.main.async {
                    self.statusText = "人物が見つかりません"
                    self.detectedBow = nil
                }
                return
            }

            guard
                let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
                let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
                let leftHip = try? observation.recognizedPoint(.leftHip),
                let rightHip = try? observation.recognizedPoint(.rightHip),
                leftShoulder.confidence > 0.3,
                rightShoulder.confidence > 0.3,
                leftHip.confidence > 0.3,
                rightHip.confidence > 0.3
            else {
                DispatchQueue.main.async {
                    self.statusText = "姿勢点の検出待機中..."
                    self.detectedBow = nil
                }
                return
            }

            let shoulder = CGPoint(
                x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
                y: (leftShoulder.location.y + rightShoulder.location.y) / 2
            )
            let hip = CGPoint(
                x: (leftHip.location.x + rightHip.location.x) / 2,
                y: (leftHip.location.y + rightHip.location.y) / 2
            )

            let dx = shoulder.x - hip.x
            let dy = shoulder.y - hip.y
            let length = sqrt(dx * dx + dy * dy)
            guard length > 0.001 else { return }

            let unitX = dx / length
            let unitY = dy / length
            let verticalX: CGFloat = 0
            let verticalY: CGFloat = 1
            let dot = max(-1.0, min(1.0, unitX * verticalX + unitY * verticalY))
            let raw = Double(acos(dot) * 180 / .pi)

            // Vision推定の揺れを軽減するため、単純な平滑化をかける。
            let smoothed: Double
            if let previous = smoothedAngle {
                smoothed = previous * 0.75 + raw * 0.25
            } else {
                smoothed = raw
            }
            smoothedAngle = smoothed

            let bow = BowAngle.from(detectedDegrees: smoothed)

            if isTrackingGestures {
                let bowedNow = smoothed >= 25
                if bowedNow && !wasBowed {
                    DispatchQueue.main.async {
                        self.bowEventCount += 1
                    }
                }
                wasBowed = bowedNow

                if
                    let leftWrist = try? observation.recognizedPoint(.leftWrist),
                    let rightWrist = try? observation.recognizedPoint(.rightWrist),
                    leftWrist.confidence > 0.2,
                    rightWrist.confidence > 0.2
                {
                    let wristDx = leftWrist.location.x - rightWrist.location.x
                    let wristDy = leftWrist.location.y - rightWrist.location.y
                    let wristDistance = sqrt(wristDx * wristDx + wristDy * wristDy)
                    let shoulderDx = leftShoulder.location.x - rightShoulder.location.x
                    let shoulderDy = leftShoulder.location.y - rightShoulder.location.y
                    let shoulderWidth = max(0.001, sqrt(shoulderDx * shoulderDx + shoulderDy * shoulderDy))
                    let normalized = wristDistance / shoulderWidth

                    if !clapClosed && normalized < 0.35 {
                        clapClosed = true
                    } else if clapClosed && normalized > 0.55 {
                        clapClosed = false
                        DispatchQueue.main.async {
                            self.clapEventCount += 1
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                self.estimatedAngle = smoothed
                self.detectedBow = bow
                self.statusText = "姿勢検出中"
            }
        } catch {
            DispatchQueue.main.async {
                self.statusText = "姿勢解析エラー"
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer.session = session
        if let connection = uiView.previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = previewVideoOrientation()
        }
    }

    private func previewVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}

final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

extension BowAngle {
    static func from(detectedDegrees: Double) -> BowAngle {
        let angle = max(0, min(90, detectedDegrees))
        switch angle {
        case 0..<23:
            return .eishaku
        case 23..<40:
            return .keirei
        default:
            return .saikeirei
        }
    }
}

private func visionOrientation(
    videoOrientation: AVCaptureVideoOrientation,
    mirrored: Bool
) -> CGImagePropertyOrientation {
    switch videoOrientation {
    case .portrait:
        return mirrored ? .rightMirrored : .left
    case .portraitUpsideDown:
        return mirrored ? .leftMirrored : .right
    case .landscapeLeft:
        return mirrored ? .upMirrored : .up
    case .landscapeRight:
        return mirrored ? .downMirrored : .down
    @unknown default:
        return mirrored ? .rightMirrored : .left
    }
}

