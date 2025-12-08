//
//  AIcameraViewController.swift
//  SwiftUI-Interface
//
//  Created by Christian on 12.05.2024.
//

/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The camera view controller manages the video capture pipeline.
 */


import SwiftUI
import UIKit
import AVFoundation
import Vision

struct CameraView: UIViewControllerRepresentable {
    var videoURL: URL?
    var frame: CGRect
    @Binding var controller: AIcameraViewController?
    
    func makeUIViewController(context: Context) -> AIcameraViewController {
        let controller = AIcameraViewController(frame: frame)
        if let videoURL = videoURL {
            controller.setupWithVideoURL(videoURL)
        }
        DispatchQueue.main.async {
            self.controller = controller
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AIcameraViewController, context: Context) {
        uiViewController.updateLayout(frame: frame)

        if let videoURL {
            print("🔄 [AI VIEW] Updating controller with video:", videoURL.lastPathComponent)
            uiViewController.setupWithVideoURL(videoURL)
        } else {
            print("⚠️ [AI VIEW] updateUIViewController called with NIL videoURL")
        }
    }

    
}


class AIcameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var VideoCoachRenderView: VideoCoachRenderView!
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInitiated,
                                                     attributes: [], autoreleaseFrequency: .workItem)
    var aiCoach = AICoach()
    private let gameManager = GameManager.shared
    
    // Video file playback management
    private var playerItemOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    private let videoFileReadingQueue = DispatchQueue(label: "VideoFileReading", qos: .userInteractive)
    private var videoFileBufferOrientation = CGImagePropertyOrientation.up
    private var videoFileFrameDuration = CMTime.invalid
    
    private var bodyPoseRequest: VNDetectHumanBodyPoseRequest!
    
    private var jointLayer = CAShapeLayer()
    private var jointSegmentLayer = CAShapeLayer()
    private var jointPath = UIBezierPath()
    private var jointSegmentPath = UIBezierPath()
    
    private var overlayView: UIView!
    
    private var jointMarkerSize: CGFloat = 0.5
    private var jointLineWidth: CGFloat = 1.0
    
        private var progressLink: CADisplayLink?
    
    private var lastObservation: VNHumanBodyPoseObservation?
    
    // Export support
    private var exportOverlayLayer = CALayer()
    private var exportQueue = DispatchQueue(label: "export.queue")

    
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
        self.view.frame = frame
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bodyPoseRequest = VNDetectHumanBodyPoseRequest(completionHandler: handleBodyPose)
        
        // Initialize the overlay view
        overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false  // Important: let touches pass through
                
        
        setupLayers()
        aiCoach.feedbackHandler = {
            short, detailed in
            let gm = GameManager.shared
            gm.playerStats.feedbackArray = short.components(separatedBy: "\n")
            gm.playerStats.feedbackArrayDetailed = detailed.components(separatedBy: "\n")
            
            NotificationCenter.default.post(
                name: GameStateChangeNotification.name,
                object: GameStateChangeNotification.gameManager,
                userInfo: nil
            )
        }
    }
    
    

    
    // 5. Update the updateLayout method to use continuous updates
    func updateLayout(frame: CGRect) {
        self.view.frame = frame
        
        // Immediate layout
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        VideoCoachRenderView?.frame = view.bounds
        VideoCoachRenderView?.setNeedsLayout()
        VideoCoachRenderView?.layoutIfNeeded()
        
        // Update overlay immediately
        updateOverlayLayout()
    }
    
    private struct JointConnection {
        let start: CGPoint
        let end: CGPoint
        let startConfidence: Float
        let endConfidence: Float
    }

    private var cachedJointConnections: [JointConnection] = []

    // Modified redrawSkeleton to cache normalized positions
    private func redrawSkeleton(from observation: VNHumanBodyPoseObservation) {
        do {
            let recognizedPoints = try observation.recognizedPoints(.all)
            let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                (.rightShoulder, .rightElbow),
                (.rightElbow, .rightWrist),
                (.rightShoulder, .rightHip),
                (.rightHip, .rightKnee),
                (.rightKnee, .rightAnkle)
            ]
            
            cachedJointConnections.removeAll()
            for (startJoint, endJoint) in connections {
                guard let startPoint = recognizedPoints[startJoint],
                      let endPoint = recognizedPoints[endJoint],
                      startPoint.confidence > 0.1,
                      endPoint.confidence > 0.1 else {
                    continue
                }
                cachedJointConnections.append(JointConnection(
                    start: startPoint.location,
                    end: endPoint.location,
                    startConfidence: startPoint.confidence,
                    endConfidence: endPoint.confidence
                ))
            }

            print("🦴 Caching joints — raw Vision normalized coordinates:")
            for c in cachedJointConnections {
                print("   start:", c.start, "end:", c.end)
            }
            
            drawSkeletonFromCache()
            
        } catch {
            print("Error redrawing skeleton: \(error)")
        }
    }

    
    // New method: Draw skeleton from cached normalized positions
    private func drawSkeletonFromCache() {
        self.jointPath.removeAllPoints()
        self.jointSegmentPath.removeAllPoints()
        
        guard let videoView = VideoCoachRenderView else { return }

        print("🖼 drawSkeletonFromCache() — video bounds:", videoView.bounds)
        
        for connection in cachedJointConnections {
            let viewStart = videoView.viewPointConverted(fromNormalizedContentsPoint: connection.start)
            let viewEnd = videoView.viewPointConverted(fromNormalizedContentsPoint: connection.end)

            print("   🎯 converted start:", viewStart, "end:", viewEnd)
            
            let startCircle = UIBezierPath(arcCenter: viewStart, radius: 2.0, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            self.jointPath.append(startCircle)
            
            let endCircle = UIBezierPath(arcCenter: viewEnd, radius: 2.0, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            self.jointPath.append(endCircle)
            
            self.jointSegmentPath.move(to: viewStart)
            self.jointSegmentPath.addLine(to: viewEnd)
        }
        
        self.jointLayer.path = self.jointPath.cgPath
        self.jointSegmentLayer.path = self.jointSegmentPath.cgPath
    }

    
    
    
    func startProgressUpdates() {
        progressLink?.invalidate()
        
        let link = CADisplayLink(target: self, selector: #selector(updateVideoProgress))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .default)
        progressLink = link
    }
    
    
    @objc private func updateVideoProgress() {
        guard let player = VideoCoachRenderView?.player else {
            print("⚠️ No player for progress")
            return
        }
        guard let item = player.currentItem else {
            print("⚠️ No playerItem for progress")
            return
        }
        
        let duration = item.duration.seconds
        let current = player.currentTime().seconds
        
        if duration > 0 {
            let p = max(0, min(current / duration, 1))
            GameStateObserver.shared.videoProgress = p
        }
    }
    
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        VideoCoachRenderView?.frame = self.view.bounds
        updateOverlayLayout()
    }
    
    
    func setupLayers() {
        // Nice bright green (tennis-style)
        let accent = UIColor(red: 0.10, green: 0.95, blue: 0.45, alpha: 1).cgColor
        
        jointLayer.strokeColor = accent
        jointLayer.fillColor = accent
        jointLayer.lineWidth = 4    // thicker joint dots
        
        jointSegmentLayer.strokeColor = accent
        jointSegmentLayer.fillColor = nil
        jointSegmentLayer.lineWidth = 3.5   // thicker skeleton lines
        
        
        jointSegmentLayer.frame = overlayView.bounds
        jointLayer.frame = overlayView.bounds
        
        overlayView.layer.addSublayer(jointLayer)
        overlayView.layer.addSublayer(jointSegmentLayer)
        overlayView.layer.zPosition = 2000
    }
    
    
    func setupVideoOutputView(_ videoOutputView: UIView) {
        videoOutputView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoOutputView)
        
        NSLayoutConstraint.activate([
            videoOutputView.topAnchor.constraint(equalTo: view.topAnchor),
            videoOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoOutputView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    
    
    
    func pauseVideoPlayback(multiplier: Int32) {
        VideoCoachRenderView?.pausePlayback()
        displayLink?.invalidate()
        displayLink = nil

        // First compute & store safeTime
        VideoCoachRenderView?.stepBackFrames(multiplier: multiplier)

        guard let safe = VideoCoachRenderView?.safeTime,
              let player = VideoCoachRenderView?.player else { return }

        let seekTime = CMTime(seconds: safe, preferredTimescale: 600)

        player.seek(
            to: seekTime,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] _ in
            self?.processCurrentVideoFrame()

            if let obs = self?.lastObservation {
                DispatchQueue.main.async {
                    self?.redrawSkeleton(from: obs)
                    self?.updateOverlayLayout()
                }
            }
        }
    }


    // Add this new method to manually process the current frame
    private func processCurrentVideoFrame() {
        guard let output = playerItemOutput,
              let player = VideoCoachRenderView?.player else {
            return
        }
        
        let currentTime = player.currentTime()
        
        videoFileReadingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check if we have a new pixel buffer at this time
            guard output.hasNewPixelBuffer(forItemTime: currentTime) else {
                print("⚠️ No pixel buffer available at current time")
                return
            }
            
            guard let pixelBuffer = output.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) else {
                print("⚠️ Failed to copy pixel buffer")
                return
            }
            
            // Process this frame to update the skeleton
            self.processVideoFrame(pixelBuffer: pixelBuffer)
        }
    }
    
    func continuePlayback() {
        self.startDisplayLink()
        VideoCoachRenderView?.player?.play()
    }
    
    func startDisplayLink() {
        let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        link.preferredFramesPerSecond = 0
        link.add(to: .main, forMode: .default)
        displayLink = link
    }
    
    
    
    
    
    func handleBodyPose(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let observations = request.results as? [VNHumanBodyPoseObservation] else {
                print("Failed to obtain body pose results")
                return
            }
            
            // Store the first observation
            self.lastObservation = observations.first
            
            // Draw the skeleton (this also updates cache)
            if let observation = observations.first {
                self.redrawSkeleton(from: observation)
            }
            
            // Game logic remains the same...
            for observation in observations {
                do {
                    let recognizedPoints = try observation.recognizedPoints(.all)
                    let verbose = false
                    
                    if self.gameManager.stateMachine.currentState is GameManager.TryDetectingServe {
                        let (serveDetected, framesPrior) = self.aiCoach.detectServe(from: recognizedPoints, verbose: verbose)
                        if serveDetected {
                            self.pauseVideoPlayback(multiplier: framesPrior)
                            self.gameManager.stateMachine.enter(GameManager.TryDetectingTrophyPose.self)
                            GameStateObserver.shared.serveFramePosition = GameStateObserver.shared.videoProgress
                        }
                    } else {
                        let (trophyPoseDetected, framesPrior) = self.aiCoach.detectTrophyPose(from: recognizedPoints, verbose: verbose)
                        if trophyPoseDetected {
                            self.pauseVideoPlayback(multiplier: framesPrior / 2)
                            self.gameManager.stateMachine.enter(GameManager.TryDetectingServe.self)
                            GameStateObserver.shared.trophyFramePosition = GameStateObserver.shared.videoProgress
                        }
                    }
                } catch {
                    print("Error processing body pose observation: \(error)")
                }
            }
        }
    }

    // OPTIONAL: Force AVPlayerLayer to layout immediately
    func startContinuousLayoutUpdates(duration: TimeInterval = 0.5) {
        layoutUpdateLink?.invalidate()
        
        // Force initial layout
        VideoCoachRenderView?.renderLayer.setNeedsLayout()
        VideoCoachRenderView?.renderLayer.layoutIfNeeded()
        
        let link = CADisplayLink(target: self, selector: #selector(updateOverlayDuringAnimation))
        link.add(to: .main, forMode: .common)
        layoutUpdateLink = link
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.layoutUpdateLink?.invalidate()
            self?.layoutUpdateLink = nil
            self?.updateOverlayLayout()
        }
    }

    @objc private func updateOverlayDuringAnimation() {
        // Force AVPlayerLayer to update its videoRect
        VideoCoachRenderView?.renderLayer.setNeedsLayout()
        VideoCoachRenderView?.renderLayer.layoutIfNeeded()
        

        updateOverlayLayout()
    }

    
    
    private func updatePathForJoint(startPoint: CGPoint, endPoint: CGPoint, scale: CGSize) {
        // Convert normalized points to view points using the VideoCoachRenderView's conversion function
        let viewStart = VideoCoachRenderView.viewPointConverted(fromNormalizedContentsPoint: startPoint)
        let viewEnd = VideoCoachRenderView.viewPointConverted(fromNormalizedContentsPoint: endPoint)
        
        // Create circles at the joint positions
        let startCircle = UIBezierPath(arcCenter: viewStart, radius: 2.0, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        self.jointPath.append(startCircle)
        
        let endCircle = UIBezierPath(arcCenter: viewEnd, radius: 2.0, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        self.jointPath.append(endCircle)
        
        // Draw a line between the joints
        self.jointSegmentPath.move(to: viewStart)
        self.jointSegmentPath.addLine(to: viewEnd)
    }
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Check if the body pose request is set up
        guard let bodyPoseRequest = bodyPoseRequest else {
            return
        }
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([bodyPoseRequest])
        } catch {
            print("Failed to perform body pose request: \(error)")
        }
    }
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        displayLink?.invalidate()
        layoutUpdateLink?.invalidate()
        progressLink?.invalidate()
    }
    
    
    func setupWithVideoURL(_ url: URL) {
        let asset = AVAsset(url: url)
        startReadingAsset(asset)
    }
    
    
    
    func startReadingAsset(_ asset: AVAsset) {
        
        print("🎥 [READER] Starting reader")
        print("🎥 [READER] Asset playable:", asset.isPlayable)
        print("🎥 [READER] Asset readable:", asset.isReadable)

        
        // FIX: remove previous video view
        VideoCoachRenderView?.player?.pause()
        VideoCoachRenderView?.removeFromSuperview()
        VideoCoachRenderView = nil
        
        // Now create a single one
        VideoCoachRenderView = Clay_Tennis.VideoCoachRenderView(frame: view.bounds)
        setupVideoOutputView(VideoCoachRenderView)
        
        overlayView.removeFromSuperview()
        VideoCoachRenderView.addSubview(overlayView)
        overlayView.frame = VideoCoachRenderView.bounds
        
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink.preferredFramesPerSecond = 0
        displayLink.isPaused = true
        displayLink.add(to: RunLoop.current, forMode: .default)
        
        
        guard let track = asset.tracks(withMediaType: .video).first else {
            //AppError.display(AppError.videoReadingError(reason: "No video tracks found in AVAsset."), inViewController: self)
            return
        }
        
        // Set safe minimum seek time to 3 frames
        let frame = track.minFrameDuration.seconds
        self.VideoCoachRenderView.minSeekTime = frame * 3
        
        
        
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let settings = [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
        playerItem.add(output)
        player.actionAtItemEnd = .pause
        player.play()
        startProgressUpdates()
        
        
        self.displayLink = displayLink
        self.playerItemOutput = output
        self.VideoCoachRenderView.player = player
        
        let affineTransform = track.preferredTransform.inverted()
        let angleInDegrees = atan2(affineTransform.b, affineTransform.a) * CGFloat(180) / CGFloat.pi
        var orientation: UInt32 = 1
        switch angleInDegrees {
        case 0:
            orientation = 1 // Recording button is on the right
        case 180, -180:
            orientation = 3 // abs(180) degree rotation recording button is on the right
        case 90:
            orientation = 8 // 90 degree CW rotation recording button is on the top
        case -90:
            orientation = 6 // 90 degree CCW rotation recording button is on the bottom
        default:
            orientation = 1
        }
        videoFileBufferOrientation = CGImagePropertyOrientation(rawValue: orientation)!
        videoFileFrameDuration = track.minFrameDuration
        displayLink.isPaused = false
    }
    
    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        guard let output = playerItemOutput else {
            return
        }
        
        videoFileReadingQueue.async {
            let nextTimeStamp = displayLink.timestamp + displayLink.duration
            let itemTime = output.itemTime(forHostTime: nextTimeStamp)
            guard output.hasNewPixelBuffer(forItemTime: itemTime) else {
                return
            }
            guard let pixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) else {
                return
            }
            
            // Create sample buffer from pixel buffer (if necessary)
            self.processVideoFrame(pixelBuffer: pixelBuffer)
        }
    }
    
    private func processVideoFrame(pixelBuffer: CVPixelBuffer) {
        var requestOptions: [VNImageOption : Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(pixelBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions[.cameraIntrinsics] = cameraIntrinsicData
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: videoFileBufferOrientation, options: requestOptions)
        do {
            try handler.perform([bodyPoseRequest])
        } catch {
            print("Failed to perform body pose request: \(error)")
        }
    }
    
    
    
    private var layoutUpdateLink: CADisplayLink?


    // 4. Add a clean method to update overlay layout
    private func updateOverlayLayout() {
        guard let videoView = VideoCoachRenderView else { return }
        
        // Update frames to match current state
        overlayView.frame = videoView.bounds
        jointLayer.frame = overlayView.bounds
        jointSegmentLayer.frame = overlayView.bounds
        
        // Redraw using cached normalized positions with CURRENT geometry
        drawSkeletonFromCache()
    }
    
    
    private func getVideoSizeAndTransform(from track: AVAssetTrack) -> (size: CGSize, transform: CGAffineTransform, isPortrait: Bool) {
        let naturalSize = track.naturalSize
        let transform = track.preferredTransform
        
        // Calculate actual display size after transform
        let videoSize = naturalSize.applying(transform)
        let normalizedSize = CGSize(
            width: abs(videoSize.width),
            height: abs(videoSize.height)
        )
        
        let isPortrait = normalizedSize.height > normalizedSize.width
        
        print("📐 Video naturalSize: \(naturalSize)")
        print("📐 Video transform: \(transform)")
        print("📐 Video normalized size: \(normalizedSize)")
        print("📐 Is portrait: \(isPortrait)")
        
        return (normalizedSize, transform, isPortrait)
    }

    private func makeExportOverlayLayer(videoSize: CGSize) -> CALayer {
        print("🎨 makeExportOverlayLayer - START")
        print("🎨 videoSize:", videoSize)
        print("🎨 cachedJointConnections count:", cachedJointConnections.count)

        for (i, c) in cachedJointConnections.enumerated() {
            print("   [\(i)] normalized start:", c.start, "end:", c.end)
            let sx = c.start.x * videoSize.width
            let sy = (1 - c.start.y) * videoSize.height
            let ex = c.end.x * videoSize.width
            let ey = (1 - c.end.y) * videoSize.height
            print("   [\(i)] scaled start:", CGPoint(x: sx, y: sy),
                  "scaled end:", CGPoint(x: ex, y: ey))
        }

        let root = CALayer()
        root.frame = CGRect(origin: .zero, size: videoSize)
        root.masksToBounds = true

        let exportJointPath = UIBezierPath()
        let exportSegmentPath = UIBezierPath()

        for connection in cachedJointConnections {
            let startX = connection.start.x * videoSize.width
            let startY = (connection.start.y) * videoSize.height
            let endX = connection.end.x * videoSize.width
            let endY = (connection.end.y) * videoSize.height

            let startPoint = CGPoint(x: startX, y: startY)
            let endPoint = CGPoint(x: endX, y: endY)

            let radius = max(videoSize.width, videoSize.height) * 0.006

            exportJointPath.append(
                UIBezierPath(
                    arcCenter: startPoint,
                    radius: radius,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                )
            )
            exportJointPath.append(
                UIBezierPath(
                    arcCenter: endPoint,
                    radius: radius,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                )
            )

            exportSegmentPath.move(to: startPoint)
            exportSegmentPath.addLine(to: endPoint)
        }

        let joints = CAShapeLayer()
        joints.frame = root.bounds
        joints.strokeColor = jointLayer.strokeColor
        joints.fillColor = jointLayer.fillColor
        joints.lineWidth = max(videoSize.width, videoSize.height) * 0.004
        joints.path = exportJointPath.cgPath

        let segments = CAShapeLayer()
        segments.frame = root.bounds
        segments.strokeColor = jointSegmentLayer.strokeColor
        segments.fillColor = jointSegmentLayer.fillColor
        segments.lineWidth = max(videoSize.width, videoSize.height) * 0.0035
        segments.path = exportSegmentPath.cgPath

        root.addSublayer(joints)
        root.addSublayer(segments)

        print("🎨 Export overlay layer created with sublayers:",
              root.sublayers?.count ?? 0)

        return root
    }


    private func makeVideoComposition(
        asset: AVAsset,
        videoSize: CGSize,
        transform: CGAffineTransform
    ) -> AVVideoComposition {
        print("🎬 makeVideoComposition - videoSize:", videoSize)
        print("🎬 transform:", transform)

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            fatalError("No video track")
        }

        let composition = AVMutableVideoComposition()
        composition.renderSize = videoSize
        composition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]

        let parentLayer = CALayer()
        let videoLayer = CALayer()

        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)

        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(self.exportOverlayLayer)

        print("🎬 Video composition created, renderSize:", composition.renderSize)

        composition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )

        return composition
    }


    func exportVideoWithOverlay(
        originalURL: URL,
        completion: @escaping (URL?) -> Void
    ) {
        print("📹 Dynamic export START:", originalURL)

        let asset = AVAsset(url: originalURL)
        guard let track = asset.tracks(withMediaType: .video).first else {
            print("❌ No video track found")
            completion(nil)
            return
        }

        let naturalSize = track.naturalSize
        let transform = track.preferredTransform
        let fps = track.nominalFrameRate
        let frameDuration = CMTimeMake(value: 1, timescale: Int32(fps))

        let isPortrait = abs(transform.b) == 1.0 && abs(transform.c) == 1.0

        let exportSize: CGSize =
            isPortrait ? CGSize(width: naturalSize.height, height: naturalSize.width)
                       : naturalSize

        print("🎞 naturalSize:", naturalSize)
        print("🎞 exportSize:", exportSize)
        print("🎞 preferredTransform:", transform)
        print("🎞 isPortrait:", isPortrait)

        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            print("❌ Failed to create AVAssetReader:", error)
            completion(nil)
            return
        }

        let readerOutput = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_32BGRA
            ]
        )
        reader.add(readerOutput)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("dynamic_export_\(UUID().uuidString).mp4")

        let writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            print("❌ Failed to create AVAssetWriter:", error)
            completion(nil)
            return
        }

        let writerInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: exportSize.width,
                AVVideoHeightKey: exportSize.height
            ]
        )
        writerInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: exportSize.width,
                kCVPixelBufferHeightKey as String: exportSize.height
            ]
        )

        writer.add(writerInput)

        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: .zero)

        let poseRequest = VNDetectHumanBodyPoseRequest()
        let ciContext = CIContext()

        print("🚀 Export loop started…")

        writerInput.requestMediaDataWhenReady(on: DispatchQueue.global(qos: .userInitiated)) {
            var frameCount: Int64 = 0

            while writerInput.isReadyForMoreMediaData {
                guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                    print("🏁 No more frames — finishing export")
                    writerInput.markAsFinished()
                    writer.finishWriting {
                        print("✅ Export completed:", outputURL)
                        completion(outputURL)
                    }
                    return
                }

                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    print("⚠️ Failed to extract pixel buffer")
                    continue
                }

                let w = CVPixelBufferGetWidth(pixelBuffer)
                let h = CVPixelBufferGetHeight(pixelBuffer)
                print("📦 [EXPORT] Input pixelBuffer:", w, "x", h)

                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                print("🖼 [EXPORT] CIImage extent:", ciImage.extent)
                print("🔄 [EXPORT] preferredTransform:", transform)
                print("📐 [EXPORT] exportSize:", exportSize)

                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                try? handler.perform([poseRequest])

                if let obs = poseRequest.results?.first {
                    self.redrawSkeleton(from: obs)

                    do {
                        let points = try obs.recognizedPoints(.all)
                        self.cachedJointConnections.removeAll()

                        let pairs: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                            (.rightShoulder, .rightElbow),
                            (.rightElbow, .rightWrist),
                            (.rightShoulder, .rightHip),
                            (.rightHip, .rightKnee),
                            (.rightKnee, .rightAnkle)
                        ]

                        for (a, b) in pairs {
                            if let p1 = points[a], let p2 = points[b],
                               p1.confidence > 0.1, p2.confidence > 0.1 {

                                print("👣 [EXPORT] Vision normalized:", p1.location, p2.location)

                                let sp = CGPoint(x: p1.location.x * exportSize.width,
                                                 y: (p1.location.y) * exportSize.height)
                                let ep = CGPoint(x: p2.location.x * exportSize.width,
                                                 y: (p2.location.y) * exportSize.height)

                                print("➡️  [EXPORT] Scaled to:", sp, ep)

                                self.cachedJointConnections.append(
                                    JointConnection(
                                        start: p1.location,
                                        end: p2.location,
                                        startConfidence: p1.confidence,
                                        endConfidence: p2.confidence
                                    )
                                )
                            }
                        }
                    } catch {
                        print("⚠️ Error reading points:", error)
                    }
                }

                self.exportOverlayLayer = self.makeExportOverlayLayer(videoSize: exportSize)
                print("🎨 [EXPORT] overlay frame:", self.exportOverlayLayer.frame)

                var renderedPixel: CVPixelBuffer? = nil
                CVPixelBufferCreate(
                    nil,
                    Int(exportSize.width),
                    Int(exportSize.height),
                    kCVPixelFormatType_32BGRA,
                    nil,
                    &renderedPixel
                )

                guard let rendered = renderedPixel else {
                    print("❌ Failed to create output pixel buffer")
                    continue
                }

                CVPixelBufferLockBaseAddress(rendered, [])

                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue |
                                 CGImageAlphaInfo.premultipliedFirst.rawValue

                guard let ctx = CGContext(
                    data: CVPixelBufferGetBaseAddress(rendered),
                    width: Int(exportSize.width),
                    height: Int(exportSize.height),
                    bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(rendered),
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                ) else {
                    print("⚠️ Failed to create CGContext")
                    CVPixelBufferUnlockBaseAddress(rendered, [])
                    continue
                }

                ctx.saveGState()
                ctx.concatenate(transform)

                let drawRect = isPortrait
                    ? CGRect(origin: .zero,
                             size: CGSize(width: exportSize.height,
                                          height: exportSize.width))
                    : CGRect(origin: .zero, size: exportSize)

                print("🖍 [EXPORT] drawRect:", drawRect)

                let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
                if let cg = cgImage {
                    ctx.draw(cg, in: drawRect)
                }

                ctx.restoreGState()

                print("🎨 [EXPORT] Rendering overlay… frame:", self.exportOverlayLayer.frame)
                self.exportOverlayLayer.render(in: ctx)

                CVPixelBufferUnlockBaseAddress(rendered, [])

                let time = CMTime(value: frameCount, timescale: Int32(fps))
                adaptor.append(rendered, withPresentationTime: time)

                frameCount += 1
            }
        }
    }




    

    func exportCurrentVideo(completion: @escaping (URL?) -> Void) {
        print("🎥 exportCurrentVideo - START")
        
        guard let player = VideoCoachRenderView?.player else {
            print("❌ No player available")
            completion(nil)
            return
        }
        
        print("🎥 Player found")
        
        guard let item = player.currentItem else {
            print("❌ No player item available")
            completion(nil)
            return
        }
        
        print("🎥 Player item found")
        
        guard let urlAsset = item.asset as? AVURLAsset else {
            print("❌ Asset is not AVURLAsset")
            completion(nil)
            return
        }
        
        print("🎥 AVURLAsset found - URL: \(urlAsset.url)")

        exportVideoWithOverlay(originalURL: urlAsset.url, completion: completion)
    }


    
    
}



// MARK: - Coordinates conversion
protocol NormalizedGeometryConverting {
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect
    func viewPointConverted(fromNormalizedContentsPoint normalizedPoint: CGPoint) -> CGPoint
}

// MARK: - View to display live camera feed
class CameraFeedView: UIView, NormalizedGeometryConverting {
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    init(frame: CGRect, session: AVCaptureSession, videoOrientation: AVCaptureVideoOrientation) {
        super.init(frame: frame)
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspect
        previewLayer.connection?.videoOrientation = videoOrientation
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect {
        return previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect)
    }
    
    func viewPointConverted(fromNormalizedContentsPoint normalizedPoint: CGPoint) -> CGPoint {
        return previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
    }
}

// MARK: - View for rendering video file contents
class VideoCoachRenderView: UIView, NormalizedGeometryConverting {
    var renderLayer: AVPlayerLayer!
    var minSeekTime: Double = 0.033
    var safeTime = 0.0
    
    func pausePlayback() {
        player?.pause()
    }
    
    func stepBackFrames(multiplier: Int32) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let frameDuration = CMTime(value: 1, timescale: 30)

        let targetTime = CMTimeSubtract(currentTime, CMTimeMultiply(frameDuration, multiplier: multiplier))

        let computed = max(targetTime.seconds, self.minSeekTime)
        self.safeTime = computed     // <-- Store it here

        let seekTime = CMTime(seconds: computed, preferredTimescale: 600)

        player.seek(
            to: seekTime,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    
    
    
    var player: AVPlayer? {
        get {
            return renderLayer.player
        }
        set {
            renderLayer.player = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        renderLayer = layer as? AVPlayerLayer
        renderLayer.videoGravity = .resizeAspect
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect {
        let videoRect = renderLayer.videoRect
        let origin = CGPoint(x: videoRect.origin.x + normalizedRect.origin.x * videoRect.width,
                             y: videoRect.origin.y + normalizedRect.origin.y * videoRect.height)
        let size = CGSize(width: normalizedRect.width * videoRect.width,
                          height: normalizedRect.height * videoRect.height)
        let convertedRect = CGRect(origin: origin, size: size)
        return convertedRect.integral
    }
    
    func viewPointConverted(fromNormalizedContentsPoint normalizedPoint: CGPoint) -> CGPoint {
        let videoRect = renderLayer.videoRect

        print("🔍 [Conversion] incoming normalized:", normalizedPoint)
        print("🔍 [Conversion] videoRect:", videoRect)

        let flippedY = 1.0 - normalizedPoint.y
        let convertedPoint = CGPoint(
            x: videoRect.origin.x + normalizedPoint.x * videoRect.width,
            y: videoRect.origin.y + flippedY * videoRect.height
        )

        print("🔍 [Conversion] converted:", convertedPoint)

        return convertedPoint
    }

}

