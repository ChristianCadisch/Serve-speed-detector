import Foundation

let serveQuestions: [QuizQuestion] = [

    QuizQuestion(
    text: "What grip do the majority players use for the tennis serve?",
    type: .single,
    answers: [
    QuizAnswer(text: "Forehand grip", isCorrect: false, explanation: "Limits spin and control"),
    QuizAnswer(text: "Continental grip (Chopper grip)", isCorrect: true, explanation: "Best for power and spin"),
    QuizAnswer(text: "Extreme Western grip", isCorrect: false, explanation: "Not suitable for serving"),
    ],
    difficulty: .easy
    ),


    QuizQuestion(
    text: "To ensure a consistent ball toss on the serve, the ball should be released when the tossing hand reaches what height?",
    type: .single,
    answers: [
    QuizAnswer(text: "Shoulder height", isCorrect: false, explanation: "Too low for consistency"),
    QuizAnswer(text: "Head height", isCorrect: true, explanation: "Release at head height"),
    QuizAnswer(text: "The peak of the toss", isCorrect: false, explanation: "Release earlier than that"),
    ],
    difficulty: .easy
    ),


    QuizQuestion(
    text: "Where should the racket typically finish during a natural, relaxed follow-through for a right-handed server?",
    type: .single,
    answers: [
    QuizAnswer(text: "Over the left shoulder", isCorrect: false, explanation: "It goes lower"),
    QuizAnswer(text: "By the right knee", isCorrect: false, explanation: "It crosses the body"),
    QuizAnswer(text: "To the left hip", isCorrect: true, explanation: "A relaxed finish ends here"),
    ],
    difficulty: .easy
    ),


    QuizQuestion(
    text: "When reaching a good trophy position on the serve, what should the non-hitting hand be pointing towards?",
    type: .single,
    answers: [
    QuizAnswer(text: "The net", isCorrect: false, explanation: "It should track the toss"),
    QuizAnswer(text: "The ball", isCorrect: true, explanation: "Helps alignment and timing"),
    QuizAnswer(text: "The opponent's serving target", isCorrect: false, explanation: "Focus stays on the ball"),
    ],
    difficulty: .easy
    ),


    QuizQuestion(
    text: "For a consistent ball toss, how should the ball generally be held?",
    type: .single,
    answers: [
    QuizAnswer(text: "In the palm of your hand", isCorrect: false, explanation: "Too unstable"),
    QuizAnswer(text: "Only using the fingertips", isCorrect: false, explanation: "Not enough control"),
    QuizAnswer(text: "In your fingers (not fingertips)", isCorrect: true, explanation: "Gives better control"),
    ],
    difficulty: .easy
    ),


    QuizQuestion(
    text: "For a right-handed player hitting a Kick Service, where is the ball toss typically directed?",
    type: .single,
    answers: [
    QuizAnswer(text: "Slightly behind the head (around 11 o'clock)", isCorrect: true, explanation: "Classic kick toss spot"),
    QuizAnswer(text: "Far in front and to the right side", isCorrect: false, explanation: "That’s for slice"),
    QuizAnswer(text: "Directly in front of the baseline (around 12 to 13 o'clock)", isCorrect: false, explanation: "That’s for flat serves"),
    ],
    difficulty: .easy
    ),


    QuizQuestion(
    text: "For a consistent ball toss, how much higher than the ideal contact point should the ball be tossed?",
    type: .single,
    answers: [
    QuizAnswer(text: "Around 4-6 inches higher", isCorrect: true, explanation: "Slightly above contact"),
    QuizAnswer(text: "As high as possible to allow time to wind up", isCorrect: false, explanation: "Too high ruins rhythm"),
    QuizAnswer(text: "Exactly at the contact point height", isCorrect: false, explanation: "Needs extra height"),
    ],
    difficulty: .medium
    ),


    QuizQuestion(
    text: "Which of these is a required component of a good Trophy Position on the serve?",
    type: .single,
    answers: [
    QuizAnswer(text: "Racket head facing the ground", isCorrect: false, explanation: "It points up"),
    QuizAnswer(text: "A strong knee bend, ready to launch the body off the ground", isCorrect: true, explanation: "Legs load power"),
    QuizAnswer(text: "The right shoulder lifted high towards the head", isCorrect: false, explanation: "Shoulder drops back"),
    ],
    difficulty: .medium
    ),


    QuizQuestion(
    text: "Supination and pronation during the serve are only able to occur if the player is utilizing which specific grip?",
    type: .single,
    answers: [
    QuizAnswer(text: "A strong Eastern grip", isCorrect: false, explanation: "Prevents full rotation"),
    QuizAnswer(text: "The Continental grip", isCorrect: true, explanation: "Allows full rotation"),
    QuizAnswer(text: "A Forehand grip", isCorrect: false, explanation: "Limits spin generation"),
    ],
    difficulty: .medium
    ),


    QuizQuestion(
    text: "To avoid placing a great deal of stress on the shoulder joint during the serve follow-through, what action should occur?",
    type: .single,
    answers: [
    QuizAnswer(text: "The arm should remain completely straight throughout the finish", isCorrect: false, explanation: "This strains the shoulder"),
    QuizAnswer(text: "The elbow should be bent when finishing", isCorrect: true, explanation: "Reduces shoulder stress"),
    QuizAnswer(text: "The racket must be gripped tightly throughout the acceleration", isCorrect: false, explanation: "Grip should stay loose"),
    ],
    difficulty: .medium
    ),


    QuizQuestion(
    text: "For generating racket head speed, why do the biggest servers often use a continuous motion?",
    type: .single,
    answers: [
    QuizAnswer(text: "It ensures a perfectly straight arm at contact", isCorrect: false, explanation: "This isn’t the main reason"),
    QuizAnswer(text: "It allows the server to pause in the trophy position for perfect timing", isCorrect: false, explanation: "Pausing kills speed"),
    QuizAnswer(text: "It builds momentum that would otherwise be lost if the swing broke or paused", isCorrect: true, explanation: "Continuous flow keeps speed"),
    ],
    difficulty: .medium
    ),


    QuizQuestion(
    text: "What technique did Pete Sampras famously use during the lifting phase of his serve to ensure relaxed grip pressure?",
    type: .single,
    answers: [
    QuizAnswer(text: "He squeezed the grip tightly before every toss", isCorrect: false, explanation: "He stayed loose"),
    QuizAnswer(text: "He released his pinky, ring, and middle fingers during the lift into the trophy position", isCorrect: true, explanation: "This relaxed his grip"),
    QuizAnswer(text: "He exhaled sharply as he lifted the racket behind his head", isCorrect: false, explanation: "That’s for breathing"),
    ],
    difficulty: .hard
    ),


    QuizQuestion(
    text: "For a right-handed server using the Continental grip, when the forearm is in supination prior to contact, which direction should the palm of the hand and the strings initially face?",
    type: .single,
    answers: [
    QuizAnswer(text: "Towards the target/net", isCorrect: false, explanation: "That’s at contact"),
    QuizAnswer(text: "Towards the right side of the court", isCorrect: false, explanation: "That’s after pronation"),
    QuizAnswer(text: "Towards the left side of the court", isCorrect: true, explanation: "This is pre-contact"),
    ],
    difficulty: .hard
    ),


    QuizQuestion(
    text: "For the majority of tennis players (club and pro level), what is the typical timing duration from the start of the service motion until the contact point?",
    type: .single,
    answers: [
    QuizAnswer(text: "0.8 - 1.0 seconds", isCorrect: false, explanation: "Too fast for most"),
    QuizAnswer(text: "1.5 - 2.0 seconds", isCorrect: true, explanation: "Typical serve timing"),
    QuizAnswer(text: "2.5 - 3.0 seconds", isCorrect: false, explanation: "Too slow"),
    ],
    difficulty: .hard
    ),


    QuizQuestion(
    text: "What specific action initiates the uncoiling of the body from the trophy position, thereby maximizing rotational power?",
    type: .single,
    answers: [
    QuizAnswer(text: "The bending of the knees prior to the jump", isCorrect: false, explanation: "This loads power only"),
    QuizAnswer(text: "The tossing hand pulling down and away from the contact point", isCorrect: true, explanation: "This starts rotation"),
    QuizAnswer(text: "The serving arm reaching its furthest racket drop position", isCorrect: false, explanation: "That comes later"),
    ],
    difficulty: .hard
    ),

    QuizQuestion(
    text: "For a right-handed player executing a Slice Service, what occurs regarding the forearm and wrist at contact?",
    type: .single,
    answers: [
    QuizAnswer(text: "Ulnar flexion of the wrist and internal rotation of the forearm", isCorrect: true, explanation: "This creates slice"),
    QuizAnswer(text: "Ulnar flexion of the wrist and external rotation of the forearm", isCorrect: false, explanation: "That’s for kick"),
    QuizAnswer(text: "Radial flexion of the wrist and supination of the forearm", isCorrect: false, explanation: "Wrong mechanics"),
    ],
    difficulty: .hard
    ),

    QuizQuestion(
    text: "A major advantage gained by players who utilize a low ball toss is that it forces them to do what?",
    type: .single,
    answers: [
    QuizAnswer(text: "Slow down their motion to ensure they hit the ball at the apex", isCorrect: false, explanation: "It does the opposite"),
    QuizAnswer(text: "Increase the accuracy of their pronation snap", isCorrect: false, explanation: "That’s not the key effect"),
    QuizAnswer(text: "Speed up their motion to make contact at their ideal height", isCorrect: true, explanation: "A low toss forces speed"),
    ],
    difficulty: .hard
    ),

    QuizQuestion(
    text: "To ensure the body is relaxed and maximize power, when should the server typically start exhaling during the service motion?",
    type: .single,
    answers: [
    QuizAnswer(text: "Start the exhale when reaching the trophy position", isCorrect: true, explanation: "Helps stay relaxed"),
    QuizAnswer(text: "Hold the breath until after the ball contact", isCorrect: false, explanation: "Causes tension"),
    QuizAnswer(text: "Start the exhale at the moment the ball is released from the tossing hand", isCorrect: false, explanation: "Too early"),
    ],
    difficulty: .hard
    )
]
