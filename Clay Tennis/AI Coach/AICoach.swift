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

    
    var feedbackHandler: ((String, String, String, String) -> Void)?
    
    func detectServe(from joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint], angle: ServeCameraAngle, verbose: Bool = false) -> (Bool, Int32) {
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
    
    
    
    
    func provideFeedback(
        for joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        pose: String,
        verbose: Bool = false
    ) {
        var feedbackArray = [String]()
        var feedbackArrayDetailed = [String]()
        var positiveFeedbackArray = [String]()
        var keywordArray = [String]()  // ← NEW TAG LIST

        func vprint(_ label: String, _ value: Any? = nil) {
            if verbose {
                if let value = value { print("🤖 [AICOACH DEBUG] \(label): \(value)") }
                else { print("🤖 [AICOACH DEBUG] \(label)") }
            }
        }

        // ---------------------------------------------------------
        // MARK: - TROPHY BEHIND
        // ---------------------------------------------------------
        if pose == "Trophy behind" {

            guard let leftKneeAngle = calculateAngle(from: joints, joint1: .leftHip, joint2: .leftKnee, joint3: .leftAnkle),
                  let rightKneeAngle = calculateAngle(from: joints, joint1: .rightHip, joint2: .rightKnee, joint3: .rightAnkle)
            else { return }

            let avgLoad = (180 - leftKneeAngle + 180 - rightKneeAngle) / 2
            let idealLoad = 75.0

            if avgLoad < idealLoad {
                feedbackArray.append("Your knee bend is too shallow")
                feedbackArrayDetailed.append("More knee flexion strengthens loading")
                keywordArray.append("trophy_knee_bend_low")
            } else {
                positiveFeedbackArray.append("Strong lower-body loading — great knee bend")
                keywordArray.append("trophy_knee_bend_good")
            }

            guard let leftAnkle = joints[.leftAnkle], let rightAnkle = joints[.rightAnkle] else { return }
            let stanceWidth = abs(leftAnkle.x - rightAnkle.x)
            let reference = 112.0

            if stanceWidth / reference < 0.9 {
                feedbackArray.append("Your stance is slightly too narrow")
                feedbackArrayDetailed.append("Wider base improves balance")
                keywordArray.append("trophy_stance_narrow")
            } else {
                positiveFeedbackArray.append("Good, stable stance width")
                keywordArray.append("trophy_stance_good")
            }

            feedbackHandler?(
                feedbackArray.joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n"),
                keywordArray.joined(separator: "\n")

            )
            return
        }


        // ---------------------------------------------------------
        // MARK: - HIT BEHIND
        // ---------------------------------------------------------
        if pose == "Hit behind" {

            guard let leftWrist = joints[.leftWrist],
                  let rightWrist = joints[.rightWrist],
                  let leftShoulder = joints[.leftShoulder],
                  let rightShoulder = joints[.rightShoulder]
            else { return }

            let isLeftHigher = leftWrist.y < rightWrist.y
            let higherWrist = isLeftHigher ? leftWrist : rightWrist
            let lowerWrist = isLeftHigher ? rightWrist : leftWrist

            // Contact direction
            if let armAngle = calculateAngle(from: joints,
                                             joint1: .rightShoulder,
                                             joint2: isLeftHigher ? .leftWrist : .rightWrist,
                                             joint3: isLeftHigher ? .rightWrist : .leftWrist) {

                if armAngle < 50 {
                    feedbackArray.append("Your contact point is too far right")
                    feedbackArrayDetailed.append("Reduces directional stability")
                    keywordArray.append("hit_contact_right")
                } else if armAngle > 100 {
                    feedbackArray.append("Your contact point is too far left")
                    feedbackArrayDetailed.append("Center contact improves control")
                    keywordArray.append("hit_contact_left")
                } else {
                    positiveFeedbackArray.append("Great ball contact alignment")
                    keywordArray.append("hit_contact_good")
                }
            }

            // Arm extension
            if let elbowAngle = calculateAngle(from: joints,
                                               joint1: .rightShoulder,
                                               joint2: isLeftHigher ? .leftElbow : .rightElbow,
                                               joint3: isLeftHigher ? .leftWrist : .rightWrist) {

                if elbowAngle > 30 {
                    feedbackArray.append("Your hitting arm should be more extended")
                    feedbackArrayDetailed.append("Straight arm maximizes reach")
                    keywordArray.append("hit_arm_bent")
                } else {
                    positiveFeedbackArray.append("Excellent arm extension at contact")
                    keywordArray.append("hit_arm_straight")
                }
            }

            // Shoulder tilt
            let higher = isLeftHigher ? leftShoulder : rightShoulder
            let lower = isLeftHigher ? rightShoulder : leftShoulder

            if lower.y <= higher.y {
                feedbackArray.append("Increase your shoulder tilt")
                feedbackArrayDetailed.append("Better upward swing path")
                keywordArray.append("hit_shoulder_flat")
            } else {
                positiveFeedbackArray.append("Good shoulder tilt")
                keywordArray.append("hit_shoulder_tilt_good")
            }

            feedbackHandler?(
                feedbackArray.joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n"),
                keywordArray.joined(separator: "\n")

            )
            return
        }


        // ---------------------------------------------------------
        // MARK: - TROPHY SIDE
        // ---------------------------------------------------------
        if pose == "Trophy side" {

            guard let leftShoulder = joints[.leftShoulder],
                  let leftElbow = joints[.leftElbow],
                  let leftWrist = joints[.leftWrist],
                  let rightShoulder = joints[.rightShoulder],
                  let rightElbow = joints[.rightElbow],
                  let rightWrist = joints[.rightWrist],
                  let leftHip = joints[.leftHip],
                  let leftKnee = joints[.leftKnee]
            else { return }

            // Tossing arm straightness
            if let elbowAngle = calculateAngle(from: joints,
                                               joint1: .leftShoulder,
                                               joint2: .leftElbow,
                                               joint3: .leftWrist) {

                if elbowAngle > 25 {
                    feedbackArray.append("Your tossing arm should be straighter")
                    feedbackArrayDetailed.append("Straight arm improves toss stability")
                    keywordArray.append("trophy_arm_bent")
                } else {
                    positiveFeedbackArray.append("Excellent tossing-arm extension")
                    keywordArray.append("trophy_arm_straight")
                }
            }

            // Toss direction (upward)
            if let armDirection = calculateAngle(from: joints,
                                                 joint1: .leftShoulder,
                                                 joint2: .leftWrist,
                                                 joint3: .rightShoulder) {

                if abs(armDirection - 90) > 15 {
                    feedbackArray.append("Your tossing arm should point more upward")
                    feedbackArrayDetailed.append("Better vertical alignment")
                    keywordArray.append("trophy_toss_off")
                } else {
                    positiveFeedbackArray.append("Good toss direction")
                    keywordArray.append("trophy_toss_up")
                }
            }

            // Hip leading knee
            if (leftHip.x + 0.02) < leftKnee.x {
                feedbackArray.append("Your hip should lead your knee forward")
                feedbackArrayDetailed.append("Correct hip lead loads kinetic chain")
                keywordArray.append("trophy_hip_back")
            } else {
                positiveFeedbackArray.append("Good hip lead")
                keywordArray.append("trophy_hip_good")
            }

            // Shoulder–elbow horizontal line
            if let shoulderLine = calculateAngle(from: joints,
                                                 joint1: .leftShoulder,
                                                 joint2: .rightShoulder,
                                                 joint3: .rightElbow) {

                if shoulderLine > 20 {
                    feedbackArray.append("Your hitting-arm elbow should align more horizontally")
                    feedbackArrayDetailed.append("Helps racket drop")
                    keywordArray.append("trophy_elbow_high")
                } else {
                    positiveFeedbackArray.append("Good shoulder–elbow alignment")
                    keywordArray.append("trophy_elbow_good")
                }
            }

            // Hitting-arm elbow load angle
            if let rightElbowAngle = calculateAngle(from: joints,
                                                    joint1: .rightShoulder,
                                                    joint2: .rightElbow,
                                                    joint3: .rightWrist) {

                if rightElbowAngle > 80 {
                    feedbackArray.append("Your hitting-arm elbow should be more bent")
                    feedbackArrayDetailed.append("Tighter angle improves whip")
                    keywordArray.append("trophy_hitting_elbow_open")
                } else {
                    positiveFeedbackArray.append("Great hitting-arm loading angle")
                    keywordArray.append("trophy_hitting_elbow_good")
                }
            }

            feedbackHandler?(
                feedbackArray.joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n"),
                keywordArray.joined(separator: "\n")

            )
            return
        }


        // ---------------------------------------------------------
        // MARK: - HIT SIDE
        // ---------------------------------------------------------
        if pose == "Hit side" {

            guard let leftWrist = joints[.leftWrist],
                  let rightWrist = joints[.rightWrist],
                  let leftShoulder = joints[.leftShoulder],
                  let rightShoulder = joints[.rightShoulder],
                  let rightElbow = joints[.rightElbow],
                  let rightHip = joints[.rightHip]
            else { return }

            let isLeftHigher = leftWrist.y < rightWrist.y
            let hittingWrist = isLeftHigher ? leftWrist : rightWrist
            let hittingShoulder = isLeftHigher ? leftShoulder : rightShoulder
            let hittingElbowJoint = isLeftHigher ? VNHumanBodyPoseObservation.JointName.leftElbow : .rightElbow

            // Contact position (forward/back)
            if let armDirection = calculateAngle(
                from: joints,
                joint1: isLeftHigher ? .leftShoulder : .rightShoulder,
                joint2: isLeftHigher ? .leftWrist : .rightWrist,
                joint3: hittingElbowJoint
            ) {

                if armDirection > 75 {
                    feedbackArray.append("Your contact point could be slightly further forward")
                    feedbackArrayDetailed.append("Earlier contact improves acceleration")
                    keywordArray.append("hit_forward_low")
                } else if armDirection < 55 {
                    feedbackArray.append("Your contact point is too far in front")
                    feedbackArrayDetailed.append("Optimal contact slightly ahead")
                    keywordArray.append("hit_forward_high")
                } else {
                    positiveFeedbackArray.append("Well-timed contact point")
                    keywordArray.append("hit_forward_good")
                }
            }

            // Arm extension
            if let elbowAngle = calculateAngle(
                from: joints,
                joint1: isLeftHigher ? .leftShoulder : .rightShoulder,
                joint2: hittingElbowJoint,
                joint3: isLeftHigher ? .leftWrist : .rightWrist
            ) {

                if elbowAngle > 30 {
                    feedbackArray.append("Your hitting arm should be more extended")
                    feedbackArrayDetailed.append("Straight arm maximizes reach")
                    keywordArray.append("hit_arm_bent")
                } else {
                    positiveFeedbackArray.append("Great arm extension at contact")
                    keywordArray.append("hit_arm_straight")
                }
            }

            // Body alignment
            if let stretchAngle = calculateAngle(from: joints,
                                                 joint1: .rightHip,
                                                 joint2: .rightShoulder,
                                                 joint3: .rightWrist) {

                if stretchAngle > 20 {
                    feedbackArray.append("Try forming a straighter upper-body line")
                    feedbackArrayDetailed.append("Improves energy transfer")
                    keywordArray.append("hit_torso_bent")
                } else {
                    positiveFeedbackArray.append("Excellent upper-body alignment")
                    keywordArray.append("hit_torso_good")
                }
            }

            // Left arm position (non-hitting)
            if leftWrist.y > leftShoulder.y {
                feedbackArray.append("Your non-hitting arm should stay lower")
                feedbackArrayDetailed.append("Stabilizes torso rotation")
                keywordArray.append("hit_leftarm_high")
            } else {
                positiveFeedbackArray.append("Good non-hitting-arm positioning")
                keywordArray.append("hit_leftarm_good")
            }

            feedbackHandler?(
                feedbackArray.joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n"),
                keywordArray.joined(separator: "\n")

            )
            return
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
