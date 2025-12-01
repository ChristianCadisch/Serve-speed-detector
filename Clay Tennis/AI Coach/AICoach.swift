import Vision

class AICoach {
    
    let detectionThreshold: Int32 = 4

    var rightElbowOverShoulder = false
    var leftElbowOverShoulder = false
    var prevYDifference: CGFloat = 0.0

    var elbowOverShoulderCount = 0
    var wristHeightDecreasingCount = 0
    var framesSinceWristOverShoulder = 0

    private var yDifferenceDerivative = 1.0

    var feedbackHandler: ((String, String) -> Void)?

    func detectServe(from joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint], verbose: Bool = false) -> (Bool, Int32) {
        guard let rightWristJoint = joints[.rightWrist],
              let rightShoulderJoint = joints[.rightShoulder],
              let rightElbowJoint = joints[.rightElbow] else {
            return (false, 0)
        }
        if rightWristJoint.location.y == 1.0 {
            print("Failed to detect right wrist")
            return (false, 0)
        }
        
        let yDifference = rightShoulderJoint.location.y - rightWristJoint.location.y
        
        if rightElbowOverShoulder == false && rightShoulderJoint.location.y - rightElbowJoint.location.y < -0.04 {
            rightElbowOverShoulder = true
            framesSinceWristOverShoulder = 0
        }
        
        if rightShoulderJoint.location.y - rightElbowJoint.location.y < 0 {
            elbowOverShoulderCount += 1
        } else {
            elbowOverShoulderCount = max(elbowOverShoulderCount - 1, 0)
        }
        
        rightElbowOverShoulder = elbowOverShoulderCount > detectionThreshold
        
        if rightElbowOverShoulder {
            framesSinceWristOverShoulder += 1
            
            if yDifference > prevYDifference {
                wristHeightDecreasingCount += 1
            } else {
                wristHeightDecreasingCount = 0
            }
            
            if wristHeightDecreasingCount >= detectionThreshold {
                print("Serve detected after \(framesSinceWristOverShoulder) frames since wrist was over shoulder")
                provideFeedback(for: convertJointsToCGPoint(joints), pose: "Hit behind")
                rightElbowOverShoulder = false
                wristHeightDecreasingCount = 0
                elbowOverShoulderCount = 0
                return (true, detectionThreshold)
            }
        }
        
        if verbose { print("Detecting Serve. Right Wrist high? ", rightElbowOverShoulder, "Decreasing?", wristHeightDecreasingCount) }
        
        prevYDifference = yDifference
        return (false, 0)
    }

    
    func detectTrophyPose(from joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint], verbose: Bool = false) -> (Bool, Int32) {
        guard let leftWristJoint = joints[.leftWrist],
              let leftShoulderJoint = joints[.leftShoulder], let leftElbowJoint = joints[.leftElbow] else {
            return (false, 0)
        }
        if leftWristJoint.location.y == 1.0 {
            print("Failed to detect left wrist")
            return (false, 0)
        }
        
        let yDifference = leftShoulderJoint.location.y - leftWristJoint.location.y
        
        
        
        
        if leftElbowOverShoulder == false && leftShoulderJoint.location.y - leftElbowJoint.location.y < -0.04 {
            leftElbowOverShoulder = true
        }
        
        if leftShoulderJoint.location.y - leftElbowJoint.location.y < 0 {
            elbowOverShoulderCount += 1
        } else {
            elbowOverShoulderCount = max(elbowOverShoulderCount - 1, 0)
        }
        
        leftElbowOverShoulder = elbowOverShoulderCount > detectionThreshold
        
        
        
        if leftElbowOverShoulder {
            if yDifference > prevYDifference {
                wristHeightDecreasingCount += 1
            } else {
                wristHeightDecreasingCount = 0
            }
            
            if wristHeightDecreasingCount >= detectionThreshold {
                print("Trophy detected")
                provideFeedback(for: convertJointsToCGPoint(joints), pose: "Trophy behind")
                leftElbowOverShoulder = false
                wristHeightDecreasingCount = 0
                elbowOverShoulderCount = 0
                return (true, detectionThreshold)
            }
        }
        
        if verbose {print("Detecting Trophy. Left Wrist high? ", leftElbowOverShoulder, "Decreasing?", wristHeightDecreasingCount)}
        
        prevYDifference = yDifference
        return (false, 0)
    }
    
    
    
    
    // Function to provide feedback based on joint positions
    func provideFeedback(for joints: [VNHumanBodyPoseObservation.JointName: CGPoint], pose: String) {
        var feedbackArray = [String]()
        var feedbackArrayDetailed = [String]()
        
        if pose == "Trophy behind" {
            feedbackArray.append("Good job on the Trophy Pose! Let's break it down:")
            feedbackArrayDetailed.append("Your Trophy Pose is a crucial element in your serve. Analyzing it can help improve your power and stability.")
            
            // Calculate knee angles
            guard let leftKneeAngle = calculateAngle(from: joints, joint1: .leftHip, joint2: .leftKnee, joint3: .leftAnkle),
                  let rightKneeAngle = calculateAngle(from: joints, joint1: .rightHip, joint2: .rightKnee, joint3: .rightAnkle) else {
                feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
                return
            }
            
            let averageKneeAngle = (180 - leftKneeAngle + 180 - rightKneeAngle) / 2
            let federerAverageAngle = 75.0
            
            // Feedback on knee angles
            if averageKneeAngle < federerAverageAngle {
                feedbackArray.append("Your knees are bent \(federerAverageAngle - averageKneeAngle)° less than Roger Federer's. This may reduce the power of your serve.")
                feedbackArrayDetailed.append("Having less knee bend can impact the explosiveness of your serve. Try bending your knees more to generate more power.")
            } else {
                feedbackArray.append("Your knee bending is on par with Roger Federer's, which is excellent for power generation.")
                feedbackArrayDetailed.append("Maintaining this level of knee bend helps you to utilize your lower body strength effectively.")
            }
            
            // Calculate foot placement
            guard let leftAnkle = joints[.leftAnkle], let rightAnkle = joints[.rightAnkle] else {
                feedbackArray.append("Could not determine ankle positions.")
                feedbackArrayDetailed.append("Without accurate ankle positions, it's challenging to assess your stance properly.")
                feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
                return
            }
            
            let playerStanceDistance = abs(leftAnkle.x - rightAnkle.x)
            let federerStanceDistance = 112.0  // The reference distance for Federer's stance width
            
            // Feedback on foot placement
            if playerStanceDistance / federerStanceDistance < 0.9 {
                feedbackArray.append("Your feet are closer together compared to Roger Federer, which could affect your stability.")
                feedbackArrayDetailed.append("Wider foot placement can enhance stability and balance, helping you maintain a strong base during your serve.")
            } else {
                feedbackArray.append("Your stance width is similar to or wider than Roger Federer's, providing good stability.")
                feedbackArrayDetailed.append("A stable stance is essential for a powerful serve. Keep up the good work!")
            }
            
            feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
            
        } else if pose == "Hit behind" {
            feedbackArray.append("Nice serve! Let's take a closer look:")
            feedbackArrayDetailed.append("Analyzing your serve can help refine your technique and ensure you're making the most out of each shot.")
            
            guard let leftWrist = joints[.leftWrist],
                  let rightWrist = joints[.rightWrist],
                  let leftShoulder = joints[.leftShoulder],
                  let rightShoulder = joints[.rightShoulder] else {
                feedbackArray.append("Essential joint positions are missing.")
                feedbackArrayDetailed.append("Having all joint positions is crucial for a detailed analysis.")
                feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
                return
            }
            
            // Determine which wrist is higher and adjust the feedback accordingly
            let isLeftWristHigher = leftWrist.y < rightWrist.y
            let higherWristJoint: VNHumanBodyPoseObservation.JointName = isLeftWristHigher ? .leftWrist : .rightWrist
            let lowerWristJoint: VNHumanBodyPoseObservation.JointName = isLeftWristHigher ? .rightWrist : .leftWrist
            let higherShoulder = isLeftWristHigher ? leftShoulder : rightShoulder
            let lowerShoulder = isLeftWristHigher ? rightShoulder : leftShoulder
            
            // Calculate the angle of the arm to determine the direction of the hit
            if let armAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: higherWristJoint, joint3: lowerWristJoint) {
                if armAngle < 50.0 {
                    feedbackArray.append("You're hitting the ball too far to the right of your body.")
                    feedbackArrayDetailed.append("Adjusting your hitting position can help you hit the ball more centrally, improving control and accuracy.")
                } else if armAngle > 100.0 {
                    feedbackArray.append("You're hitting the ball too much to the left.")
                    feedbackArrayDetailed.append("Hitting the ball closer to your body's centerline can enhance power and precision.")
                }
            }
            
            // Check if the arm is properly stretched
            let elbowJoint: VNHumanBodyPoseObservation.JointName = isLeftWristHigher ? .leftElbow : .rightElbow
            
            if let elbowAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: elbowJoint, joint3: higherWristJoint) {
                if elbowAngle > 30.0 {
                    feedbackArray.append("Ensure your arm is fully extended.")
                    feedbackArrayDetailed.append("Keeping your arm straight helps in maximizing the reach and power of your serve.")
                }
            }
            
            // Compare shoulder heights to ensure proper posture
            if lowerShoulder.y <= higherShoulder.y {
                feedbackArray.append("Maintain a lower shoulder position compared to the higher shoulder for better form.")
                feedbackArrayDetailed.append("Proper shoulder positioning enhances stability and control during your serve.")
            }
            
            if feedbackArray.isEmpty {
                feedbackArray.append("Congratulations, your technique looks perfect!")
                feedbackArrayDetailed.append("Keep practicing to maintain this level of performance.")
            }
            
            feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
        }
    }
    
    // Helper function to convert joints to CGPoint
    private func convertJointsToCGPoint(_ joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var convertedJoints = [VNHumanBodyPoseObservation.JointName: CGPoint]()
        for (jointName, recognizedPoint) in joints {
            convertedJoints[jointName] = recognizedPoint.location
        }
        return convertedJoints
    }
    
    // Function to calculate the angle between three joints
    private func calculateAngle(from joints: [VNHumanBodyPoseObservation.JointName: CGPoint], joint1: VNHumanBodyPoseObservation.JointName, joint2: VNHumanBodyPoseObservation.JointName, joint3: VNHumanBodyPoseObservation.JointName) -> CGFloat? {
        guard let point1 = joints[joint1], let point2 = joints[joint2], let point3 = joints[joint3] else {
            return nil
        }
        let vector1 = CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
        let vector2 = CGPoint(x: point3.x - point2.x, y: point3.y - point2.y)
        let angle = atan2(vector2.y, vector2.x) - atan2(vector1.y, vector1.x)
        return abs(angle * 180 / .pi)
    }
}
