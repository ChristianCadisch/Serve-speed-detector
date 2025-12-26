/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The app's view controller that handles the trajectory analysis.
 */

import UIKit
import AVFoundation
import Vision

protocol ContentAnalysisViewControllerDelegate: AnyObject {
    func contentAnalysisViewControllerDidFinish(
        _ controller: ContentAnalysisViewController,
        serveCount: Int
    )
}


class ContentAnalysisViewController: UIViewController,
                                     AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Static Properties
    static let segueDestinationId = "ShowAnalysisView"
    
    // MARK: - IBOutlets
    private var serveSpeedLabel: UILabel!
    var detectedServeCount: Int = 0
    var speedContainerView: UIVisualEffectView!
    private var motionWarningView: UIView?
    
    
    
    // MARK: - IBActions
    @IBAction func closeRootViewTapped(_ sender: Any) {
        print("close tapped")
        navigationController?.popViewController(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.delegate?.contentAnalysisViewControllerDidFinish(
                self,
                serveCount: self.detectedServeCount
            )

        }
    }
    
    
    // MARK: - Public Properties
    weak var delegate: ContentAnalysisViewControllerDelegate?
    
    // MARK: - Public Properties
    var recordedVideoSource: AVAsset?
    
    // MARK: - Private Properties
    private var cameraViewController: CameraViewController!
    private var trajectoryView = TrajectoryView()
    private var setupComplete = false
    private var detectTrajectoryRequest: VNDetectTrajectoriesRequest!
    
    private var framesWithoutUpdate = 0
    private var lastObservedTrajectory: VNTrajectoryObservation?
    private let updateThreshold = 8 // Number of frames to wait before considering trajectory complete
    
    // A dictionary that stores all trajectories.
    private var trajectoryDictionary: [String: [VNPoint]] = [:]
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetFastestSpeedForCurrentVideo()
        resetServeCountForCurrentVideo()
        configureView()
        setupButtonsAndLabels()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    
    private func resetFastestSpeedForCurrentVideo() {
        guard let videoAsset = recordedVideoSource,
              let urlString = (videoAsset as? AVURLAsset)?.url.absoluteString else { return }
        
        let key = "FastestSpeed_\(urlString)"
        
        UserDefaults.standard.set(0, forKey: key)
        print("Reset fastest speed for this video.")
    }
    
    private func resetServeCountForCurrentVideo() {
        guard let videoAsset = recordedVideoSource,
              let urlString = (videoAsset as? AVURLAsset)?.url.absoluteString else { return }
        
        let key = "ServeCount_\(urlString)"
        
        UserDefaults.standard.set(0, forKey: key)
        print("Reset serve count for this video.")
    }
    
    
    private func saveFastestSpeed(_ speed: Double) {
        guard let videoAsset = recordedVideoSource else {
            print("saveFastestSpeed: No video asset available")
            return
        }
        guard let urlString = (videoAsset as? AVURLAsset)?.url.absoluteString else {
            print("saveFastestSpeed: Unable to get URL string")
            return
        }
        let key = "FastestSpeed_\(urlString)"
        DispatchQueue.main.async {
            let currentFastestSpeed = UserDefaults.standard.double(forKey: key)
            print("Current fastest speed : \(currentFastestSpeed)")
            if speed > currentFastestSpeed {
                print("New fastest speed : \(speed)")
                UserDefaults.standard.set(speed, forKey: key)

                print("Posted fastestSpeedUpdated notification")
            }
        }
    }
    
    private func checkForTrajectoryCompletion() {

        if framesWithoutUpdate >= updateThreshold,
           let lastTrajectory = lastObservedTrajectory {

            var speed = round(Double(3.6 * 18) / lastTrajectory.timeRange.duration.seconds)
            print("New speed detected: \(speed)")

            if speed > 200 {
                speed = 0
                print("speed wrongly measured, reset to 0")
                DispatchQueue.main.async { [weak self] in
                    self?.showMotionWarning(errormessage: "Speed measurement failed")
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    // ─────────────────────────────
                    // VISUAL UPDATE (unchanged logic)
                    // ─────────────────────────────
                    self.trajectoryView.speed = speed
                    self.trajectoryView.numberOfServes += 1
                    self.detectedServeCount = self.trajectoryView.numberOfServes

                    let attributed = NSMutableAttributedString(
                        string: String(format: "%.0f", speed),
                        attributes: [.font: UIFont.systemFont(ofSize: 48, weight: .bold)]
                    )

                    attributed.append(NSAttributedString(
                        string: "\nkm/h",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                            .foregroundColor: UIColor.white.withAlphaComponent(0.75)
                        ]
                    ))

                    self.serveSpeedLabel.attributedText = attributed

                    // ─────────────────────────────
                    // 🔥 CRITICAL FIX: persistence
                    // ─────────────────────────────
                    self.saveFastestSpeed(speed)

                    // also persist serve count (feed relies on this too)
                    if let asset = self.recordedVideoSource,
                       let urlString = (asset as? AVURLAsset)?.url.absoluteString {
                        UserDefaults.standard.set(
                            self.detectedServeCount,
                            forKey: "ServeCount_\(urlString)"
                        )
                    }



                    UIView.animate(withDuration: 0.15, animations: {
                        self.speedContainerView.transform =
                            CGAffineTransform(scaleX: 1.05, y: 1.05)
                    }) { _ in
                        UIView.animate(withDuration: 0.2) {
                            self.speedContainerView.transform = .identity
                        }
                    }
                }
            }

            lastObservedTrajectory = nil
            framesWithoutUpdate = 0
        }
    }

    
    
    
    private func setupButtonsAndLabels() {

        // --- Container (HUD style) ---
        speedContainerView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        speedContainerView.layer.cornerRadius = 22
        speedContainerView.clipsToBounds = true

        view.addSubview(speedContainerView)
        speedContainerView.translatesAutoresizingMaskIntoConstraints = false

        let cardWidth: CGFloat = 180
        let cardHeight: CGFloat = 140

        NSLayoutConstraint.activate([
            speedContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speedContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            speedContainerView.widthAnchor.constraint(equalToConstant: cardWidth),
            speedContainerView.heightAnchor.constraint(equalToConstant: cardHeight)
        ])

        // --- Speed Label ---
        serveSpeedLabel = UILabel()
        serveSpeedLabel.textAlignment = .center
        serveSpeedLabel.textColor = .white
        serveSpeedLabel.numberOfLines = 2

        let attributed = NSMutableAttributedString(
            string: "0",
            attributes: [.font: UIFont.systemFont(ofSize: 48, weight: .bold)]
        )

        attributed.append(NSAttributedString(
            string: "\nkm/h",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.75)
            ]
        ))

        serveSpeedLabel.attributedText = attributed

        // --- Title ---
        let titleLabel = UILabel()
        titleLabel.text = "Serve Speed"
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, serveSpeedLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2

        speedContainerView.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: speedContainerView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: speedContainerView.centerYAnchor)
        ])


    }

    

    
    @objc private func backButtonTapped() {
        print("back tapped")
        navigationController?.popViewController(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.delegate?.contentAnalysisViewControllerDidFinish(
                self,
                serveCount: self.detectedServeCount
            )

            
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        recordedVideoSource = nil
        detectTrajectoryRequest = nil
    }
    
    // MARK: - Public Methods
    
    // The sample app calls this when the camera view delegate begins reading
    // frames of a video buffer.
    func setUpDetectTrajectoriesRequestWithMaxDimension() {
        
        guard setupComplete == false else {
            return
        }
        
        /**
         Define what the sample app looks for, and how to handle the output trajectories.
         Setting the frame time spacing to (10, 600) so the framework looks for trajectories after each 1/60 second of video.
         Setting the trajectory length to 6 so the framework returns trajectories of a length of 6 or greater.
         Use a shorter length for real-time apps, and use longer lengths to observe finer and longer curves.
         */
        detectTrajectoryRequest = VNDetectTrajectoriesRequest(frameAnalysisSpacing: CMTime(value: 10, timescale: 600),
                                                              trajectoryLength: 5) { [weak self] (request: VNRequest, error: Error?) -> Void in
            
            guard let results = request.results as? [VNTrajectoryObservation] else {
                return
            }
            
            DispatchQueue.main.async {
                self?.processTrajectoryObservation(results: results)
            }
            
        }
        setupComplete = true
        
    }
    
    // MARK: - Private Methods
    
    @objc private func openRecordingSetup() {
        let vc = UIHostingController(rootView: SpeedRecordingSetupView(isPresented: .constant(true)
        ))
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    private func showMotionWarning(errormessage: String) {
        guard motionWarningView == nil else { return }
        
        let card = UIView()
        card.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.95)
        card.layer.cornerRadius = 20
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.15
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(openRecordingSetup))
        card.addGestureRecognizer(tap)
        
        let icon = UIImageView()
        icon.image = UIImage(systemName: "video.slash")
        icon.tintColor = .systemRed
        icon.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = errormessage
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap to see how to set up your camera"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            icon.heightAnchor.constraint(equalToConstant: 60),
            icon.widthAnchor.constraint(equalToConstant: 60),
            
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
        
        view.addSubview(card)
        motionWarningView = card
        
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.widthAnchor.constraint(equalToConstant: 300),
            card.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    
    
    
    
    private func hideMotionWarning() {
        motionWarningView?.removeFromSuperview()
        motionWarningView = nil
    }
    
    
    
    
    private func processTrajectoryObservation(results: [VNTrajectoryObservation]) {
        guard !results.isEmpty else {
            framesWithoutUpdate += 1
            checkForTrajectoryCompletion()
            return
        }
        
        for trajectory in results {
            if filterParabola(trajectory: trajectory) {
                framesWithoutUpdate = 0
                lastObservedTrajectory = trajectory
                trajectoryView.points = correctTrajectoryPath(trajectoryToCorrect: trajectory)
                trajectoryView.performTransition(.fadeIn, duration: 0.05)
                
                // Don't update speed here, just update the view
                trajectoryView.speed = 0
                //serveSpeedLabel.text = "Measuring..."
            }
        }
    }
    
    
    
    
    
    
    private func filterParabola(trajectory: VNTrajectoryObservation) -> Bool {
        
        if trajectoryDictionary[trajectory.uuid.uuidString] == nil {
            // Add the new trajectories to the dictionary.
            trajectoryDictionary[trajectory.uuid.uuidString] = trajectory.projectedPoints
        } else {
            // Increase the points on the existing trajectory.
            // The framework returns the last five projected points, so check whether a trajectory is
            // increasing, and update it.
            if trajectoryDictionary[trajectory.uuid.uuidString]!.last != trajectory.projectedPoints[4] {
                trajectoryDictionary[trajectory.uuid.uuidString]!.append(trajectory.projectedPoints[4])
            }
        }
        
        /**
         Filter the trajectory with the following conditions:
         - The trajectory moves from left to right.
         - The trajectory starts in the first half of the region of interest.
         - The trajectory ens in the right half of the region of interest.
         - The trajectory length increases to 8.
         - The trajectory contains a parabolic equation constant a, less than or equal to 0, and implies there
         are either straight lines or downward-facing lines.
         - The trajectory confidence is greater than 0.9.
         
         Add additional filters based on trajectory speed, location, and properties.
         */
        if trajectoryDictionary[trajectory.uuid.uuidString]!.first!.x < trajectoryDictionary[trajectory.uuid.uuidString]!.last!.x //left to right
            && trajectoryDictionary[trajectory.uuid.uuidString]!.first!.x < 0.6
            && trajectoryDictionary[trajectory.uuid.uuidString]!.last!.x > 0.4
            && trajectoryDictionary[trajectory.uuid.uuidString]!.first!.y - 0.1 >  trajectoryDictionary[trajectory.uuid.uuidString]!.last!.y //high y to low y
            && trajectoryDictionary[trajectory.uuid.uuidString]!.count >= 8
            && trajectory.equationCoefficients[0] <= 0
            && trajectory.confidence > 0.6 {
            return true
        } else {
            return false
        }
        
    }
    
    private func correctTrajectoryPath(trajectoryToCorrect: VNTrajectoryObservation) -> [VNPoint] {
        
        guard var basePoints = trajectoryDictionary[trajectoryToCorrect.uuid.uuidString],
              var basePointX = basePoints.first?.x else {
            return []
        }
        
        /**
         This is inside region-of-interest space where both x and y range between 0.0 and 1.0.
         If a left-to-right moving trajectory begins too far from a fixed region, extrapolate it back
         to that region using the available quadratic equation coefficients.
         */
        if basePointX > 0.1 {
            
            // Compute the initial trajectory location points based on the average
            // change in the x direction of the first five points.
            var sum = 0.0
            for i in 0..<5 {
                sum = sum + basePoints[i + 1].x - basePoints[i].x
            }
            let averageDifferenceInX = sum / 5.0
            
            while basePointX > 0.1 {
                let nextXValue = basePointX - averageDifferenceInX
                let aXX = Double(trajectoryToCorrect.equationCoefficients[0]) * nextXValue * nextXValue
                let bX = Double(trajectoryToCorrect.equationCoefficients[1]) * nextXValue
                let c = Double(trajectoryToCorrect.equationCoefficients[2])
                
                let nextYValue = aXX + bX + c
                if nextYValue > 0 {
                    // Insert values into the trajectory path present in the positive Cartesian space.
                    basePoints.insert(VNPoint(x: nextXValue, y: nextYValue), at: 0)
                }
                basePointX = nextXValue
            }
            // Update the dictionary with the corrected path.
            trajectoryDictionary[trajectoryToCorrect.uuid.uuidString] = basePoints
            
        }
        return basePoints
        
    }
    
    private func configureView() {
        
        // Set up the video layers.
        cameraViewController = CameraViewController()
        cameraViewController.view.frame = view.bounds
        addChild(cameraViewController)
        cameraViewController.beginAppearanceTransition(true, animated: true)
        view.addSubview(cameraViewController.view)
        cameraViewController.endAppearanceTransition()
        cameraViewController.didMove(toParent: self)
        
        do {
            if recordedVideoSource != nil {
                // Start reading the video.
                cameraViewController.startReadingAsset(recordedVideoSource!)
            } else {
                // Start live camera capture.
                //try cameraViewController.setupAVSession()
            }
        } catch {
            AppError.display(error, inViewController: self)
        }
        
        cameraViewController.outputDelegate = self
        
        // Add a custom trajectory view for overlaying trajectories.
        view.addSubview(trajectoryView)
    }
}

extension ContentAnalysisViewController: CameraViewControllerOutputDelegate {
    
    func cameraViewController(_ controller: CameraViewController,
                              didReceiveBuffer buffer: CMSampleBuffer,
                              orientation: CGImagePropertyOrientation) {
        
        let visionHandler = VNImageRequestHandler(cmSampleBuffer: buffer,
                                                  orientation: orientation,
                                                  options: [:])
        
        let normalizedFrame = CGRect(x: 0.25, y: 0.4, width: 0.65, height: 0.5)
        DispatchQueue.main.async {
            // Get the frame of the rendered view.
            self.trajectoryView.frame = controller.viewRectForVisionRect(normalizedFrame)
        }
        
        setUpDetectTrajectoriesRequestWithMaxDimension()
        
        guard let detectTrajectoryRequest = detectTrajectoryRequest else {
            print("Failed to retrieve a trajectory request.")
            return
        }
        
        do {
            // Following optional bounds by checking for the moving average radius
            // of the trajectories the app is looking for.
            detectTrajectoryRequest.objectMinimumNormalizedRadius = 10.0 / Float(1920.0)
            detectTrajectoryRequest.objectMaximumNormalizedRadius = 30.0 / Float(1920.0)
            
            
            // Help manage the real-time use case to improve the precision versus delay tradeoff.
            detectTrajectoryRequest.targetFrameTime = CMTimeMake(value: 1, timescale: 20)
            
            // The region of interest where the object is moving in the normalized image space.
            detectTrajectoryRequest.regionOfInterest = normalizedFrame
            
            
            try visionHandler.perform([detectTrajectoryRequest])
            checkForTrajectoryCompletion()
        }  catch {
            let message = error.localizedDescription.lowercased()
            if message.contains("too many moving objects") || message.contains("noise detected") {
                DispatchQueue.main.async { [weak self] in
                    self?.showMotionWarning(errormessage: "Recording too unstable")
                }
            }
            return
        }
    }
    
}




import SwiftUI

struct ContentAnalysisPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ContentAnalysisViewController {
        let vc = ContentAnalysisViewController()
        // Optionally set properties on vc
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ContentAnalysisViewController, context: Context) {}
}

#Preview {
    ContentAnalysisPreview()
}
