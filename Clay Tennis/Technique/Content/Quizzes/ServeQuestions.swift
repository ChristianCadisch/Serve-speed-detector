import Foundation

let serveQuestions: [QuizQuestion] = [

    QuizQuestion(
        text: "In the 'Trophy Position' phase of the serve, what is the correct orientation for the non-hitting hand?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "Resting on the opposite hip",
                isCorrect: false,
                explanation: "Dropping it early breaks balance and the upward flow"
            ),
            QuizAnswer(
                text: "Pointing towards the ball",
                isCorrect: true,
                explanation: "Pointing stabilizes balance, alignment, and timing"
            ),
            QuizAnswer(
                text: "Reaching back towards the fence",
                isCorrect: false,
                explanation: "Pulling back over-rotates the torso and reduces control"
            ),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "A common error for tennis players who struggle with the ball toss is throwing the ball too high, which tends to cause what issue?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "It ensures the racket drops fully behind the back",
                isCorrect: false,
                explanation: "A higher toss usually makes timing harder, not better"
            ),
            QuizAnswer(
                text: "It causes the ball to go all over the place",
                isCorrect: true,
                explanation: "A very high toss increases variability and timing errors"
            ),
            QuizAnswer(
                text: "It allows players to achieve full extension naturally",
                isCorrect: false,
                explanation: "Extension comes from mechanics, not toss height"
            ),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "Where should the racket ultimately finish in a natural, relaxed follow-through of the serve?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "Around the opposite shoulder",
                isCorrect: false,
                explanation: "This suggests a shortened or decelerated follow-through"
            ),
            QuizAnswer(
                text: "All the way to the left hip (for a right-handed player)",
                isCorrect: true,
                explanation: "A relaxed follow-through naturally ends across the body"
            ),
            QuizAnswer(
                text: "Stopping abruptly at waist height",
                isCorrect: false,
                explanation: "Abrupt stopping increases injury risk and stiffness"
            ),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "What grip do the majority of professional players use for the serve, often referred to as the chopper grip?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "Western Forehand Grip",
                isCorrect: false,
                explanation: "This closes the racket face and limits serve motion"
            ),
            QuizAnswer(
                text: "Eastern Backhand Grip",
                isCorrect: false,
                explanation: "Close, but not the standard serve grip"
            ),
            QuizAnswer(
                text: "Continental Grip",
                isCorrect: true,
                explanation: "This allows natural pronation and efficient power"
            ),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "What is a primary problem caused by using a typical forehand grip when serving?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "It increases net clearance excessively",
                isCorrect: false,
                explanation: "Net clearance isn’t the main issue"
            ),
            QuizAnswer(
                text: "It makes generating spin and maintaining accuracy very difficult",
                isCorrect: true,
                explanation: "A forehand grip blocks pronation and reduces control"
            ),
            QuizAnswer(
                text: "It causes the server to land on their back foot",
                isCorrect: false,
                explanation: "Landing issues are more about weight transfer"
            ),
        ],
        difficulty: .easy
    ),

    QuizQuestion(
        text: "During the serve motion, what specific action initiates the uncoiling of the shoulders and trunk from the trophy position, contributing to rotational power?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "The racket dropping fully behind the back",
                isCorrect: false,
                explanation: "The racket drop is a result, not the trigger"
            ),
            QuizAnswer(
                text: "The hitting elbow moving forward toward the ball",
                isCorrect: false,
                explanation: "The elbow follows rotation, it doesn’t start it"
            ),
            QuizAnswer(
                text: "The tossing hand pulling down and away from the contact point",
                isCorrect: true,
                explanation: "Pulling the tossing arm down starts shoulder rotation"
            ),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "A key feature of a good trophy position is having the hitting shoulder perform which action?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "The right shoulder (for a right-hander) dropped back and down",
                isCorrect: true,
                explanation: "This loads the upper body for power"
            ),
            QuizAnswer(
                text: "The hitting shoulder squared directly toward the net",
                isCorrect: false,
                explanation: "Squaring too early reduces stretch and power"
            ),
            QuizAnswer(
                text: "The left shoulder pushed forward towards the ball",
                isCorrect: false,
                explanation: "This happens later, not in the trophy position"
            ),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "If pronation is executed correctly, the movement continues past contact to the point of full pronation where the palm and strings face which side of the court?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "The left side of the court",
                isCorrect: false,
                explanation: "That’s the pre-contact supinated position"
            ),
            QuizAnswer(
                text: "The right side of the court",
                isCorrect: true,
                explanation: "Full pronation turns palm and strings right"
            ),
            QuizAnswer(
                text: "The back of the court",
                isCorrect: false,
                explanation: "A proper serve never finishes facing backwards"
            ),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "In the follow-through, why should the elbow be bent instead of straight when finishing the serve?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "A straight arm places a great deal of stress on the shoulder joint",
                isCorrect: true,
                explanation: "A bent arm absorbs force and reduces shoulder stress"
            ),
            QuizAnswer(
                text: "A straight arm reduces the overall arc of the swing",
                isCorrect: false,
                explanation: "Arc depends more on timing and rotation"
            ),
            QuizAnswer(
                text: "A straight arm prevents the body from rotating correctly",
                isCorrect: false,
                explanation: "Rotation is driven by legs and torso"
            ),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "What location is specified for the ball toss when a right-handed player executes a Kick Service (Topspin Serve)?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "In front and to the right (1-2 o’clock)",
                isCorrect: false,
                explanation: "This toss is typical for flat or slice serves"
            ),
            QuizAnswer(
                text: "Slightly behind the head (approximately 11 o’clock)",
                isCorrect: true,
                explanation: "A kick serve needs a slightly backward toss"
            ),
            QuizAnswer(
                text: "Directly above the head (12 o’clock)",
                isCorrect: false,
                explanation: "A straight overhead toss limits topspin"
            ),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "If a player pauses or breaks the swing, for example in the trophy position or racket drop position, what is the consequence concerning serve power?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "It allows for greater wrist snap",
                isCorrect: false,
                explanation: "Pausing breaks rhythm and reduces acceleration"
            ),
            QuizAnswer(
                text: "It helps in achieving the highest contact point",
                isCorrect: false,
                explanation: "Contact height comes from leg drive and timing"
            ),
            QuizAnswer(
                text: "Any momentum created up to that point is lost",
                isCorrect: true,
                explanation: "Pausing breaks the kinetic chain and kills momentum"
            ),
        ],
        difficulty: .medium
    ),

    QuizQuestion(
        text: "When utilizing the Continental grip, how should the forearm ideally move *prior* to contact (during supination) to allow the maximum 'whip' through the contact zone?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "The palm and strings face the left side of the court",
                isCorrect: true,
                explanation: "This loads the forearm for explosive pronation"
            ),
            QuizAnswer(
                text: "The palm faces the target",
                isCorrect: false,
                explanation: "Facing the target means pronation happened too early"
            ),
            QuizAnswer(
                text: "The palm and strings face the right side of the court",
                isCorrect: false,
                explanation: "This describes the post-contact position"
            ),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "What major biomechanical consequence results if a segment impulse is transferred prematurely or too late to the next link in the kinematic chain of the serve?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "The server is forced into a hybrid stance",
                isCorrect: false,
                explanation: "Stance change is not the main issue"
            ),
            QuizAnswer(
                text: "It leads to a coordinated disturbance, resulting in shots without quality or effect",
                isCorrect: true,
                explanation: "Mistimed transfer disrupts the kinetic chain"
            ),
            QuizAnswer(
                text: "It causes the player to release the toss too early",
                isCorrect: false,
                explanation: "Toss timing is unrelated to impulse sequencing"
            ),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "For a straight (flat) serve, what are the two subsequent actions involving the forearm and hand/wrist just before the moment of impact?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "A flexing of the elbow and upward pull of the wrist",
                isCorrect: false,
                explanation: "This is more of a pushing motion"
            ),
            QuizAnswer(
                text: "A stretching of the arm and backward rotation of the shoulder",
                isCorrect: false,
                explanation: "The shoulder doesn’t rotate backward before impact"
            ),
            QuizAnswer(
                text: "The forearm pronates (ausdrehen) followed by a tilting (abkippen) of the wrist/hand",
                isCorrect: true,
                explanation: "Pronation adds speed, wrist tilt fine-tunes direction"
            ),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "To ensure maximum relaxation and help the body avoid stiffening up during the powerful upswing phase, when is it recommended to start exhaling?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "At the moment of contact",
                isCorrect: false,
                explanation: "Exhaling only at contact is usually too late"
            ),
            QuizAnswer(
                text: "Just before the player starts the motion",
                isCorrect: false,
                explanation: "Exhaling too early can disrupt timing"
            ),
            QuizAnswer(
                text: "When reaching (passing through) the trophy position",
                isCorrect: true,
                explanation: "Starting here helps keep the body relaxed"
            ),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "What service preparation footwork sequence is listed for weight transfer (Gewichtsverlagerung) during the Ausholbewegung (backswing) phase of a straight serve (for a right-hander)?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "Right foot to left foot to right foot",
                isCorrect: false,
                explanation: "This doesn’t match the natural weight shift"
            ),
            QuizAnswer(
                text: "Left foot to right foot to left foot",
                isCorrect: true,
                explanation: "Weight shifts back, forward, then finishes front"
            ),
            QuizAnswer(
                text: "Both feet simultaneously lift off the ground",
                isCorrect: false,
                explanation: "Both feet don’t lift simultaneously in this phase"
            ),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "A common cause of breakdown and potential injury when swinging the racket at high speed through the contact zone is:",
        type: .single,
        answers: [
            QuizAnswer(
                text: "Failing to drop the right shoulder down and back",
                isCorrect: false,
                explanation: "This mainly reduces power, not health"
            ),
            QuizAnswer(
                text: "Tossing the ball too low, forcing a hurried motion",
                isCorrect: false,
                explanation: "A low toss mostly affects timing"
            ),
            QuizAnswer(
                text: "Suddenly stopping the swing or finishing in the wrong way",
                isCorrect: true,
                explanation: "Stopping the swing stresses the shoulder and elbow"
            ),
        ],
        difficulty: .hard
    ),

    QuizQuestion(
        text: "What specific technique did Pete Sampras occasionally use during the lifting phase of his service motion to ensure his grip pressure remained relaxed?",
        type: .single,
        answers: [
            QuizAnswer(
                text: "He rapidly squeezed and released the grip before tossing the ball",
                isCorrect: false,
                explanation: "This would increase tension instead of reducing it"
            ),
            QuizAnswer(
                text: "He rotated his wrist sharply inward just before contact",
                isCorrect: false,
                explanation: "That’s pronation, not a relaxation technique"
            ),
            QuizAnswer(
                text: "He released his pinky, ring, and middle fingers",
                isCorrect: true,
                explanation: "This helped him avoid gripping too tightly"
            ),
        ],
        difficulty: .hard
    )
]
