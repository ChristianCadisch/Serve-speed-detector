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
        
        var negativeHighlights: [HighlightInstruction] = []
        var positiveHighlights: [HighlightInstruction] = []
        
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
                feedbackArray.append(
                    NSLocalizedString(
                        "trophy_knee_bend_shallow_title",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                feedbackArrayDetailed.append(
                    NSLocalizedString(
                        "trophy_knee_bend_shallow_detail",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                
                negativeHighlights.append(
                    HighlightInstruction(
                        joints: [.leftKnee, .leftHip, .leftAnkle, .rightHip, .rightAnkle, .rightKnee],
                        segments: [
                            (.leftHip, .leftKnee),
                            (.leftKnee, .leftAnkle),
                            (.rightHip, .rightKnee),
                            (.rightKnee, .rightAnkle)
                        ],
                        color: "orange"
                    )
                )
            } else {
                positiveFeedbackArray.append(
                    NSLocalizedString(
                        "trophy_knee_bend_strong_title",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                positiveFeedbackDetailed.append(
                    NSLocalizedString(
                        "trophy_knee_bend_strong_detail",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                
                positiveHighlights.append(
                    HighlightInstruction(
                        joints: [.leftKnee, .leftHip, .leftAnkle, .rightHip, .rightAnkle, .rightKnee],
                        segments: [
                            (.leftHip, .leftKnee),
                            (.leftKnee, .leftAnkle),
                            (.rightHip, .rightKnee),
                            (.rightKnee, .rightAnkle)
                        ],
                        color: "green"
                    )
                )
            }
            
            
            // ---------------------------------------------------------
            // Tossing arm checks (Trophy phase) — UPDATED THRESHOLDS
            // ---------------------------------------------------------
            guard
                let leftWrist = joints[.leftWrist],
                let rightWrist = joints[.rightWrist],
                let leftShoulder = joints[.leftShoulder],
                let rightShoulder = joints[.rightShoulder]
            else {
                print("⚠️ [TROPHY BEHIND] Missing wrist / shoulder for tossing arm analysis")
                return
            }
            
            // Higher wrist = tossing arm (Vision coords: higher = larger y)
            let isLeftTossArm = leftWrist.y > rightWrist.y
            
            let tossShoulderJoint: VNHumanBodyPoseObservation.JointName =
            isLeftTossArm ? .leftShoulder : .rightShoulder
            let tossElbowJoint: VNHumanBodyPoseObservation.JointName =
            isLeftTossArm ? .leftElbow : .rightElbow
            let tossWristJoint: VNHumanBodyPoseObservation.JointName =
            isLeftTossArm ? .leftWrist : .rightWrist
            
            print("🎾 [TROPHY BEHIND] Tossing arm detected:",
                  isLeftTossArm ? "LEFT" : "RIGHT")
            
            // ---------------------------------------------------------
            // 1) Tossing arm elbow straightness (PRO-TOLERANT)
            // ---------------------------------------------------------
            if let rawElbowAngle = calculateAngle(
                from: joints,
                joint1: tossShoulderJoint,
                joint2: tossElbowJoint,
                joint3: tossWristJoint
            ) {
                let interiorAngle = normalizedInteriorAngle(rawElbowAngle)
                let elbowBend = 180.0 - interiorAngle
                
                print(
                    "📐 [TROPHY BEHIND] Toss elbow raw =", rawElbowAngle,
                    "→ interior =", interiorAngle,
                    "→ bend =", elbowBend
                )
                
                if elbowBend > 45 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "trophy_toss_arm_bent_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "trophy_toss_arm_bent_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [tossShoulderJoint, tossElbowJoint, tossWristJoint],
                            segments: [
                                (tossShoulderJoint, tossElbowJoint),
                                (tossElbowJoint, tossWristJoint)
                            ],
                            color: "orange"
                        )
                    )
                } else if elbowBend <= 35 {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "trophy_toss_arm_extended_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "trophy_toss_arm_extended_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [tossShoulderJoint, tossElbowJoint, tossWristJoint],
                            segments: [
                                (tossShoulderJoint, tossElbowJoint),
                                (tossElbowJoint, tossWristJoint)
                            ],
                            color: "green"
                        )
                    )
                }
                else {
                    print("ℹ️ [TROPHY BEHIND] Toss elbow in neutral range — no feedback")
                }
            } else {
                print("⚠️ [TROPHY BEHIND] Unable to compute toss elbow angle")
            }
            
            // ---------------------------------------------------------
            // 2) Tossing arm verticality (POINTING TO THE SKY)
            // ---------------------------------------------------------
            if
                let tossShoulder = joints[tossShoulderJoint],
                let tossWrist = joints[tossWristJoint]
            {
                let dx = tossWrist.x - tossShoulder.x
                let dy = tossWrist.y - tossShoulder.y
                
                let verticalDeviation = abs(atan2(dx, dy)) * 180.0 / .pi
                
                print(
                    "📐 [TROPHY BEHIND] Toss arm verticality:",
                    "dx =", dx,
                    "dy =", dy,
                    "→ deviation =", verticalDeviation, "°"
                )
                
                if verticalDeviation > 35 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "trophy_toss_arm_not_vertical_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "trophy_toss_arm_not_vertical_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [tossShoulderJoint, tossWristJoint],
                            segments: [(tossShoulderJoint, tossWristJoint)],
                            color: "orange"
                        )
                    )
                } else if verticalDeviation <= 20 {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "trophy_toss_arm_vertical_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "trophy_toss_arm_vertical_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [tossShoulderJoint, tossWristJoint],
                            segments: [(tossShoulderJoint, tossWristJoint)],
                            color: "green"
                        )
                    )
                }
                else {
                    print("ℹ️ [TROPHY BEHIND] Toss verticality in neutral range — no feedback")
                }
            } else {
                print("⚠️ [TROPHY BEHIND] Missing shoulder/wrist points for verticality check")
            }
            
            
            
            feedbackHandler?(
                feedbackArray.joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n"),
                positiveFeedbackDetailed.joined(separator: "\n"),
                negativeHighlights + positiveHighlights
            )
            return
        }
        
        // ---------------------------------------------------------
        // MARK: - HIT BEHIND (FIXED + DEBUG)
        // ---------------------------------------------------------
        if pose == "Hit behind" {
            
            guard
                let leftWrist = joints[.leftWrist],
                let rightWrist = joints[.rightWrist],
                let leftShoulder = joints[.leftShoulder],
                let rightShoulder = joints[.rightShoulder]
            else { return }
            
            // ---------------------------------------------------------
            // DEBUG: Wrist positions
            // ---------------------------------------------------------
            print("🖐️ [DEBUG] Left Wrist  y =", leftWrist.y)
            print("🖐️ [DEBUG] Right Wrist y =", rightWrist.y)
            
            // IMPORTANT FIX:
            // Higher on screen = LARGER y (Vision normalized coords)
            let isLeftHitter = leftWrist.y > rightWrist.y
            
            print("🎾 [DEBUG] Detected hitter arm =", isLeftHitter ? "LEFT" : "RIGHT")
            
            let hitterShoulderJoint: VNHumanBodyPoseObservation.JointName =
            isLeftHitter ? .leftShoulder : .rightShoulder
            let hitterElbowJoint: VNHumanBodyPoseObservation.JointName =
            isLeftHitter ? .leftElbow : .rightElbow
            let hitterWristJoint: VNHumanBodyPoseObservation.JointName =
            isLeftHitter ? .leftWrist : .rightWrist
            
            print("🦴 [DEBUG] Using joints:",
                  hitterShoulderJoint.rawValue,
                  hitterElbowJoint.rawValue,
                  hitterWristJoint.rawValue)
            
            
            
            
            // ---------------------------------------------------------
            // Elbow extension
            // ---------------------------------------------------------
            if let rawElbowAngle = calculateAngle(
                from: joints,
                joint1: hitterShoulderJoint,
                joint2: hitterElbowJoint,
                joint3: hitterWristJoint
            ) {
                let interiorElbowAngle = normalizedInteriorAngle(rawElbowAngle)
                let elbowBend = 180.0 - interiorElbowAngle
                
                print(
                    "📐 [HIT BEHIND] Elbow raw =", rawElbowAngle,
                    "→ interior =", interiorElbowAngle,
                    "→ bend =", elbowBend
                )
                
                // PRO-CALIBRATED THRESHOLDS
                if elbowBend > 45 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "hit_behind_arm_not_extended_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "hit_behind_arm_not_extended_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [hitterShoulderJoint, hitterElbowJoint, hitterWristJoint],
                            segments: [
                                (hitterShoulderJoint, hitterElbowJoint),
                                (hitterElbowJoint, hitterWristJoint)
                            ],
                            color: "orange"
                        )
                    )
                } else {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "hit_behind_arm_extended_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "hit_behind_arm_extended_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [hitterShoulderJoint, hitterElbowJoint, hitterWristJoint],
                            segments: [
                                (hitterShoulderJoint, hitterElbowJoint),
                                (hitterElbowJoint, hitterWristJoint)
                            ],
                            color: "green"
                        )
                    )
                }
                
            }
            
            
            // ---------------------------------------------------------
            // Shoulder tilt
            // ---------------------------------------------------------
            let leftShoulderHigher = leftShoulder.y > rightShoulder.y
            print("📐 [DEBUG] Shoulder y — L:", leftShoulder.y, "R:", rightShoulder.y)
            
            let higherShoulder = leftShoulderHigher ? leftShoulder : rightShoulder
            let lowerShoulder = leftShoulderHigher ? rightShoulder : leftShoulder
            
            let shoulderTilt = abs(lowerShoulder.y - higherShoulder.y)
            
            print("📐 [HIT BEHIND] Shoulder tilt Δy =", shoulderTilt)
            
            if shoulderTilt < 0.02 {
                feedbackArray.append(
                    NSLocalizedString(
                        "hit_behind_shoulder_tilt_insufficient_title",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                feedbackArrayDetailed.append(
                    NSLocalizedString(
                        "hit_behind_shoulder_tilt_insufficient_detail",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                
                negativeHighlights.append(
                    HighlightInstruction(
                        joints: [.leftShoulder, .rightShoulder],
                        segments: [(.leftShoulder, .rightShoulder)],
                        color: "orange"
                    )
                )
            } else {
                positiveFeedbackArray.append(
                    NSLocalizedString(
                        "hit_behind_shoulder_tilt_good_title",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                positiveFeedbackDetailed.append(
                    NSLocalizedString(
                        "hit_behind_shoulder_tilt_good_detail",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                
                positiveHighlights.append(
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
                negativeHighlights + positiveHighlights
            )
            return
        }
        
        // ---------------------------------------------------------
        // MARK: - TROPHY SIDE (ROBUST SIDE DETECTION + DEBUG)
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
                let leftKnee = joints[.leftKnee],
                let rightHip = joints[.rightHip],
                let rightKnee = joints[.rightKnee]
            else {
                print("⚠️ [TROPHY SIDE] Missing required joints")
                return
            }
            
            // ---------------------------------------------------------
            // Determine forward direction (side view)
            // ---------------------------------------------------------
            let torsoDX = (rightShoulder.x - leftShoulder.x)
            
            let forwardSign: CGFloat = torsoDX >= 0 ? 1.0 : -1.0
            // forwardSign = +1 → player facing right
            // forwardSign = -1 → player facing left
            
            print("""
                🎾 [TROPHY SIDE][DEBUG] Torso dx = \(torsoDX)
                🎾 [TROPHY SIDE][DEBUG] Forward direction sign = \(forwardSign > 0 ? "RIGHT" : "LEFT")
                """)
            
            
            // ---------------------------------------------------------
            // 1) Determine hitting side (SIDE VIEW LOGIC)
            // ---------------------------------------------------------
            // In side view, the hitting arm is:
            // - the arm with the LOWER wrist (post-trophy drop)
            // - and the elbow that is MORE BEHIND the shoulder (x-axis)
            //
            // We combine both signals for robustness.
            
            
            
            let wristDeltaY = rightWrist.y - leftWrist.y          // >0 → right wrist lower
            let elbowDeltaX = rightElbow.x - leftElbow.x          // <0 → right elbow further back (camera-dependent)
            
            print("""
                🎾 [TROPHY SIDE][DEBUG] Wrist Y — L: \(leftWrist.y) R: \(rightWrist.y) Δ=\(wristDeltaY)
                🎾 [TROPHY SIDE][DEBUG] Elbow X — L: \(leftElbow.x) R: \(rightElbow.x) Δ=\(elbowDeltaX)
                """)
            
            let rightIsHitterScore =
            (wristDeltaY > 0 ? 1 : 0) +
            (elbowDeltaX < 0 ? 1 : 0)
            
            let isRightHitter = rightIsHitterScore >= 1
            
            print("🎾 [TROPHY SIDE] Detected hitting arm:",
                  isRightHitter ? "RIGHT" : "LEFT",
                  "(score:", rightIsHitterScore, ")")
            
            let hitShoulderJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .rightShoulder : .leftShoulder
            let hitElbowJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .rightElbow : .leftElbow
            let hitWristJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .rightWrist : .leftWrist
            
            let tossShoulderJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .leftShoulder : .rightShoulder
            let tossElbowJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .leftElbow : .rightElbow
            let tossWristJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .leftWrist : .rightWrist
            
            // ---------------------------------------------------------
            // 2) Tossing arm elbow straightness (SIDE VIEW)
            // ---------------------------------------------------------
            if let rawTossElbowAngle = calculateAngle(
                from: joints,
                joint1: tossShoulderJoint,
                joint2: tossElbowJoint,
                joint3: tossWristJoint
            ) {
                let interior = normalizedInteriorAngle(rawTossElbowAngle)
                let bend = 180.0 - interior
                
                print(
                    "📐 [TROPHY SIDE] Toss elbow raw =", rawTossElbowAngle,
                    "→ interior =", interior,
                    "→ bend =", bend
                )
                
                if bend > 45 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "trophy_side_toss_arm_not_extended_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "trophy_side_toss_arm_not_extended_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [tossShoulderJoint, tossElbowJoint, tossWristJoint],
                            segments: [
                                (tossShoulderJoint, tossElbowJoint),
                                (tossElbowJoint, tossWristJoint)
                            ],
                            color: "orange"
                        )
                    )
                } else if bend <= 35 {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "trophy_side_toss_arm_extended_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "trophy_side_toss_arm_extended_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [tossShoulderJoint, tossElbowJoint, tossWristJoint],
                            segments: [
                                (tossShoulderJoint, tossElbowJoint),
                                (tossElbowJoint, tossWristJoint)
                            ],
                            color: "green"
                        )
                    )
                }
                else {
                    print("ℹ️ [TROPHY SIDE] Toss elbow in neutral range")
                }
            }
            
            // ---------------------------------------------------------
            // 3) Tossing arm verticality (SIDE VIEW)
            // ---------------------------------------------------------
            if
                let tossShoulder = joints[tossShoulderJoint],
                let tossWrist = joints[tossWristJoint]
            {
                let dx = tossWrist.x - tossShoulder.x
                let dy = tossWrist.y - tossShoulder.y
                let deviation = abs(atan2(dx, dy)) * 180.0 / .pi
                
                print(
                    "📐 [TROPHY SIDE] Toss arm verticality:",
                    "dx =", dx,
                    "dy =", dy,
                    "→ deviation =", deviation, "°"
                )
                
                if deviation > 35 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "trophy_side_toss_arm_not_vertical_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "trophy_side_toss_arm_not_vertical_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [tossShoulderJoint, tossWristJoint],
                            segments: [(tossShoulderJoint, tossWristJoint)],
                            color: "orange"
                        )
                    )
                } else if deviation <= 20 {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "trophy_side_toss_arm_vertical_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "trophy_side_toss_arm_vertical_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [tossShoulderJoint, tossWristJoint],
                            segments: [(tossShoulderJoint, tossWristJoint)],
                            color: "green"
                        )
                    )
                }
                else {
                    print("ℹ️ [TROPHY SIDE] Toss verticality neutral")
                }
            }
            
            // ---------------------------------------------------------
            // 4) Hitting-arm elbow loading (SIDE VIEW)
            // ---------------------------------------------------------
            if let rawHitElbowAngle = calculateAngle(
                from: joints,
                joint1: hitShoulderJoint,
                joint2: hitElbowJoint,
                joint3: hitWristJoint
            ) {
                let interior = normalizedInteriorAngle(rawHitElbowAngle)
                let bend = 180.0 - interior
                
                print(
                    "📐 [TROPHY SIDE] Hitting elbow raw =", rawHitElbowAngle,
                    "→ interior =", interior,
                    "→ bend =", bend
                )
                
                if bend < 20 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "trophy_side_hit_arm_underloaded_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "trophy_side_hit_arm_underloaded_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [hitShoulderJoint, hitElbowJoint, hitWristJoint],
                            segments: [
                                (hitShoulderJoint, hitElbowJoint),
                                (hitElbowJoint, hitWristJoint)
                            ],
                            color: "orange"
                        )
                    )
                } else if bend <= 55 {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "trophy_side_hit_arm_loaded_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "trophy_side_hit_arm_loaded_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [hitShoulderJoint, hitElbowJoint, hitWristJoint],
                            segments: [
                                (hitShoulderJoint, hitElbowJoint),
                                (hitElbowJoint, hitWristJoint)
                            ],
                            color: "green"
                        )
                    )
                }
                else {
                    print("ℹ️ [TROPHY SIDE] Hitting elbow overly bent")
                }
            }
            
            // ---------------------------------------------------------
            // 5) Leading-hip check (SIDE VIEW, SIGN-CORRECTED)
            //    Leading hip should be MOST FORWARD vs shoulder and knee
            // ---------------------------------------------------------
            
            let leadingHip = isRightHitter ? leftHip : rightHip
            let leadingShoulder = isRightHitter ? leftShoulder : rightShoulder
            let leadingKnee = isRightHitter ? leftKnee : rightKnee
            
            let leadingHipJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .leftHip : .rightHip
            let leadingShoulderJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .leftShoulder : .rightShoulder
            let leadingKneeJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .leftKnee : .rightKnee
            
            // Forward-normalized positions (your logs show "more forward" = more negative)
            let hipForward = leadingHip.x * forwardSign
            let shoulderForward = leadingShoulder.x * forwardSign
            let kneeForward = leadingKnee.x * forwardSign
            
            // Define deltas as "how much hip is ahead" in YOUR sign convention
            // If hip is more forward (more negative), these will be POSITIVE.
            let hipAheadOfShoulder = shoulderForward - hipForward
            let hipAheadOfKnee = kneeForward - hipForward
            
            // Pro-tolerant minimum “ahead” distances (in normalized coords)
            let minAheadOfShoulder: CGFloat = 0.005
            let minAheadOfKnee: CGFloat = 0.010
            
            print("""
                📐 [TROPHY SIDE][DEBUG] Leading hip forward check (sign-corrected):
                    hitter=\(isRightHitter ? "RIGHT" : "LEFT")
                    hipForward=\(hipForward)
                    shoulderForward=\(shoulderForward)
                    kneeForward=\(kneeForward)
                    hipAheadOfShoulder=\(hipAheadOfShoulder)
                    hipAheadOfKnee=\(hipAheadOfKnee)
                    thresholds: shoulder>=\(minAheadOfShoulder), knee>=\(minAheadOfKnee)
                """)
            
            let hipLeadsShoulder = hipAheadOfShoulder >= minAheadOfShoulder
            let hipLeadsKnee = hipAheadOfKnee >= minAheadOfKnee
            
            if hipLeadsShoulder && hipLeadsKnee {
                positiveFeedbackArray.append(
                    NSLocalizedString(
                        "trophy_side_hip_lead_good_title",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                positiveFeedbackDetailed.append(
                    NSLocalizedString(
                        "trophy_side_hip_lead_good_detail",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                
                positiveHighlights.append(
                    HighlightInstruction(
                        joints: [leadingHipJoint, leadingShoulderJoint, leadingKneeJoint],
                        segments: [
                            (leadingHipJoint, leadingShoulderJoint),
                            (leadingHipJoint, leadingKneeJoint)
                        ],
                        color: "green"
                    )
                )
            } else {
                feedbackArray.append(
                    NSLocalizedString(
                        "trophy_side_hip_lead_insufficient_title",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                feedbackArrayDetailed.append(
                    NSLocalizedString(
                        "trophy_side_hip_lead_insufficient_detail",
                        tableName: "AICoach",
                        comment: ""
                    )
                )
                
                negativeHighlights.append(
                    HighlightInstruction(
                        joints: [leadingHipJoint, leadingShoulderJoint, leadingKneeJoint],
                        segments: [
                            (leadingHipJoint, leadingShoulderJoint),
                            (leadingHipJoint, leadingKneeJoint)
                        ],
                        color: "orange"
                    )
                )
            }
            
            
            
            
            
            feedbackHandler?(
                feedbackArray.joined(separator: "\n"),
                feedbackArrayDetailed.joined(separator: "\n"),
                positiveFeedbackArray.joined(separator: "\n"),
                positiveFeedbackDetailed.joined(separator: "\n"),
                negativeHighlights + positiveHighlights
            )
            return
        }
        
        // ---------------------------------------------------------
        // MARK: - HIT SIDE (MODULAR HITTING-ARM DETECTION + DEBUG)
        // ---------------------------------------------------------
        if pose == "Hit side" {
            
            guard
                let leftWrist = joints[.leftWrist],
                let rightWrist = joints[.rightWrist],
                let leftElbow = joints[.leftElbow],
                let rightElbow = joints[.rightElbow],
                let leftShoulder = joints[.leftShoulder],
                let rightShoulder = joints[.rightShoulder],
                let leftHip = joints[.leftHip],
                let rightHip = joints[.rightHip]
            else {
                print("⚠️ [HIT SIDE] Missing required joints")
                return
            }
            
            // ---------------------------------------------------------
            // 1) Determine hitting arm (SIDE VIEW, MOMENT OF HIT)
            // ---------------------------------------------------------
            // Logic:
            // - At contact, the hitting wrist is LOWER than the non-hitting wrist
            // - And the hitting elbow is more EXTENDED (larger shoulder–elbow–wrist interior angle)
            // We combine both signals for robustness.
            
            let wristDeltaY = rightWrist.y - leftWrist.y   // >0 → right wrist lower
            let elbowExtensionScoreRight: Double
            let elbowExtensionScoreLeft: Double
            
            if
                let rightElbowAngle = calculateAngle(
                    from: joints,
                    joint1: .rightShoulder,
                    joint2: .rightElbow,
                    joint3: .rightWrist
                ),
                let leftElbowAngle = calculateAngle(
                    from: joints,
                    joint1: .leftShoulder,
                    joint2: .leftElbow,
                    joint3: .leftWrist
                )
            {
                let rightInterior = normalizedInteriorAngle(rightElbowAngle)
                let leftInterior = normalizedInteriorAngle(leftElbowAngle)
                
                elbowExtensionScoreRight = rightInterior
                elbowExtensionScoreLeft = leftInterior
            } else {
                print("⚠️ [HIT SIDE] Unable to compute elbow angles for hitter detection")
                return
            }
            
            print("""
                🎾 [HIT SIDE][DEBUG] Wrist Y — L: \(leftWrist.y) R: \(rightWrist.y) Δ=\(wristDeltaY)
                🎾 [HIT SIDE][DEBUG] Elbow interior — L: \(elbowExtensionScoreLeft) R: \(elbowExtensionScoreRight)
                """)
            
            let rightIsHitterScore =
            (wristDeltaY > 0 ? 1 : 0) +
            (elbowExtensionScoreRight > elbowExtensionScoreLeft ? 1 : 0)
            
            let isRightHitter = rightIsHitterScore >= 1
            
            print("🎾 [HIT SIDE] Detected hitting arm:",
                  isRightHitter ? "RIGHT" : "LEFT",
                  "(score:", rightIsHitterScore, ")")
            
            // ---------------------------------------------------------
            // 2) Resolve joints based on detected hitting arm
            // ---------------------------------------------------------
            let hitShoulderJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .rightShoulder : .leftShoulder
            let hitElbowJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .rightElbow : .leftElbow
            let hitWristJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .rightWrist : .leftWrist
            let hitHipJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .rightHip : .leftHip
            
            let nonHitShoulderJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .leftShoulder : .rightShoulder
            let nonHitWristJoint: VNHumanBodyPoseObservation.JointName =
            isRightHitter ? .leftWrist : .rightWrist
            
            // ---------------------------------------------------------
            // 3) Contact point timing (CORRECTED LOGIC)
            // ---------------------------------------------------------
            if let rawArmAngle = calculateAngle(
                from: joints,
                joint1: hitShoulderJoint,
                joint2: hitWristJoint,
                joint3: hitElbowJoint
            ) {
                let armAngle = normalizedInteriorAngle(rawArmAngle)
                
                print("📊 [HIT SIDE] Arm direction interior angle:", armAngle, "°")
                
                // INTERPRETATION:
                // 0°  → ideal straight-line contact
                // 0–15° → elite / pro range
                // 15–30° → acceptable
                // >30° → contact drifting off line
                
                if armAngle > 30 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "hit_side_contact_not_clean_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "hit_side_contact_not_clean_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [hitShoulderJoint, hitElbowJoint, hitWristJoint],
                            segments: [
                                (hitShoulderJoint, hitElbowJoint),
                                (hitElbowJoint, hitWristJoint)
                            ],
                            color: "orange"
                        )
                    )
                } else if armAngle <= 15 {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "hit_side_contact_excellent_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "hit_side_contact_excellent_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [hitShoulderJoint, hitElbowJoint, hitWristJoint],
                            segments: [
                                (hitShoulderJoint, hitElbowJoint),
                                (hitElbowJoint, hitWristJoint)
                            ],
                            color: "green"
                        )
                    )
                }
                else {
                    print("ℹ️ [HIT SIDE] Contact point in acceptable range")
                }
            }
            
            
            // ---------------------------------------------------------
            // 4) Hitting-arm extension at contact
            // ---------------------------------------------------------
            if let rawElbowAngle = calculateAngle(
                from: joints,
                joint1: hitShoulderJoint,
                joint2: hitElbowJoint,
                joint3: hitWristJoint
            ) {
                let interior = normalizedInteriorAngle(rawElbowAngle)
                let elbowBend = 180.0 - interior
                
                print("📊 [HIT SIDE] Elbow bend at contact:", elbowBend, "°")
                
                if elbowBend > 40 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "hit_side_arm_not_extended_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "hit_side_arm_not_extended_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [hitShoulderJoint, hitElbowJoint, hitWristJoint],
                            segments: [
                                (hitShoulderJoint, hitElbowJoint),
                                (hitElbowJoint, hitWristJoint)
                            ],
                            color: "orange"
                        )
                    )
                } else {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "hit_side_arm_extended_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "hit_side_arm_extended_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [hitShoulderJoint, hitElbowJoint, hitWristJoint],
                            segments: [
                                (hitShoulderJoint, hitElbowJoint),
                                (hitElbowJoint, hitWristJoint)
                            ],
                            color: "green"
                        )
                    )
                }
                
            }
            
            // ---------------------------------------------------------
            // 5) Upper-body alignment (hip–shoulder–wrist line)
            // ---------------------------------------------------------
            if let rawStretchAngle = calculateAngle(
                from: joints,
                joint1: hitHipJoint,
                joint2: hitShoulderJoint,
                joint3: hitWristJoint
            ) {
                // Interpret as deviation from a straight line (180°)
                let interior = normalizedInteriorAngle(rawStretchAngle)
                let deviationFromStraight = abs(180.0 - interior)
                
                print(
                    "📊 [HIT SIDE] Upper-body stretch raw =", rawStretchAngle,
                    "→ interior =", interior,
                    "→ deviationFromStraight =", deviationFromStraight, "°"
                )
                
                // PRO-TOLERANT MARGINS:
                // - <= 25°: good alignment (many pros are in 10–25° depending on style / camera)
                // - 25–40°: neutral (no feedback)
                // - > 40°: likely broken line / collapsing trunk
                if deviationFromStraight > 40 {
                    feedbackArray.append(
                        NSLocalizedString(
                            "hit_side_upper_body_misaligned_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "hit_side_upper_body_misaligned_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [hitHipJoint, hitShoulderJoint, hitWristJoint],
                            segments: [
                                (hitHipJoint, hitShoulderJoint),
                                (hitShoulderJoint, hitWristJoint)
                            ],
                            color: "orange"
                        )
                    )
                } else if deviationFromStraight <= 25 {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "hit_side_upper_body_aligned_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "hit_side_upper_body_aligned_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [hitHipJoint, hitShoulderJoint, hitWristJoint],
                            segments: [
                                (hitHipJoint, hitShoulderJoint),
                                (hitShoulderJoint, hitWristJoint)
                            ],
                            color: "green"
                        )
                    )
                }
                else {
                    print("ℹ️ [HIT SIDE] Upper-body alignment in neutral range")
                }
            }
            
            
            // ---------------------------------------------------------
            // 6) Non-hitting arm discipline
            // ---------------------------------------------------------
            if
                let nonHitShoulder = joints[nonHitShoulderJoint],
                let nonHitWrist = joints[nonHitWristJoint]
            {
                print("📊 [HIT SIDE] Non-hitting arm Y:",
                      "wrist =", nonHitWrist.y,
                      "shoulder =", nonHitShoulder.y)
                
                if nonHitWrist.y > nonHitShoulder.y {
                    feedbackArray.append(
                        NSLocalizedString(
                            "hit_side_non_hit_arm_high_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    feedbackArrayDetailed.append(
                        NSLocalizedString(
                            "hit_side_non_hit_arm_high_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    negativeHighlights.append(
                        HighlightInstruction(
                            joints: [nonHitShoulderJoint, nonHitWristJoint],
                            segments: [(nonHitShoulderJoint, nonHitWristJoint)],
                            color: "orange"
                        )
                    )
                } else {
                    positiveFeedbackArray.append(
                        NSLocalizedString(
                            "hit_side_non_hit_arm_good_title",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    positiveFeedbackDetailed.append(
                        NSLocalizedString(
                            "hit_side_non_hit_arm_good_detail",
                            tableName: "AICoach",
                            comment: ""
                        )
                    )
                    
                    positiveHighlights.append(
                        HighlightInstruction(
                            joints: [nonHitShoulderJoint, nonHitWristJoint],
                            segments: [(nonHitShoulderJoint, nonHitWristJoint)],
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
                negativeHighlights + positiveHighlights
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
    
    func normalizedInteriorAngle(_ angle: Double) -> Double {
        let a = abs(angle)
        return a > 180 ? 360 - a : a
    }
    
}


struct HighlightInstruction {
    let joints: [VNHumanBodyPoseObservation.JointName]
    let segments: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)]
    let color: String
}

