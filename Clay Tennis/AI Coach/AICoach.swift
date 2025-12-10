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

    
    var feedbackHandler: ((String, String, String) -> Void)?
    
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
    
    
    
    
    func provideFeedback(
        for joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        pose: String,
        verbose: Bool = false
    ) {
        var feedbackArray = [String]()
        var feedbackArrayDetailed = [String]()
        var positiveFeedbackArray = [String]()

        func vprint(_ label: String, _ value: Any? = nil) {
            if verbose {
                if let value = value {
                    print("🤖 [AICOACH DEBUG] \(label): \(value)")
                } else {
                    print("🤖 [AICOACH DEBUG] \(label)")
                }
            }
        }

        // ---------------------------------------------------------
        // MARK: - TROPHY BEHIND
        // ---------------------------------------------------------
        if pose == "Trophy behind" {

            guard let leftKneeAngle = calculateAngle(from: joints, joint1: .leftHip, joint2: .leftKnee, joint3: .leftAnkle),
                  let rightKneeAngle = calculateAngle(from: joints, joint1: .rightHip, joint2: .rightKnee, joint3: .rightAnkle) else {

                vprint("Missing knee angles → cannot compute trophy-behind feedback")
                return
            }

            let avgLoad = (180 - leftKneeAngle + 180 - rightKneeAngle) / 2
            let idealLoad = 75.0

            vprint("Left knee angle", leftKneeAngle)
            vprint("Right knee angle", rightKneeAngle)
            vprint("Average knee load", avgLoad)

            if avgLoad < idealLoad {
                feedbackArray.append("Your knee bend is too shallow")
                feedbackArrayDetailed.append("More knee flexion strengthens the loading phase and increases upward drive")
                vprint("Knee load result", "Too shallow")
            } else {
                positiveFeedbackArray.append("Strong lower-body loading — great knee bend")
                vprint("Knee load result", "Good / positive feedback")
            }

            guard let leftAnkle = joints[.leftAnkle], let rightAnkle = joints[.rightAnkle] else {
                vprint("Missing ankle positions")
                feedbackArray.append("Unable to assess stance width")
                feedbackArrayDetailed.append("Accurate ankle positions are required to evaluate stance stability")
                return
            }

            let stanceWidth = abs(leftAnkle.x - rightAnkle.x)
            let reference = 112.0

            vprint("Left ankle", leftAnkle)
            vprint("Right ankle", rightAnkle)
            vprint("Stance width", stanceWidth)

            if stanceWidth / reference < 0.9 {
                feedbackArray.append("Your stance is slightly too narrow")
                feedbackArrayDetailed.append("A wider base improves balance and supports a stronger hip–shoulder coil")
                vprint("Stance width result", "Too narrow")
            } else {
                positiveFeedbackArray.append("Good, stable stance width")
                vprint("Stance width result", "Good")
            }

            feedbackHandler?(
                (feedbackArray + positiveFeedbackArray).joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n")
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
                  let rightShoulder = joints[.rightShoulder] else {

                vprint("Missing wrist/shoulder joints")
                feedbackArray.append("Essential joint positions missing")
                feedbackArrayDetailed.append("Full wrist and shoulder data is required for hit-phase evaluation")
                return
            }

            vprint("Left wrist", leftWrist)
            vprint("Right wrist", rightWrist)
            vprint("Left shoulder", leftShoulder)
            vprint("Right shoulder", rightShoulder)

            let isLeftHigher = leftWrist.y < rightWrist.y
            let higherWristJoint: VNHumanBodyPoseObservation.JointName = isLeftHigher ? .leftWrist : .rightWrist
            let lowerWristJoint: VNHumanBodyPoseObservation.JointName = isLeftHigher ? .rightWrist : .leftWrist

            vprint("Higher wrist is left?", isLeftHigher)

            // Direction angle
            if let armAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: higherWristJoint, joint3: lowerWristJoint) {

                vprint("Arm direction angle", armAngle)

                if armAngle < 50 {
                    feedbackArray.append("Your contact point is too far right")
                    feedbackArrayDetailed.append("This reduces directional stability")
                    vprint("Arm angle result", "Too far right")
                } else if armAngle > 100 {
                    feedbackArray.append("Your contact point is too far left")
                    feedbackArrayDetailed.append("Centering your contact improves control")
                    vprint("Arm angle result", "Too far left")
                } else {
                    positiveFeedbackArray.append("Great ball contact alignment")
                    vprint("Arm angle result", "Good / positive")
                }
            }

            // Arm extension
            let elbowJoint: VNHumanBodyPoseObservation.JointName = isLeftHigher ? .leftElbow : .rightElbow

            if let elbowAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: elbowJoint, joint3: higherWristJoint) {

                vprint("Elbow extension angle", elbowAngle)

                if elbowAngle > 30 {
                    feedbackArray.append("Your hitting arm should be more extended")
                    feedbackArrayDetailed.append("A straighter arm maximizes reach and power")
                    vprint("Elbow extension result", "Not straight enough")
                } else {
                    positiveFeedbackArray.append("Excellent arm extension at contact")
                    vprint("Elbow extension result", "Good")
                }
            }

            // Shoulder tilt
            let higherShoulder = isLeftHigher ? leftShoulder : rightShoulder
            let lowerShoulder = isLeftHigher ? rightShoulder : leftShoulder

            vprint("Higher shoulder y", higherShoulder.y)
            vprint("Lower shoulder y", lowerShoulder.y)

            if lowerShoulder.y <= higherShoulder.y {
                feedbackArray.append("Increase your shoulder tilt for better upward swing path")
                feedbackArrayDetailed.append("A stronger drop of the non-hitting shoulder stabilizes rotation")
                vprint("Shoulder tilt result", "Insufficient")
            } else {
                positiveFeedbackArray.append("Good shoulder tilt at contact")
                vprint("Shoulder tilt result", "Good")
            }

            feedbackHandler?(
                (feedbackArray + positiveFeedbackArray).joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n")
            )

            return
        }

        // ---------------------------------------------------------
        // MARK: - TROPHY SIDE
        // ---------------------------------------------------------
        if pose == "Trophy side" {

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
                vprint("Missing joints for trophy-side evaluation")
                feedbackArray.append("Missing joints for trophy-side analysis")
                feedbackArrayDetailed.append("Insufficient markers to evaluate trophy pose")
                return
            }

            vprint("Left arm joints", "\(leftShoulder), \(leftElbow), \(leftWrist)")
            vprint("Right arm joints", "\(rightShoulder), \(rightElbow), \(rightWrist)")
            vprint("Left hip", leftHip)
            vprint("Left knee", leftKnee)

            // Tossing arm straightness
            if let elbowAngle = calculateAngle(from: joints, joint1: .leftShoulder, joint2: .leftElbow, joint3: .leftWrist) {

                vprint("Tossing arm elbow angle", elbowAngle)

                if elbowAngle > 25 {
                    feedbackArray.append("Your tossing arm should be straighter")
                    feedbackArrayDetailed.append("A straight arm improves toss stability")
                    vprint("Toss arm result", "Too bent")
                } else {
                    positiveFeedbackArray.append("Excellent tossing-arm extension")
                    vprint("Toss arm result", "Good")
                }
            }

            // Toss direction
            if let armDirection = calculateAngle(from: joints, joint1: .leftShoulder, joint2: .leftWrist, joint3: .rightShoulder) {

                vprint("Toss direction angle", armDirection)

                if abs(armDirection - 90) > 15 {
                    feedbackArray.append("Your tossing arm should point more upward")
                    feedbackArrayDetailed.append("Better vertical alignment improves consistency")
                    vprint("Toss direction result", "Off")
                } else {
                    positiveFeedbackArray.append("Good toss direction alignment")
                    vprint("Toss direction result", "Good")
                }
            }

            // Hip lead
            vprint("Hip x", leftHip.x)
            vprint("Knee x", leftKnee.x)

            if (leftHip.x + 0.02) < leftKnee.x {
                feedbackArray.append("Your hip should lead your knee forward")
                feedbackArrayDetailed.append("Correct hip lead loads the kinetic chain properly")
                vprint("Hip lead result", "Hip behind knee → incorrect")
            } else {
                positiveFeedbackArray.append("Good hip lead and torso alignment")
                vprint("Hip lead result", "Correct")
            }

            // Shoulder–elbow line
            if let shoulderLine = calculateAngle(from: joints, joint1: .leftShoulder, joint2: .rightShoulder, joint3: .rightElbow) {

                vprint("Shoulder–elbow line angle", shoulderLine)

                if shoulderLine > 20 {
                    feedbackArray.append("Your hitting-arm elbow should align more horizontally")
                    feedbackArrayDetailed.append("A straighter alignment helps with racket drop")
                    vprint("Shoulder–elbow result", "Misaligned")
                } else {
                    positiveFeedbackArray.append("Solid shoulder–elbow alignment")
                    vprint("Shoulder–elbow result", "Good")
                }
            }

            // Hitting arm elbow angle
            if let rightElbowAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: .rightElbow, joint3: .rightWrist) {

                vprint("Hitting arm elbow angle", rightElbowAngle)

                if rightElbowAngle > 80 {
                    feedbackArray.append("Your hitting-arm elbow should be more bent")
                    feedbackArrayDetailed.append("A tighter angle improves racket whip")
                    vprint("Hitting arm elbow result", "Too open")
                } else {
                    positiveFeedbackArray.append("Great hitting-arm loading angle")
                    vprint("Hitting arm elbow result", "Good")
                }
            }

            feedbackHandler?(
                (feedbackArray + positiveFeedbackArray).joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n")
            )

            return
        }

        // ---------------------------------------------------------
        // MARK: - HIT SIDE
        // ---------------------------------------------------------
        if pose == "Hit side" {

            guard
                let leftWrist = joints[.leftWrist],
                let rightWrist = joints[.rightWrist],
                let leftShoulder = joints[.leftShoulder],
                let rightShoulder = joints[.rightShoulder],
                let rightElbow = joints[.rightElbow],
                let rightHip = joints[.rightHip]
            else {
                vprint("Missing joints for hit-side evaluation")
                feedbackArray.append("Missing joints for hit-side analysis")
                feedbackArrayDetailed.append("Full upper-body markers required for contact-phase evaluation")
                return
            }

            vprint("Left wrist", leftWrist)
            vprint("Right wrist", rightWrist)
            vprint("Left shoulder", leftShoulder)
            vprint("Right shoulder", rightShoulder)
            vprint("Right elbow", rightElbow)
            vprint("Right hip", rightHip)

            let isLeftHigher = leftWrist.y < rightWrist.y
            let hittingWrist = isLeftHigher ? leftWrist : rightWrist
            let hittingShoulder = isLeftHigher ? leftShoulder : rightShoulder
            let hittingElbow = isLeftHigher ? joints[.leftElbow]! : joints[.rightElbow]!

            vprint("Identified hitting side", isLeftHigher ? "Left" : "Right")
            vprint("Hitting wrist", hittingWrist)
            vprint("Hitting shoulder", hittingShoulder)
            vprint("Hitting elbow", hittingElbow)

            // Contact position angle
            if let armDirection = calculateAngle(
                from: joints,
                joint1: hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                joint2: hittingWrist == leftWrist ? .leftWrist : .rightWrist,
                joint3: hittingElbow == joints[.leftElbow]! ? .leftElbow : .rightElbow
            ) {

                vprint("Contact arm direction angle", armDirection)

                if armDirection > 75 {
                    feedbackArray.append("Your contact point could be slightly further forward")
                    feedbackArrayDetailed.append("Earlier contact improves upward acceleration")
                    vprint("Contact result", "Slightly late")
                } else if armDirection < 55 {
                    feedbackArray.append("Your contact point is too far in front")
                    feedbackArrayDetailed.append("Ideal contact is just ahead of the body, not excessively forward")
                    vprint("Contact result", "Too early")
                } else {
                    positiveFeedbackArray.append("Well-timed contact point")
                    vprint("Contact result", "Good")
                }
            }

            // Arm extension
            if let elbowAngle = calculateAngle(
                from: joints,
                joint1: hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                joint2: hittingElbow == joints[.leftElbow]! ? .leftElbow : .rightElbow,
                joint3: hittingWrist == leftWrist ? .leftWrist : .rightWrist
            ) {

                vprint("Arm extension angle", elbowAngle)

                if elbowAngle > 30 {
                    feedbackArray.append("Your hitting arm should be more extended")
                    feedbackArrayDetailed.append("A straight arm maximizes reach and upward drive")
                    vprint("Arm extension result", "Not straight enough")
                } else {
                    positiveFeedbackArray.append("Great arm extension at contact")
                    vprint("Arm extension result", "Good")
                }
            }

            // Body alignment
            if let stretchAngle = calculateAngle(from: joints, joint1: .rightHip, joint2: .rightShoulder, joint3: .rightWrist) {

                vprint("Upper-body alignment angle", stretchAngle)

                if stretchAngle > 20 {
                    feedbackArray.append("Try forming a straighter upper-body line")
                    feedbackArrayDetailed.append("Better torso alignment improves energy transfer")
                    vprint("Alignment result", "Off")
                } else {
                    positiveFeedbackArray.append("Excellent upper-body alignment")
                    vprint("Alignment result", "Good")
                }
            }

            // Non-hitting arm
            vprint("Left wrist y", leftWrist.y)
            vprint("Left shoulder y", leftShoulder.y)

            if leftWrist.y > leftShoulder.y {
                feedbackArray.append("Your non-hitting arm should stay lower")
                feedbackArrayDetailed.append("A lower left arm stabilizes torso rotation")
                vprint("Non-hitting arm result", "Too high")
            } else {
                positiveFeedbackArray.append("Good non-hitting-arm positioning")
                vprint("Non-hitting arm result", "Good")
            }

            feedbackHandler?(
                (feedbackArray + positiveFeedbackArray).joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n")
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
