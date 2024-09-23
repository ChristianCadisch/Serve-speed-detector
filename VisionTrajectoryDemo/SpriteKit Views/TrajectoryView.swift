/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A scene that displays a trajectory.
*/

import UIKit
import SpriteKit
import Vision

class TrajectoryView: SKView, AnimatedTransitioning {
    
    // MARK: - Public Properties
    var glowingBallScene: BallScene?
    var outOfROIPoints = 0
    var duration = 0.0
    var speed = 0.0
    var points: [VNPoint] = [] {
        didSet {
            updatePathLayer()
        }
    }
    
    // MARK: - Private Properties
    private let pathLayer = CAShapeLayer()
    private let shadowLayer = CAShapeLayer()
    private let gradientMask = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Life Cycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        allowsTransparency = true
        backgroundColor = UIColor.clear
        setupLayer()
        glowingBallScene = BallScene(size: CGSize(width: frame.size.width, height: frame.size.height))
        presentScene(glowingBallScene!)
    }

    // MARK: - Public Methods
    
    func resetPath() {
        let trajectory = UIBezierPath()
        pathLayer.path = trajectory.cgPath
        shadowLayer.path = trajectory.cgPath
        glowingBallScene?.removeAllChildren()
    }

    // MARK: - Private Methods
    
    private func setupLayer() {
        shadowLayer.lineWidth = 6.0
        shadowLayer.lineCap = .round
        shadowLayer.fillColor = UIColor.clear.cgColor
        shadowLayer.strokeColor = #colorLiteral(red: 0.9882352941, green: 0.4666666667, blue: 0, alpha: 0.4519210188).cgColor
        layer.addSublayer(shadowLayer)
        pathLayer.lineWidth = 2.0
        pathLayer.lineCap = .round
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.strokeColor = #colorLiteral(red: 0.9960784314, green: 0.737254902, blue: 0, alpha: 0.7512574914).cgColor
        layer.addSublayer(pathLayer)
    }
    
    private func updatePathLayer() {
        let trajectory = UIBezierPath()
        guard let startingPoint = points.first else {
            return
        }
        trajectory.move(to: startingPoint.location)
        for point in points.dropFirst() {
            trajectory.addLine(to: point.location)
        }
        
        // Scale the trajectory.
        let flipVertical = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        trajectory.apply(flipVertical)
        trajectory.apply(CGAffineTransform(scaleX: bounds.width, y: bounds.height))
        trajectory.lineWidth = 12
        
        // Assign the trajectory to the user interface layers.
        shadowLayer.path = trajectory.cgPath
        pathLayer.path = trajectory.cgPath
        gradientMask.path = trajectory.cgPath
        gradientLayer.mask = gradientMask
        
        // Scale up a normalized scene.
        if glowingBallScene!.size.width <= 1.0 || glowingBallScene!.size.height <= 1.0 {
            glowingBallScene = BallScene(size: CGSize(width: frame.size.width, height: frame.size.height))
            presentScene(glowingBallScene!)
        }
        
        // Scale up the trajectory points.
        var scaledPoints: [CGPoint] = []
        for point in points {
            scaledPoints.append(point.location.applying(CGAffineTransform(scaleX: frame.size.width, y: frame.size.height)))
        }
                
        // Animate the ball across the scene.
        if scaledPoints.last != nil {
            glowingBallScene!.flyBall(points: scaledPoints)
        }
        
        // Automatically reset the path after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.resetPath()
            }
    }
    
}




class DashboardView: UIView, AnimatedTransitioning {
    
    var speed = 0.0 {
        didSet {
            updatePathLayer()
        }
    }
    private var maxSpeed = 30.0
    private var halfWidth: CGFloat = 0
    private var startAngle = CGFloat.pi * 5 / 6
    private var maxAngle = CGFloat.pi * 4 / 3
    private var pathLayer = CAShapeLayer()
    private var speedLayer = CAShapeLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    func animateSpeedChart() {
        let progressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        progressAnimation.duration = 1
        progressAnimation.fromValue = 0
        progressAnimation.toValue = 1
        progressAnimation.fillMode = .forwards
        progressAnimation.isRemovedOnCompletion = false
        speedLayer.add(progressAnimation, forKey: "animateSpeedChart")
    }

    private func initialSetup() {
        isOpaque = false
        backgroundColor = .clear
        halfWidth = bounds.width / 2
        let endAngle = CGFloat.pi / 6
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: halfWidth, y: halfWidth), radius: bounds.width / 2,
                                      startAngle: startAngle, endAngle: endAngle, clockwise: true)
        pathLayer.path = circlePath.cgPath
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.strokeColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4499411387).cgColor
        pathLayer.lineCap = .round
        pathLayer.lineWidth = 22
        layer.addSublayer(pathLayer)
    }

    private func updatePathLayer() {
        let endAngle = startAngle + maxAngle * CGFloat(speed / maxSpeed)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: halfWidth, y: halfWidth), radius: bounds.width / 2,
                                      startAngle: startAngle, endAngle: endAngle, clockwise: true)
        speedLayer.path = circlePath.cgPath
        speedLayer.fillColor = UIColor.clear.cgColor
        speedLayer.strokeColor = #colorLiteral(red: 0.6078431373, green: 0.9882352941, blue: 0, alpha: 0.7539934132).cgColor
        speedLayer.lineCap = .round
        speedLayer.lineWidth = 22
        speedLayer.strokeEnd = 1.0
        layer.addSublayer(speedLayer)
    }
}
