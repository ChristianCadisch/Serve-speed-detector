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
    var cameraAngle: ServeCameraAngle = .side

    
    var feedbackHandler: ((String, String) -> Void)?
    
    func detectServe(from joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint], angle: ServeCameraAngle, verbose: Bool = false) -> (Bool, Int32) {
        print("🤖 [AICoach] detectServe called with angle:", angle)
        self.cameraAngle = angle
        
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
                if cameraAngle == .side {
                    provideFeedback(for: convertJointsToCGPoint(joints), pose: "Hit side")
                } else {
                    provideFeedback(for: convertJointsToCGPoint(joints), pose: "Hit behind")
                }
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
    
    
    func detectTrophyPose(from joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint], angle: ServeCameraAngle, verbose: Bool = false) -> (Bool, Int32) {
        
        print("🤖 [AICoach] detectTrophyPose called with angle:", angle)
        self.cameraAngle = angle
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
                if cameraAngle == .side {
                    provideFeedback(for: convertJointsToCGPoint(joints), pose: "Trophy side")
                    print("feedback side")
                } else {
                    provideFeedback(for: convertJointsToCGPoint(joints), pose: "Trophy behind")
                    print("feedback back")

                }
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
                feedbackArray.append("Your knees are bent \(Int(federerAverageAngle - averageKneeAngle))° less than Roger Federer's. This may reduce the power of your serve")
                feedbackArrayDetailed.append("Having less knee bend can impact the explosiveness of your serve. Try bending your knees more to generate more power")
            } else {
                feedbackArray.append("Your knee bending is on par with Roger Federer's, which is excellent for power generation")
                feedbackArrayDetailed.append("Maintaining this level of knee bend helps you to utilize your lower body strength effectively")
            }
            
            // Calculate foot placement
            guard let leftAnkle = joints[.leftAnkle], let rightAnkle = joints[.rightAnkle] else {
                feedbackArray.append("Could not determine ankle positions")
                feedbackArrayDetailed.append("Without accurate ankle positions, it's challenging to assess your stance properly")
                feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
                return
            }
            
            let playerStanceDistance = abs(leftAnkle.x - rightAnkle.x)
            let federerStanceDistance = 112.0  // The reference distance for Federer's stance width
            
            // Feedback on foot placement
            if playerStanceDistance / federerStanceDistance < 0.9 {
                feedbackArray.append("Your feet are closer together compared to Roger Federer, which could affect your stability")
                feedbackArrayDetailed.append("Wider foot placement can enhance stability and balance, helping you maintain a strong base during your serve")
            } else {
                feedbackArray.append("Your stance width is similar to or wider than Roger Federer's, providing good stability")
                feedbackArrayDetailed.append("A stable stance is essential for a powerful serve. Keep up the good work!")
            }
            
            feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
            
        } else if pose == "Hit behind" {
            
            guard let leftWrist = joints[.leftWrist],
                  let rightWrist = joints[.rightWrist],
                  let leftShoulder = joints[.leftShoulder],
                  let rightShoulder = joints[.rightShoulder] else {
                feedbackArray.append("Essential joint positions are missing")
                feedbackArrayDetailed.append("Having all joint positions is crucial for a detailed analysis")
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
                    feedbackArray.append("You're hitting the ball too far to the right of your body")
                    feedbackArrayDetailed.append("Adjusting your hitting position can help you hit the ball more centrally, improving control and accuracy")
                } else if armAngle > 100.0 {
                    feedbackArray.append("You're hitting the ball too much to the left")
                    feedbackArrayDetailed.append("Hitting the ball closer to your body's centerline can enhance power and precision")
                }
            }
            
            // Check if the arm is properly stretched
            let elbowJoint: VNHumanBodyPoseObservation.JointName = isLeftWristHigher ? .leftElbow : .rightElbow
            
            if let elbowAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: elbowJoint, joint3: higherWristJoint) {
                if elbowAngle > 30.0 {
                    feedbackArray.append("Ensure your arm is fully extended")
                    feedbackArrayDetailed.append("Keeping your arm straight helps in maximizing the reach and power of your serve")
                }
            }
            
            // Compare shoulder heights to ensure proper posture
            if lowerShoulder.y <= higherShoulder.y {
                feedbackArray.append("Maintain a lower shoulder position compared to the higher shoulder for better form")
                feedbackArrayDetailed.append("Proper shoulder positioning enhances stability and control during your serve")
            }
            
            if feedbackArray.isEmpty {
                feedbackArray.append("Congratulations, your technique looks perfect!")
                feedbackArrayDetailed.append("Keep practicing to maintain this level of performance")
            }
            
            feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
        } else if pose == "Trophy side" {
            
            guard
                let leftShoulder = joints[.leftShoulder],
                let leftElbow = joints[.leftElbow],
                let leftWrist = joints[.leftWrist],
                let rightShoulder = joints[.rightShoulder],
                let rightElbow = joints[.rightElbow],
                let rightWrist = joints[.rightWrist],
                let leftHip = joints[.leftHip],
                let leftKnee = joints[.leftKnee]
            else {
                feedbackArray.append("Missing joints for trophy-side analysis")
                feedbackArrayDetailed.append("Not enough pose information to reliably analyze the trophy pose from the side")
                feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
                return
            }
            
            if let elbowAngle = calculateAngle(from: joints, joint1: .leftShoulder, joint2: .leftElbow, joint3: .leftWrist) {
                if elbowAngle > 25 {
                    feedbackArray.append("Your tossing arm is not fully stretched")
                    feedbackArrayDetailed.append("A straight tossing arm improves consistency and ball control")
                }
            }
            
            if let armDirection = calculateAngle(from: joints, joint1: .leftShoulder, joint2: .leftWrist, joint3: .rightShoulder) {
                if abs(armDirection - 90) > 15 {
                    feedbackArray.append("Your tossing arm should point more upwards")
                    feedbackArrayDetailed.append("Directing the hand toward the ball improves toss precision and alignment")
                }
            }
            
            if (leftHip.x + 0.02) < leftKnee.x {
                feedbackArray.append("Your hip should lead the body forward")
                feedbackArrayDetailed.append("Driving the hip ahead of the knee creates proper body arch and energy transfer")
            }
            
            if let shoulderLine = calculateAngle(from: joints, joint1: .leftShoulder, joint2: .rightShoulder, joint3: .rightElbow) {
                if shoulderLine > 20 {
                    feedbackArray.append("Your right elbow and shoulders should align horizontally")
                    feedbackArrayDetailed.append("A straight shoulder–elbow line improves racket drop and power loading")
                }
            }
            
            if let rightElbowAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: .rightElbow, joint3: .rightWrist) {
                if rightElbowAngle > 80 {
                    feedbackArray.append("Your hitting-arm elbow should be more bent")
                    feedbackArrayDetailed.append("A tighter elbow angle brings the racket closer to the head for better acceleration")
                }
            }
            
            feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
            
            
        } else if pose == "Hit side" {
            
            guard
                let leftWrist = joints[.leftWrist],
                let rightWrist = joints[.rightWrist],
                let leftShoulder = joints[.leftShoulder],
                let rightShoulder = joints[.rightShoulder],
                let rightElbow = joints[.rightElbow],
                let rightHip = joints[.rightHip]
            else {
                feedbackArray.append("Missing joints for hit-side analysis")
                feedbackArrayDetailed.append("Not enough pose information to evaluate the hitting phase from the side")
                feedbackHandler?(feedbackArray.joined(separator: "\n"), feedbackArrayDetailed.joined(separator: "\n"))
                return
            }
            
            let isLeftHigher = leftWrist.y < rightWrist.y
            let hittingWrist = isLeftHigher ? leftWrist : rightWrist
            let hittingShoulder = isLeftHigher ? leftShoulder : rightShoulder
            let hittingElbow: CGPoint = isLeftHigher ? joints[.leftElbow]! : joints[.rightElbow]!
            
            if let armDirection = calculateAngle(from: joints, joint1: hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                                 joint2: hittingWrist == leftWrist ? .leftWrist : .rightWrist,
                                                 joint3: hittingElbow == joints[.leftElbow]! ? .leftElbow : .rightElbow) {
                
                if armDirection > 75 {
                    feedbackArray.append("You should hit the ball slightly more in front")
                    feedbackArrayDetailed.append("Contacting the ball earlier improves power transfer and reduces drag on the arm")
                } else if armDirection < 55 {
                    feedbackArray.append("You are contacting the ball too far in front")
                    feedbackArrayDetailed.append("Ideal contact is just ahead of the body—not excessively forward")
                }
            }
            
            if let elbowAngle = calculateAngle(from: joints,
                                               joint1: hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                               joint2: hittingElbow == joints[.leftElbow]! ? .leftElbow : .rightElbow,
                                               joint3: hittingWrist == leftWrist ? .leftWrist : .rightWrist) {
                if elbowAngle > 30 {
                    feedbackArray.append("Your hitting arm should be straighter at contact")
                    feedbackArrayDetailed.append("A straight arm maximizes reach and upward extension through the ball")
                }
            }
            
            if let stretchAngle = calculateAngle(from: joints, joint1: .rightHip, joint2: .rightShoulder, joint3: .rightWrist) {
                if stretchAngle > 20 {
                    feedbackArray.append("Your upper body should form a straighter line")
                    feedbackArrayDetailed.append("Hip–shoulder–wrist alignment improves energy transfer into the ball")
                }
            }
            
            if leftWrist.y > leftShoulder.y {
                feedbackArray.append("Your non-hitting arm should stay lower during the hit")
                feedbackArrayDetailed.append("Lowering the left arm supports torso rotation and prevents balance loss")
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
