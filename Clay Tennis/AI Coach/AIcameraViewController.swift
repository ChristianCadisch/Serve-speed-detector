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
    
    private var lineLayer: CAShapeLayer?  // Store a reference to the line layer
    private var overlayView: UIView!
    
    private var jointMarkerSize: CGFloat = 0.5
    private var jointLineWidth: CGFloat = 1.0
    
    private var currentZoomScale: CGFloat = 1.0
    
    private var videoFrameRate: Float = 0.0
    private var timeObserverToken: Any?
    private var progressLink: CADisplayLink?

    
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
        overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = .clear // Ensure it's transparent
        view.addSubview(overlayView)
        
        setupLayers()
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
        
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
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let viewToZoom = gesture.view else { return }
        
        if gesture.state == .began || gesture.state == .changed {
            viewToZoom.transform = viewToZoom.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
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
        VideoCoachRenderView.frame = self.view.bounds
        overlayView.frame = VideoCoachRenderView.bounds  // Ensures overlay covers the video completely
        jointLayer.frame = overlayView.bounds
        jointSegmentLayer.frame = overlayView.bounds
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

        let flip = CGAffineTransform(scaleX: 1, y: -1)
        jointSegmentLayer.setAffineTransform(flip)
        jointLayer.setAffineTransform(flip)

        jointSegmentLayer.frame = overlayView.bounds
        jointLayer.frame = overlayView.bounds

        overlayView.layer.addSublayer(jointLayer)
        overlayView.layer.addSublayer(jointSegmentLayer)
        overlayView.layer.zPosition = 2000
    }

    
    func setupVideoOutputView(_ videoOutputView: UIView) {
        videoOutputView.translatesAutoresizingMaskIntoConstraints = false
        //videoOutputView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        view.addSubview(videoOutputView)
    }
    
    
    
    func pauseVideoPlayback(multiplier: Int32) {
        VideoCoachRenderView?.pausePlayback()
        displayLink?.invalidate()
        displayLink = nil
        VideoCoachRenderView?.stepBackFrames(multiplier: multiplier)
    }
    func resumeVideoPlayback() {
        VideoCoachRenderView?.stepBackFrames(multiplier: -4)
        VideoCoachRenderView?.player?.play()
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
            
            self.jointPath.removeAllPoints()
            self.jointSegmentPath.removeAllPoints()
            
            for observation in observations {
                do {
                    let recognizedPoints = try observation.recognizedPoints(.all)
                    let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                        (.rightShoulder, .rightElbow),
                        (.rightElbow, .rightWrist),
                        (.rightShoulder, .rightHip),
                        (.rightHip, .rightKnee),
                        (.rightKnee, .rightAnkle)
                    ]
                    
                    for (startJoint, endJoint) in connections {
                        guard let startPoint = recognizedPoints[startJoint]?.location,
                              let endPoint = recognizedPoints[endJoint]?.location,
                              recognizedPoints[startJoint]!.confidence > 0.1,
                              recognizedPoints[endJoint]!.confidence > 0.1 else {
                            continue
                        }
                        let scaledSize = CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height)
                        self.updatePathForJoint(startPoint: startPoint, endPoint: endPoint, scale: scaledSize)
                    }
                    
                    // Check if a hit is detected
                    
                    
                    let verbose = true
                    if self.gameManager.stateMachine.currentState is GameManager.TryDetectingServe {
                        let (serveDetected, framesPrior) = self.aiCoach.detectServe(from: recognizedPoints, verbose: verbose)
                        if serveDetected {
                            self.pauseVideoPlayback(multiplier: framesPrior)
                            self.gameManager.stateMachine.enter(GameManager.TryDetectingTrophyPose.self)
                        }
                    } else {
                        // Check if a trophyPose is detected
                        let (trophyPoseDetected, framesPrior) = self.aiCoach.detectTrophyPose(from: recognizedPoints, verbose: verbose)
                        if trophyPoseDetected {
                            self.pauseVideoPlayback(multiplier: framesPrior / 2)
                            self.gameManager.stateMachine.enter(GameManager.TryDetectingServe.self)
                        }
                        
                    }
                    
                } catch {
                    print("Error processing body pose observation: \(error)")
                }
            }
            
            self.jointLayer.path = self.jointPath.cgPath
            self.jointSegmentLayer.path = self.jointSegmentPath.cgPath
        }
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
        // Stop capture session if it's running
        // Invalidate display link so it's removed from run loop
        displayLink?.invalidate()
    }
    
    
    func setupWithVideoURL(_ url: URL) {
        let asset = AVAsset(url: url)
        startReadingAsset(asset)
        
        // Get the frame rate of the video
        videoFrameRate = getVideoFrameRate(asset: asset)
        print("Video Frame Rate: \(videoFrameRate) FPS")
    }
    
    private func getVideoFrameRate(asset: AVAsset) -> Float {
        guard let track = asset.tracks(withMediaType: .video).first else {
            print("No video tracks found in AVAsset.")
            return 0.0
        }
        return track.nominalFrameRate
    }
    
    
    
    func startReadingAsset(_ asset: AVAsset) {

        // FIX: remove previous video view
        VideoCoachRenderView?.player?.pause()
        VideoCoachRenderView?.removeFromSuperview()
        VideoCoachRenderView = nil

        // Now create a single one
        VideoCoachRenderView = Clay_Tennis.VideoCoachRenderView(frame: view.bounds)
        setupVideoOutputView(VideoCoachRenderView)

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
        print("minSeekTime =", self.VideoCoachRenderView.minSeekTime)


        
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
    private var renderLayer: AVPlayerLayer!
    var minSeekTime: Double = 0.033
    
    func pausePlayback() {
        player?.pause()
    }
    
    func stepBackFrames(multiplier: Int32) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let frameDuration = CMTime(value: 1, timescale: 30)

        let targetTime = CMTimeSubtract(currentTime, CMTimeMultiply(frameDuration, multiplier: multiplier))

        let safeTime = max(targetTime.seconds, self.minSeekTime)
        print("Seeking to:", safeTime)

        player.seek(
            to: CMTime(seconds: safeTime, preferredTimescale: 600),
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
        let convertedPoint = CGPoint(x: videoRect.origin.x + normalizedPoint.x * videoRect.width,
                                     y: videoRect.origin.y + normalizedPoint.y * videoRect.height)
        return convertedPoint
    }
}

