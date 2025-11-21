//
//  TacticsQuestions.swift
//  Clay Tennis
//
//  Generated from: Player Development – Grundlagen Taktik und Technik (Swiss Tennis)
//

import Foundation

let tacticsQuestions: [QuizQuestion] = [

    // MARK: - 5 Basis-Spielsituationen
    QuizQuestion(
        text: "Welche der folgenden Optionen gehört NICHT zu den 5 Basis-Spielsituationen?",
        type: .single,
        answers: [
            QuizAnswer(text: "Returnieren", isCorrect: false),
            QuizAnswer(text: "Angreifen", isCorrect: false),
            QuizAnswer(text: "Passieren", isCorrect: false),
            QuizAnswer(text: "Serve & Volley", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Wozu dienen die 5 Basis-Spielsituationen?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Zur Bewertung der Aktionen eines Spielers", isCorrect: true),
            QuizAnswer(text: "Zur technischen Analyse isolierter Bewegungen", isCorrect: false),
            QuizAnswer(text: "Zur Beschreibung der Spielsituation statt einzelner Schläge", isCorrect: true),
            QuizAnswer(text: "Zum Festlegen von Griffhaltungen", isCorrect: false)
        ]
    ),
    

    // MARK: - Tennisspielen ist Handeln
    QuizQuestion(
        text: "Was zeigt das Prinzip 'Tennisspielen ist handeln'?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Fehler entstehen oft durch schlechte Wahrnehmung oder falsche Schlagwahl", isCorrect: true),
            QuizAnswer(text: "Technik ist immer der Hauptgrund für Fehler", isCorrect: false),
            QuizAnswer(text: "Analyse umfasst Aufnehmen – Verarbeiten – Umsetzen – Auswerten", isCorrect: true),
            QuizAnswer(text: "Schlagtechnik ist wichtiger als Entscheidung", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Woran kann es liegen, wenn ein Spieler viele kurze Bälle ins Aus spielt?",
        type: .single,
        answers: [
            QuizAnswer(text: "Schlechte Wahrnehmung oder falsche Flugbahneinschätzung", isCorrect: true),
            QuizAnswer(text: "Immer ein technischer Fehler im Schwung", isCorrect: false),
            QuizAnswer(text: "Eine unpassende Griffhaltung", isCorrect: false),
            QuizAnswer(text: "Zu viel Topspin", isCorrect: false)
        ]
    ),

    // MARK: - Flugbahnen und erreichbare Zonen
    QuizQuestion(
        text: "Wovon sind Flugbahnen im Tennis abhängig?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Bodenbeschaffenheit", isCorrect: true),
            QuizAnswer(text: "Höhe über Meer", isCorrect: true),
            QuizAnswer(text: "Rotation und Geschwindigkeit des Balles", isCorrect: true),
            QuizAnswer(text: "Schlägerfarbe", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Ein Spieler steht auf Position 1 und möchte Ziel E anspielen. Was muss stimmen?",
        type: .single,
        answers: [
            QuizAnswer(text: "Die Flugbahn braucht eine ausreichende Höhe", isCorrect: true),
            QuizAnswer(text: "Der Spieler muss immer longline spielen", isCorrect: false),
            QuizAnswer(text: "Der Schlag muss ohne Drall erfolgen", isCorrect: false),
            QuizAnswer(text: "Die Schlaggeschwindigkeit ist unwichtig", isCorrect: false)
        ]
    ),

    // MARK: - Prinzip der Winkelhalbierenden
    QuizQuestion(
        text: "Was sagt das Prinzip der Winkelhalbierenden aus?",
        type: .single,
        answers: [
            QuizAnswer(text: "Man sollte sich auf der Winkelhalbierenden möglicher gegnerischer Flugbahnen positionieren", isCorrect: true),
            QuizAnswer(text: "Man sollte den Ball immer cross spielen", isCorrect: false),
            QuizAnswer(text: "Die Laufwege sind unwichtig", isCorrect: false),
            QuizAnswer(text: "Man sollte nach jedem Schlag an die Grundlinie zurücklaufen", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Aktion ist ein Beispiel für die Anwendung der Winkelhalbierenden?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Nach einer FH longline leicht über das Mittelzeichen hinaus rücken", isCorrect: true),
            QuizAnswer(text: "Nach einem Angriffsschlag dem Ball hinterherlaufen", isCorrect: true),
            QuizAnswer(text: "Nach jedem Schlag automatisch die Platzmitte ansteuern", isCorrect: false),
            QuizAnswer(text: "Immer in der Nähe der Seitenlinie stehen bleiben", isCorrect: false)
        ]
    ),

    // MARK: - Ampelprinzip Rot–Gelb–Grün
    QuizQuestion(
        text: "Was kennzeichnet die rote Situation im Ampelprinzip?",
        type: .single,
        answers: [
            QuizAnswer(text: "Der Spieler ist unter Druck und spielt defensiv zurück", isCorrect: true),
            QuizAnswer(text: "Der Spieler ist in guter Position für einen Winner", isCorrect: false),
            QuizAnswer(text: "Der Spieler versucht aktiv Druck aufzubauen", isCorrect: false),
            QuizAnswer(text: "Der Spieler hat viel Zeit und Raum", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Aussagen zum Ampelprinzip treffen zu?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Gelb bedeutet, dass der Spieler versucht eine grüne Situation zu schaffen", isCorrect: true),
            QuizAnswer(text: "Grün ist die Situation zum Punktabschluss", isCorrect: true),
            QuizAnswer(text: "Rot bedeutet: Offensive mit vollem Risiko", isCorrect: false),
            QuizAnswer(text: "Die Einschätzung hängt von eigenen Fähigkeiten und Gegner ab", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Was wäre ein typischer Fehler in einer roten Situation?",
        type: .single,
        answers: [
            QuizAnswer(text: "Aus einer defensiven Position einen Winner versuchen", isCorrect: true),
            QuizAnswer(text: "Einen hohen langen Ball cross spielen, um Zeit zu gewinnen", isCorrect: false),
            QuizAnswer(text: "Den Ball sicher tief zurückspielen", isCorrect: false),
            QuizAnswer(text: "In Richtung Winkelhalbierende laufen", isCorrect: false)
        ]
    )
    
    
]



import SwiftUI

struct TacticsQuestions_Preview: PreviewProvider {
    static var previews: some View {
        QuizView(
            vm: QuizViewModel(questions: tacticsQuestions),
            onFinish: { }
        )
    }
}

