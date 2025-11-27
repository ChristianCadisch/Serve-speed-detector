//
//  BackhandQuestions.swift
//  Clay Tennis
//
//

import Foundation




let backhandQuestions: [QuizQuestion] = [

    // EASY (7)
    question("backhand_q1",  difficulty: .easy,   correctIndex: 2, answerCount: 3),
    question("backhand_q2",  difficulty: .easy,   correctIndex: 2, answerCount: 3),
    question("backhand_q3",  difficulty: .easy,   correctIndex: 2, answerCount: 3),
    question("backhand_q4",  difficulty: .easy,   correctIndex: 1, answerCount: 3),
    question("backhand_q5",  difficulty: .easy,   correctIndex: 3, answerCount: 3),
    question("backhand_q6",  difficulty: .easy,   correctIndex: 1, answerCount: 3),
    question("backhand_q7",  difficulty: .easy,   correctIndex: 3, answerCount: 3),

    // MEDIUM (7)
    question("backhand_q8",  difficulty: .medium, correctIndex: 2, answerCount: 3),
    question("backhand_q9",  difficulty: .medium, correctIndex: 2, answerCount: 3),
    question("backhand_q10", difficulty: .medium, correctIndex: 2, answerCount: 3),
    question("backhand_q11", difficulty: .medium, correctIndex: 3, answerCount: 3),
    question("backhand_q12", difficulty: .medium, correctIndex: 2, answerCount: 3),
    question("backhand_q13", difficulty: .medium, correctIndex: 2, answerCount: 3),
    question("backhand_q14", difficulty: .medium, correctIndex: 1, answerCount: 3),

    // HARD (6)
    question("backhand_q15", difficulty: .hard,   correctIndex: 3, answerCount: 3),
    question("backhand_q16", difficulty: .hard,   correctIndex: 2, answerCount: 3),
    question("backhand_q17", difficulty: .hard,   correctIndex: 3, answerCount: 3),
    question("backhand_q18", difficulty: .hard,   correctIndex: 2, answerCount: 3),
    question("backhand_q19", difficulty: .hard,   correctIndex: 2, answerCount: 3),
    question("backhand_q20", difficulty: .hard,   correctIndex: 1, answerCount: 3),
]



/*
let backhandQuestions: [QuizQuestion] = [
    
    QuizQuestion(
        text: "What grip is recommended for hitting an aggressive topspin one-handed backhand, as used by players like Roger Federer and Stan Wawrinka?",
        type: .single,
        answers: [
            QuizAnswer(text: "Continental Grip", isCorrect: false, explanation: "Mainly used for slices, volleys, and serves"),
            QuizAnswer(text: "Eastern Backhand Grip (Extremer RH Griff)", isCorrect: true, explanation: "Ideal for aggressive topspin on the one-handed backhand"),
            QuizAnswer(text: "Semi-Western Forehand Grip", isCorrect: false, explanation: "This grip is used for forehands"),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "What is the primary action a right-handed player should take immediately after recognizing a ball coming to the backhand side?",
        type: .single,
        answers: [
            QuizAnswer(text: "Extend the arm toward the target", isCorrect: false, explanation: "Arm extension happens later, near contact"),
            QuizAnswer(text: "Turn the upper body sideways to the net, pointing the right shoulder toward the net", isCorrect: true, explanation: "You should turn sideways immediately after reading the shot"),
            QuizAnswer(text: "Shift the body weight onto the front foot", isCorrect: false, explanation: "Weight transfer happens later in the swing"),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "Where should a player aim to make contact with the ball when executing a one-handed or two-handed backhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Behind the hip, close to the body", isCorrect: false, explanation: "Contacting too close reduces control"),
            QuizAnswer(text: "Out in front of the body", isCorrect: true, explanation: "Correct contact point is in front of the body"),
            QuizAnswer(text: "Directly beside the body, near the front foot", isCorrect: false, explanation: "This causes poor energy transfer"),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "What is the goal of utilizing a low-to-high swing path on a backhand groundstroke?",
        type: .single,
        answers: [
            QuizAnswer(text: "To generate topspin and lift the ball into the court", isCorrect: true, explanation: "This swing brushes up to create topspin"),
            QuizAnswer(text: "To achieve a flat, powerful winner", isCorrect: false, explanation: "A flat shot uses a different path"),
            QuizAnswer(text: "To shorten the follow-through and reduce injury", isCorrect: false, explanation: "A full follow-through helps prevent injury"),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "What is a common trait of a good power position for both one-handed and two-handed backhands?",
        type: .single,
        answers: [
            QuizAnswer(text: "The racket head is lower than the grip level", isCorrect: false, explanation: "The racket head should be higher"),
            QuizAnswer(text: "The shoulders are relaxed and facing the side fence", isCorrect: false, explanation: "The shoulders should be fully coiled"),
            QuizAnswer(text: "The racket head is higher than the grip level", isCorrect: true, explanation: "A higher racket head creates better leverage"),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "For a right-handed player using a two-handed backhand, which grip is recommended for the top hand (the left hand)?",
        type: .single,
        answers: [
            QuizAnswer(text: "An Eastern forehand grip or Semi-western grip", isCorrect: true, explanation: "The top hand drives the stroke like a forehand"),
            QuizAnswer(text: "A Continental grip", isCorrect: false, explanation: "This is usually used by the bottom hand"),
            QuizAnswer(text: "A Hammer grip", isCorrect: false, explanation: "This grip is used for serves and volleys"),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "During the unit turn on the backhand, if the player coils their upper body without moving their arms, where does the racket move from the initial 12 o'clock position (facing the net)?",
        type: .single,
        answers: [
            QuizAnswer(text: "To a 6 o'clock position (facing the ground)", isCorrect: false, explanation: "This is not part of the backhand coil"),
            QuizAnswer(text: "To a 3 o'clock position (facing the right side of the court)", isCorrect: false, explanation: "This is typical for forehand coils"),
            QuizAnswer(text: "To a 9 o'clock position (facing the left side of the court)", isCorrect: true, explanation: "A pure upper-body coil rotates it to 9 o'clock"),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "Why is using an Eastern backhand grip on the bottom hand discouraged for a two-handed backhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "It causes excessive wrist strain", isCorrect: false, explanation: "The main issue is shot flatness, not strain"),
            QuizAnswer(text: "It makes it very hard to flatten out the backhand and truly hit through the shot", isCorrect: true, explanation: "This grip limits your ability to drive the ball"),
            QuizAnswer(text: "It prevents the top hand from dominating the stroke", isCorrect: false, explanation: "The problem is flattening, not hand dominance"),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "To ensure proper topspin generation on a one-handed backhand, where should the racket head generally finish?",
        type: .single,
        answers: [
            QuizAnswer(text: "At waist height, pointed toward the opposite corner", isCorrect: false, explanation: "The finish should be much higher"),
            QuizAnswer(text: "High, around shoulder or head height", isCorrect: true, explanation: "A high finish ensures upward brushing"),
            QuizAnswer(text: "Low, near the left pocket, with the arm relaxed", isCorrect: false, explanation: "The racket should not finish low"),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "In the preparation phase (Ausholbewegung), in what direction does the kinematic chain movement flow?",
        type: .single,
        answers: [
            QuizAnswer(text: "From the bottom up", isCorrect: false, explanation: "That happens during the hitting phase"),
            QuizAnswer(text: "From the top down", isCorrect: true, explanation: "The preparation starts from the upper body"),
            QuizAnswer(text: "Horizontally, parallel to the baseline", isCorrect: false, explanation: "The movement is vertical/diagonal"),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "In the execution of a two-handed backhand, which hand primarily dominates the movement?",
        type: .single,
        answers: [
            QuizAnswer(text: "The bottom (right) hand", isCorrect: false, explanation: "It mainly stabilizes"),
            QuizAnswer(text: "The bottom (right) hand ensures wrist fixation", isCorrect: false, explanation: "Stability is secondary"),
            QuizAnswer(text: "The upper (left) hand, which executes a forehand-like movement", isCorrect: true, explanation: "The top hand provides most of the power"),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "Why should the arm be almost fully extended at the contact point on a one-handed backhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "To maximize racket head lag", isCorrect: false, explanation: "Lag is discussed more for forehands"),
            QuizAnswer(text: "To absorb incoming ball pace", isCorrect: false, explanation: "This can reduce stability"),
            QuizAnswer(text: "To ensure firmness and optimal energy transfer", isCorrect: true, explanation: "Extension stabilizes contact and transfers power"),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "What is a key benefit of executing the unit turn early on the backhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "It delays the opponent’s read", isCorrect: false, explanation: "The benefit is movement efficiency"),
            QuizAnswer(text: "It allows normal running steps instead of slow side steps", isCorrect: true, explanation: "Early turn allows faster positioning"),
            QuizAnswer(text: "It stores weight mainly on the front leg", isCorrect: false, explanation: "Weight is stored on the back leg"),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "What is the recommended height for both elbows after a two-handed backhand finish?",
        type: .single,
        answers: [
            QuizAnswer(text: "Around shoulder level", isCorrect: true, explanation: "Both elbows should finish high"),
            QuizAnswer(text: "At waist height, close to the body", isCorrect: false, explanation: "Finishing too low blocks the follow-through"),
            QuizAnswer(text: "Touching the back", isCorrect: false, explanation: "Only the racket head may touch the back"),
        ],
        difficulty: .medium
    ),


    QuizQuestion(
        text: "When should elite players begin the coil motion during a backhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "After the ball crosses the net", isCorrect: false, explanation: "Top players start much earlier"),
            QuizAnswer(text: "Just before contact", isCorrect: false, explanation: "The coil is done during preparation"),
            QuizAnswer(text: "Almost as soon as the ball leaves the opponent’s strings", isCorrect: true, explanation: "Elite players start the coil immediately"),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "During the contact zone, what should the racket be doing?",
        type: .single,
        answers: [
            QuizAnswer(text: "Slowing down slightly", isCorrect: false, explanation: "It should not decelerate"),
            QuizAnswer(text: "Accelerating with good speed", isCorrect: true, explanation: "The racket should accelerate through contact"),
            QuizAnswer(text: "Pausing briefly for wrist fixation", isCorrect: false, explanation: "Pausing kills momentum"),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "What is the core function of the Power Position in the backhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "To lower the racket head for topspin", isCorrect: false, explanation: "The racket head should be higher"),
            QuizAnswer(text: "To guarantee racket lag", isCorrect: false, explanation: "Lag is mainly discussed for forehands"),
            QuizAnswer(text: "To allow power generation even after a brief pause", isCorrect: true, explanation: "It stores power even if you stop momentarily"),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "What crucial role does a complete follow-through play in the backhand stroke?",
        type: .single,
        answers: [
            QuizAnswer(text: "To keep balance before recovering", isCorrect: false, explanation: "The main focus is injury prevention"),
            QuizAnswer(text: "To help muscles relax and reduce injury risk", isCorrect: true, explanation: "A good follow-through protects your body"),
            QuizAnswer(text: "To increase recovery time", isCorrect: false, explanation: "Its role is biomechanical, not temporal"),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "During the finish of a one-handed backhand, what should the non-hitting hand do?",
        type: .single,
        answers: [
            QuizAnswer(text: "Swing forward across the body", isCorrect: false, explanation: "It acts as a counterbalance"),
            QuizAnswer(text: "Stay by the left pocket or pull back and down", isCorrect: true, explanation: "It balances the upward swing of the hitting arm"),
            QuizAnswer(text: "Hold the throat of the racket", isCorrect: false, explanation: "That happens earlier in preparation"),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "Which common error blocks the follow-through on a two-handed backhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Finishing with the top hand too far overhead", isCorrect: false, explanation: "The key issue is the bottom elbow"),
            QuizAnswer(text: "Finishing too low with the bottom elbow", isCorrect: true, explanation: "A low elbow blocks the swing path"),
            QuizAnswer(text: "Not letting the racket touch the back", isCorrect: false, explanation: "This is only a visual guide"),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "How is the kinetic chain resolved during the hitting phase of the backhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "From bottom to top", isCorrect: true, explanation: "Power flows upward through the body"),
            QuizAnswer(text: "From top to bottom", isCorrect: false, explanation: "That happens during preparation"),
            QuizAnswer(text: "Simultaneously across all limbs", isCorrect: false, explanation: "The chain works in sequence"),
        ],
        difficulty: .hard
    )


*/


