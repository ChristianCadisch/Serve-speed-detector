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

    
    var feedbackHandler: ((String, String, String, String, [HighlightInstruction]) -> Void)?

    
    
    func provideFeedback(
            for joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
            pose: String,
            verbose: Bool = false
        ) {
            var feedbackArray = [String]()
            var feedbackArrayDetailed = [String]()
            var positiveFeedbackArray = [String]()
            var positiveFeedbackDetailed = [String]()
            var highlightInstructions = [HighlightInstruction]()

            func vprint(_ label: String, _ value: Any? = nil) {
                if verbose {
                    if let v = value { print("🤖 [AICOACH DEBUG] \(label): \(v)") }
                    else { print("🤖 [AICOACH DEBUG] \(label)") }
                }
            }

            // ---------------------------------------------------------
            // MARK: - TROPHY BEHIND
            // ---------------------------------------------------------
            if pose == "Trophy behind" {
                
                guard
                    let leftKneeAngle = calculateAngle(from: joints, joint1: .leftHip, joint2: .leftKnee, joint3: .leftAnkle),
                    let rightKneeAngle = calculateAngle(from: joints, joint1: .rightHip, joint2: .rightKnee, joint3: .rightAnkle)
                else { return }
                
                let avgLoad = abs((180 - leftKneeAngle + 180 - rightKneeAngle) / 2)
                let minimalLoad = 75.0
                
                print("📊 [TROPHY BEHIND] Avg Load: \(avgLoad)° (Ideal: \(minimalLoad)°)")
                
                if avgLoad < minimalLoad {
                    print("⚠️ FEEDBACK: Your knee bend is too shallow | Metric: avgLoad=\(avgLoad)° < \(minimalLoad)°")
                    feedbackArray.append("Your knee bend is too shallow")
                    feedbackArrayDetailed.append("More knee flexion strengthens loading")
                    
                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftKnee, .leftHip, .leftAnkle, .rightHip, .rightAnkle, .rightKnee],
                            segments: [(.leftHip, .leftKnee), (.leftKnee, .leftAnkle), (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)],
                            color: "orange"
                        )
                    )
                } else {
                    print("✅ POSITIVE: Strong lower-body loading — great knee bend | Metric: avgLoad=\(avgLoad)° >= \(minimalLoad)°")
                    positiveFeedbackArray.append("Strong lower-body loading — great knee bend")
                    positiveFeedbackDetailed.append("Optimal power position achieved")
                    
                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftKnee, .leftHip, .leftAnkle, .rightHip, .rightAnkle, .rightKnee],
                            segments: [(.leftHip, .leftKnee), (.leftKnee, .leftAnkle), (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)],
                            color: "green"
                        )
                    )
                }
                
                
                guard
                    let leftWrist = joints[.leftWrist],
                    let rightWrist = joints[.rightWrist],
                    let leftShoulder = joints[.leftShoulder],
                    let rightShoulder = joints[.rightShoulder]
                else { return }

                let isLeftHigher = leftWrist.y < rightWrist.y
                let hitterWrist = isLeftHigher ? leftWrist : rightWrist
                let hitterShoulder = isLeftHigher ? leftShoulder : rightShoulder
                let hitterElbowJoint = isLeftHigher ? VNHumanBodyPoseObservation.JointName.leftElbow : .rightElbow

                if let armAngle = calculateAngle(
                    from: joints,
                    joint1: .rightShoulder,
                    joint2: isLeftHigher ? .leftWrist : .rightWrist,
                    joint3: isLeftHigher ? .rightWrist : .leftWrist
                ) {
                    print("📊 [TROPHY BEHIND] Arm Angle: \(armAngle)° (Range: 50-100°)")
                    
                    if armAngle < 50 {
                        print("⚠️ FEEDBACK: Your contact point is too far right | Metric: armAngle=\(armAngle)° < 50°")
                        feedbackArray.append("Your contact point is too far right")
                        feedbackArrayDetailed.append("Reduces directional stability")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, .rightWrist],
                                segments: [(.rightShoulder, .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else if armAngle > 100 {
                        print("⚠️ FEEDBACK: Your contact point is too far left | Metric: armAngle=\(armAngle)° > 100°")
                        feedbackArray.append("Your contact point is too far left")
                        feedbackArrayDetailed.append("Center contact improves control")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, .rightWrist],
                                segments: [(.rightShoulder, .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Great ball contact alignment | Metric: armAngle=\(armAngle)° (50-100°)")
                        positiveFeedbackArray.append("Great ball contact alignment")
                        positiveFeedbackDetailed.append("Centered contact maximizes power")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [hitterShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                         hitterWrist == leftWrist ? .leftWrist : .rightWrist],
                                segments: [(hitterShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                            hitterWrist == leftWrist ? .leftWrist : .rightWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                if let elbowAngle = calculateAngle(
                    from: joints,
                    joint1: .leftShoulder,
                    joint2: .leftElbow,
                    joint3: .leftWrist
                   ) {
                    print("📊 [TROPHY BEHIND] Elbow Angle: \(elbowAngle)° (Threshold: 30°)")
                    
                    if elbowAngle > 30 {
                        print("⚠️ FEEDBACK: Your hitting arm should be more extended | Metric: elbowAngle=\(elbowAngle)° > 30°")
                        feedbackArray.append("Your hitting arm should be more extended")
                        feedbackArrayDetailed.append("Straight arm maximizes reach")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.leftShoulder, .leftElbow, .leftWrist],
                                segments: [(.leftShoulder, .leftElbow),
                                           (.leftElbow, .leftWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Excellent arm extension at contact | Metric: elbowAngle=\(elbowAngle)° <= 30°")
                        positiveFeedbackArray.append("Excellent arm extension at contact")
                        positiveFeedbackDetailed.append("Full reach achieved")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.leftShoulder, .leftElbow, .leftWrist],
                                segments: [(.leftShoulder, .leftElbow),
                                           (.leftElbow, .leftWrist)],
                                color: "green"
                            )
                        )
                    }
                }
                
                
                let higherShoulder = isLeftHigher ? leftShoulder : rightShoulder
                let lowerShoulder = isLeftHigher ? rightShoulder : leftShoulder
                
                print("📊 [TROPHY BEHIND] Shoulder Tilt: lower.y=\(lowerShoulder.y), higher.y=\(higherShoulder.y)")

                if lowerShoulder.y <= higherShoulder.y {
                    print("⚠️ FEEDBACK: Increase your shoulder tilt | Metric: lowerShoulder.y=\(lowerShoulder.y) <= higherShoulder.y=\(higherShoulder.y)")
                    feedbackArray.append("Increase your shoulder tilt")
                    feedbackArrayDetailed.append("Better upward swing path")

                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftShoulder, .rightShoulder],
                            segments: [(.leftShoulder, .rightShoulder)],
                            color: "orange"
                        )
                    )
                } else {
                    print("✅ POSITIVE: Good shoulder tilt | Metric: lowerShoulder.y=\(lowerShoulder.y) > higherShoulder.y=\(higherShoulder.y)")
                    positiveFeedbackArray.append("Good shoulder tilt")
                    positiveFeedbackDetailed.append("Proper upward trajectory angle")

                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftShoulder, .rightShoulder],
                            segments: [(.leftShoulder, .rightShoulder)],
                            color: "green"
                        )
                    )
                }

                feedbackHandler?(
                    feedbackArray.joined(separator: "\n"),
                    feedbackArrayDetailed.joined(separator: "\n"),
                    positiveFeedbackArray.joined(separator: "\n"),
                    positiveFeedbackDetailed.joined(separator: "\n"),
                    highlightInstructions
                )
                return
            }

            // ---------------------------------------------------------
            // MARK: - HIT BEHIND
            // ---------------------------------------------------------
            if pose == "Hit behind" {

                guard
                    let leftWrist = joints[.leftWrist],
                    let rightWrist = joints[.rightWrist],
                    let leftShoulder = joints[.leftShoulder],
                    let rightShoulder = joints[.rightShoulder]
                else { return }

                let isLeftHigher = leftWrist.y < rightWrist.y
                let hitterWrist = isLeftHigher ? leftWrist : rightWrist
                let hitterShoulder = isLeftHigher ? leftShoulder : rightShoulder
                let hitterElbowJoint = isLeftHigher ? VNHumanBodyPoseObservation.JointName.leftElbow : .rightElbow

                if let armAngle = calculateAngle(
                    from: joints,
                    joint1: .rightShoulder,
                    joint2: isLeftHigher ? .leftWrist : .rightWrist,
                    joint3: isLeftHigher ? .rightWrist : .leftWrist
                ) {
                    print("📊 [HIT BEHIND] Arm Angle: \(armAngle)° (Range: 50-100°)")
                    
                    if armAngle < 50 {
                        print("⚠️ FEEDBACK: Your contact point is too far right | Metric: armAngle=\(armAngle)° < 50°")
                        feedbackArray.append("Your contact point is too far right")
                        feedbackArrayDetailed.append("Reduces directional stability")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, .rightWrist],
                                segments: [(.rightShoulder, .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else if armAngle > 100 {
                        print("⚠️ FEEDBACK: Your contact point is too far left | Metric: armAngle=\(armAngle)° > 100°")
                        feedbackArray.append("Your contact point is too far left")
                        feedbackArrayDetailed.append("Center contact improves control")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, .rightWrist],
                                segments: [(.rightShoulder, .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Great ball contact alignment | Metric: armAngle=\(armAngle)° (50-100°)")
                        positiveFeedbackArray.append("Great ball contact alignment")
                        positiveFeedbackDetailed.append("Optimal hitting zone achieved")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [hitterShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                         hitterWrist == leftWrist ? .leftWrist : .rightWrist],
                                segments: [(hitterShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                            hitterWrist == leftWrist ? .leftWrist : .rightWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                if let elbowAngle = calculateAngle(
                    from: joints,
                    joint1: .rightShoulder,
                    joint2: hitterElbowJoint,
                    joint3: isLeftHigher ? .leftWrist : .rightWrist
                ) {
                    print("📊 [HIT BEHIND] Elbow Angle: \(elbowAngle)° (Threshold: 30°)")
                    
                    if elbowAngle > 30 {
                        print("⚠️ FEEDBACK: Your hitting arm should be more extended | Metric: elbowAngle=\(elbowAngle)° > 30°")
                        feedbackArray.append("Your hitting arm should be more extended")
                        feedbackArrayDetailed.append("Straight arm maximizes reach")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, hitterElbowJoint, isLeftHigher ? .leftWrist : .rightWrist],
                                segments: [(.rightShoulder, hitterElbowJoint),
                                           (hitterElbowJoint, isLeftHigher ? .leftWrist : .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Excellent arm extension at contact | Metric: elbowAngle=\(elbowAngle)° <= 30°")
                        positiveFeedbackArray.append("Excellent arm extension at contact")
                        positiveFeedbackDetailed.append("Maximum reach and power")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, hitterElbowJoint, isLeftHigher ? .leftWrist : .rightWrist],
                                segments: [(.rightShoulder, hitterElbowJoint),
                                           (hitterElbowJoint, isLeftHigher ? .leftWrist : .rightWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                let higherShoulder = isLeftHigher ? leftShoulder : rightShoulder
                let lowerShoulder = isLeftHigher ? rightShoulder : leftShoulder
                
                print("📊 [HIT BEHIND] Shoulder Tilt: lower.y=\(lowerShoulder.y), higher.y=\(higherShoulder.y)")

                if lowerShoulder.y <= higherShoulder.y {
                    print("⚠️ FEEDBACK: Increase your shoulder tilt | Metric: lowerShoulder.y=\(lowerShoulder.y) <= higherShoulder.y=\(higherShoulder.y)")
                    feedbackArray.append("Increase your shoulder tilt")
                    feedbackArrayDetailed.append("Better upward swing path")

                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftShoulder, .rightShoulder],
                            segments: [(.leftShoulder, .rightShoulder)],
                            color: "orange"
                        )
                    )
                } else {
                    print("✅ POSITIVE: Good shoulder tilt | Metric: lowerShoulder.y=\(lowerShoulder.y) > higherShoulder.y=\(higherShoulder.y)")
                    positiveFeedbackArray.append("Good shoulder tilt")
                    positiveFeedbackDetailed.append("Correct upward swing angle")

                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftShoulder, .rightShoulder],
                            segments: [(.leftShoulder, .rightShoulder)],
                            color: "green"
                        )
                    )
                }

                feedbackHandler?(
                    feedbackArray.joined(separator: "\n"),
                    feedbackArrayDetailed.joined(separator: "\n"),
                    positiveFeedbackArray.joined(separator: "\n"),
                    positiveFeedbackDetailed.joined(separator: "\n"),
                    highlightInstructions
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
                else { return }

                if let elbowAngle = calculateAngle(
                    from: joints,
                    joint1: .leftShoulder,
                    joint2: .leftElbow,
                    joint3: .leftWrist
                ) {
                    print("📊 [TROPHY SIDE] Tossing Arm Elbow Angle: \(elbowAngle)° (Threshold: 25°)")
                    
                    if elbowAngle > 25 {
                        print("⚠️ FEEDBACK: Your tossing arm should be straighter | Metric: elbowAngle=\(elbowAngle)° > 25°")
                        feedbackArray.append("Your tossing arm should be straighter")
                        feedbackArrayDetailed.append("Straight arm improves toss stability")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.leftShoulder, .leftElbow, .leftWrist],
                                segments: [(.leftShoulder, .leftElbow),
                                           (.leftElbow, .leftWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Excellent tossing-arm extension | Metric: elbowAngle=\(elbowAngle)° <= 25°")
                        positiveFeedbackArray.append("Excellent tossing-arm extension")
                        positiveFeedbackDetailed.append("Stable toss platform achieved")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.leftShoulder, .leftElbow, .leftWrist],
                                segments: [(.leftShoulder, .leftElbow),
                                           (.leftElbow, .leftWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                if let tossAngle = calculateAngle(
                    from: joints,
                    joint1: .leftShoulder,
                    joint2: .leftWrist,
                    joint3: .rightShoulder
                ) {
                    let deviationFrom90 = abs(tossAngle - 90)
                    print("📊 [TROPHY SIDE] Toss Angle: \(tossAngle)° (Deviation from 90°: \(deviationFrom90)°, Max: 15°)")
                    
                    if deviationFrom90 > 15 {
                        print("⚠️ FEEDBACK: Your tossing arm should point more upward | Metric: deviation=\(deviationFrom90)° > 15°")
                        feedbackArray.append("Your tossing arm should point more upward")
                        feedbackArrayDetailed.append("Better vertical alignment")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.leftShoulder, .leftWrist],
                                segments: [(.leftShoulder, .leftWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Good toss direction | Metric: deviation=\(deviationFrom90)° <= 15°")
                        positiveFeedbackArray.append("Good toss direction")
                        positiveFeedbackDetailed.append("Vertical alignment correct")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.leftShoulder, .leftWrist],
                                segments: [(.leftShoulder, .leftWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                let hipKneeOffset = leftKnee.x - (leftHip.x + 0.02)
                print("📊 [TROPHY SIDE] Hip-Knee Offset: \(hipKneeOffset) (leftKnee.x=\(leftKnee.x), leftHip.x+0.02=\(leftHip.x + 0.02))")

                if (leftHip.x + 0.02) < leftKnee.x {
                    print("⚠️ FEEDBACK: Your hip should lead your knee forward | Metric: leftHip.x+0.02=\(leftHip.x + 0.02) < leftKnee.x=\(leftKnee.x)")
                    feedbackArray.append("Your hip should lead your knee forward")
                    feedbackArrayDetailed.append("Correct hip lead loads kinetic chain")

                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftHip, .leftKnee],
                            segments: [(.leftHip, .leftKnee)],
                            color: "orange"
                        )
                    )
                } else {
                    print("✅ POSITIVE: Good hip lead | Metric: leftHip.x+0.02=\(leftHip.x + 0.02) >= leftKnee.x=\(leftKnee.x)")
                    positiveFeedbackArray.append("Good hip lead")
                    positiveFeedbackDetailed.append("Kinetic chain properly loaded")

                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftHip, .leftKnee],
                            segments: [(.leftHip, .leftKnee)],
                            color: "green"
                        )
                    )
                }

                if let shoulderLine = calculateAngle(
                    from: joints,
                    joint1: .leftShoulder,
                    joint2: .rightShoulder,
                    joint3: .rightElbow
                ) {
                    print("📊 [TROPHY SIDE] Shoulder-Elbow Line Angle: \(shoulderLine)° (Threshold: 20°)")
                    
                    if shoulderLine > 20 {
                        print("⚠️ FEEDBACK: Your hitting-arm elbow should align more horizontally | Metric: shoulderLine=\(shoulderLine)° > 20°")
                        feedbackArray.append("Your hitting-arm elbow should align more horizontally")
                        feedbackArrayDetailed.append("Helps racket drop")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, .rightElbow],
                                segments: [(.rightShoulder, .rightElbow)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Good shoulder–elbow alignment | Metric: shoulderLine=\(shoulderLine)° <= 20°")
                        positiveFeedbackArray.append("Good shoulder–elbow alignment")
                        positiveFeedbackDetailed.append("Optimal racket drop position")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, .rightElbow],
                                segments: [(.rightShoulder, .rightElbow)],
                                color: "green"
                            )
                        )
                    }
                }

                if let rightElbowAngle = calculateAngle(
                    from: joints,
                    joint1: .rightShoulder,
                    joint2: .rightElbow,
                    joint3: .rightWrist
                ) {
                    print("📊 [TROPHY SIDE] Hitting Arm Elbow Angle: \(rightElbowAngle)° (Threshold: 80°)")
                    
                    if rightElbowAngle > 80 {
                        print("⚠️ FEEDBACK: Your hitting-arm elbow should be more bent | Metric: rightElbowAngle=\(rightElbowAngle)° > 80°")
                        feedbackArray.append("Your hitting-arm elbow should be more bent")
                        feedbackArrayDetailed.append("Tighter angle improves whip")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, .rightElbow, .rightWrist],
                                segments: [(.rightShoulder, .rightElbow),
                                           (.rightElbow, .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Great hitting-arm loading angle | Metric: rightElbowAngle=\(rightElbowAngle)° <= 80°")
                        positiveFeedbackArray.append("Great hitting-arm loading angle")
                        positiveFeedbackDetailed.append("Maximum whip effect ready")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightShoulder, .rightElbow, .rightWrist],
                                segments: [(.rightShoulder, .rightElbow),
                                           (.rightElbow, .rightWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                feedbackHandler?(
                    feedbackArray.joined(separator: "\n"),
                    feedbackArrayDetailed.joined(separator: "\n"),
                    positiveFeedbackArray.joined(separator: "\n"),
                    positiveFeedbackDetailed.joined(separator: "\n"),
                    highlightInstructions
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
                else { return }

                let isLeftHigher = leftWrist.y < rightWrist.y
                let hittingWrist = isLeftHigher ? leftWrist : rightWrist
                let hittingShoulder = isLeftHigher ? leftShoulder : rightShoulder
                let elbowJoint = isLeftHigher ? VNHumanBodyPoseObservation.JointName.leftElbow : .rightElbow

                if let armDirection = calculateAngle(
                    from: joints,
                    joint1: hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                    joint2: hittingWrist == leftWrist ? .leftWrist : .rightWrist,
                    joint3: elbowJoint
                ) {
                    print("📊 [HIT SIDE] Arm Direction Angle: \(armDirection)° (Range: 55-75°)")
                    
                    if armDirection > 75 {
                        print("⚠️ FEEDBACK: Your contact point could be slightly further forward | Metric: armDirection=\(armDirection)° > 75°")
                        feedbackArray.append("Your contact point could be slightly further forward")
                        feedbackArrayDetailed.append("Earlier contact improves acceleration")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                         elbowJoint,
                                         hittingWrist == leftWrist ? .leftWrist : .rightWrist],
                                segments: [(hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder, elbowJoint),
                                           (elbowJoint, hittingWrist == leftWrist ? .leftWrist : .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else if armDirection < 55 {
                        print("⚠️ FEEDBACK: Your contact point is too far in front | Metric: armDirection=\(armDirection)° < 55°")
                        feedbackArray.append("Your contact point is too far in front")
                        feedbackArrayDetailed.append("Optimal contact slightly ahead")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                         elbowJoint,
                                         hittingWrist == leftWrist ? .leftWrist : .rightWrist],
                                segments: [(hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder, elbowJoint),
                                           (elbowJoint, hittingWrist == leftWrist ? .leftWrist : .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Well-timed contact point | Metric: armDirection=\(armDirection)° (55-75°)")
                        positiveFeedbackArray.append("Well-timed contact point")
                        positiveFeedbackDetailed.append("Well-timed contact point")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                         elbowJoint,
                                         hittingWrist == leftWrist ? .leftWrist : .rightWrist],
                                segments: [(hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder, elbowJoint),
                                           (elbowJoint, hittingWrist == leftWrist ? .leftWrist : .rightWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                if let elbowAngle = calculateAngle(
                    from: joints,
                    joint1: hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                    joint2: elbowJoint,
                    joint3: hittingWrist == leftWrist ? .leftWrist : .rightWrist
                ) {
                    print("📊 [HIT SIDE] Elbow Angle: \(elbowAngle)° (Threshold: 30°)")
                    
                    if elbowAngle > 30 {
                        print("⚠️ FEEDBACK: Your hitting arm should be more extended | Metric: elbowAngle=\(elbowAngle)° > 30°")
                        feedbackArray.append("Your hitting arm should be more extended")
                        feedbackArrayDetailed.append("Straight arm maximizes reach")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                         elbowJoint,
                                         hittingWrist == leftWrist ? .leftWrist : .rightWrist],
                                segments: [(hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder, elbowJoint),
                                           (elbowJoint, hittingWrist == leftWrist ? .leftWrist : .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Great arm extension at contact | Metric: elbowAngle=\(elbowAngle)° <= 30°")
                        positiveFeedbackArray.append("Great arm extension at contact")
                        positiveFeedbackDetailed.append("Great arm extension at contact")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder,
                                         elbowJoint,
                                         hittingWrist == leftWrist ? .leftWrist : .rightWrist],
                                segments: [(hittingShoulder == leftShoulder ? .leftShoulder : .rightShoulder, elbowJoint),
                                           (elbowJoint, hittingWrist == leftWrist ? .leftWrist : .rightWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                if let stretchAngle = calculateAngle(
                    from: joints,
                    joint1: .rightHip,
                    joint2: .rightShoulder,
                    joint3: .rightWrist
                ) {
                    print("📊 [HIT SIDE] Upper Body Stretch Angle: \(stretchAngle)° (Threshold: 20°)")
                    
                    if stretchAngle > 20 {
                        print("⚠️ FEEDBACK: Try forming a straighter upper-body line | Metric: stretchAngle=\(stretchAngle)° > 20°")
                        feedbackArray.append("Try forming a straighter upper-body line")
                        feedbackArrayDetailed.append("Improves energy transfer")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightHip, .rightShoulder, .rightWrist],
                                segments: [(.rightHip, .rightShoulder),
                                           (.rightShoulder, .rightWrist)],
                                color: "orange"
                            )
                        )
                    } else {
                        print("✅ POSITIVE: Excellent upper-body alignment | Metric: stretchAngle=\(stretchAngle)° <= 20°")
                        positiveFeedbackArray.append("Excellent upper-body alignment")
                        positiveFeedbackDetailed.append("Excellent upper-body alignment")

                        highlightInstructions.append(
                            HighlightInstruction(
                                joints: [.rightHip, .rightShoulder, .rightWrist],
                                segments: [(.rightHip, .rightShoulder),
                                           (.rightShoulder, .rightWrist)],
                                color: "green"
                            )
                        )
                    }
                }

                print("📊 [HIT SIDE] Non-hitting Arm: leftWrist.y=\(leftWrist.y), leftShoulder.y=\(leftShoulder.y)")

                if leftWrist.y > leftShoulder.y {
                    print("⚠️ FEEDBACK: Your non-hitting arm should stay lower | Metric: leftWrist.y=\(leftWrist.y) > leftShoulder.y=\(leftShoulder.y)")
                    feedbackArray.append("Your non-hitting arm should stay lower")
                    feedbackArrayDetailed.append("Stabilizes torso rotation")

                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftShoulder, .leftWrist],
                            segments: [(.leftShoulder, .leftWrist)],
                            color: "orange"
                        )
                    )
                } else {
                    print("✅ POSITIVE: Good non-hitting-arm positioning | Metric: leftWrist.y=\(leftWrist.y) <= leftShoulder.y=\(leftShoulder.y)")
                    positiveFeedbackArray.append("Good non-hitting-arm positioning")
                    positiveFeedbackDetailed.append("Good non-hitting-arm positioning")

                    highlightInstructions.append(
                        HighlightInstruction(
                            joints: [.leftShoulder, .leftWrist],
                            segments: [(.leftShoulder, .leftWrist)],
                            color: "green"
                        )
                    )
                }

                feedbackHandler?(
                    feedbackArray.joined(separator: "\n"),
                    feedbackArrayDetailed.joined(separator: "\n"),
                    positiveFeedbackArray.joined(separator: "\n"),
                    positiveFeedbackDetailed.joined(separator: "\n"),
                    highlightInstructions
                )
                return
            }
        }

    
    
    
    
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


struct HighlightInstruction {
    let joints: [VNHumanBodyPoseObservation.JointName]
    let segments: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)]
    let color: String
}

