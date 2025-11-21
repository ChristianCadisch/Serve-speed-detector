//
//  ServeQuestions.swift
//  Clay Tennis
//
//

import Foundation

let serveQuestions: [QuizQuestion] = [

    // MARK: - Serve Fundamentals

    QuizQuestion(
        text: "Warum ist das Service einzigartig im Tennis?",
        type: .single,
        answers: [
            QuizAnswer(text: "Weil es der einzige Schlag ist, den du zu 100% kontrollierst", isCorrect: true),
            QuizAnswer(text: "Weil er immer mit maximaler Geschwindigkeit gespielt wird", isCorrect: false),
            QuizAnswer(text: "Weil nur Profispieler ihn richtig ausführen können", isCorrect: false),
            QuizAnswer(text: "Weil er keinen Einfluss auf den Punktverlauf hat", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Aussage beschreibt das Prinzip der kinematischen Kette im Service korrekt?",
        type: .single,
        answers: [
            QuizAnswer(text: "Die Bewegung beginnt im Arm und endet in den Beinen", isCorrect: false),
            QuizAnswer(text: "Die Bewegung läuft von unten nach oben: Beine → Hüfte → Rumpf → Schulter → Arm", isCorrect: true),
            QuizAnswer(text: "Nur der Arm ist für Geschwindigkeit verantwortlich", isCorrect: false),
            QuizAnswer(text: "Die Hüfte spielt beim Service keine Rolle", isCorrect: false)
        ]
    ),

    // MARK: - Grip & Stance

    QuizQuestion(
        text: "Welcher Griff ist die Grundlage für alle Aufschlagvarianten?",
        type: .single,
        answers: [
            QuizAnswer(text: "Eastern Vorhandgriff", isCorrect: false),
            QuizAnswer(text: "Semi-Western Griff", isCorrect: false),
            QuizAnswer(text: "Kontinentalgriff", isCorrect: true),
            QuizAnswer(text: "Western Griff", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum ist der Kontinentalgriff beim Service so wichtig?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Er erlaubt Flat-, Slice- und Kick-Services ohne Griffwechsel", isCorrect: true),
            QuizAnswer(text: "Er verhindert jegliche Pronation", isCorrect: false),
            QuizAnswer(text: "Er ermöglicht effiziente Pronation", isCorrect: true),
            QuizAnswer(text: "Er ist nur für Anfänger gedacht", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Wie sollte die Grundstellung beim Aufschlag sein?",
        type: .single,
        answers: [
            QuizAnswer(text: "Frontal zum Netz", isCorrect: false),
            QuizAnswer(text: "Seitlich zum Netz mit schulterbreitem Stand", isCorrect: true),
            QuizAnswer(text: "Beide Füße parallel zur Grundlinie", isCorrect: false),
            QuizAnswer(text: "Auf den Zehenspitzen stehend", isCorrect: false)
        ]
    ),

    // MARK: - Ball Toss & Preparation

    QuizQuestion(
        text: "Wo sollte sich der Ballwurf für ein flaches Service befinden?",
        type: .single,
        answers: [
            QuizAnswer(text: "Hinter dem Kopf", isCorrect: false),
            QuizAnswer(text: "Zwischen 12 und 13 Uhr leicht vor dem Körper", isCorrect: true),
            QuizAnswer(text: "Weit links vom Kopf", isCorrect: false),
            QuizAnswer(text: "Direkt über der Grundlinie", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum ist ein konstanter Ballwurf wichtiger als ein sehr hoher Ballwurf?",
        type: .single,
        answers: [
            QuizAnswer(text: "Weil Höhe beim Service keine Rolle spielt", isCorrect: false),
            QuizAnswer(text: "Weil ein konstanter Wurf die Kontrolle und den Rhythmus verbessert", isCorrect: true),
            QuizAnswer(text: "Weil Profis den Ball extra tief werfen", isCorrect: false),
            QuizAnswer(text: "Weil ein hoher Wurf automatisch mehr Geschwindigkeit erzeugt", isCorrect: false)
        ]
    ),

    // MARK: - Trophy Position & Racket Drop

    QuizQuestion(
        text: "Was kennzeichnet die optimale Trophy Position?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Wurfarm ist vollständig gestreckt", isCorrect: true),
            QuizAnswer(text: "Schlagarm-Ellenbogen zeigt nach oben", isCorrect: true),
            QuizAnswer(text: "Der Schläger ist bereits vor dem Körper", isCorrect: false),
            QuizAnswer(text: "Der Oberkörper ist aktiv gekippt", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Warum ist der Racket Drop (Back Scratch Position) so wichtig?",
        type: .single,
        answers: [
            QuizAnswer(text: "Er reduziert die Schwunglänge", isCorrect: false),
            QuizAnswer(text: "Er verkürzt die Beschleunigungsphase", isCorrect: false),
            QuizAnswer(text: "Er vergrößert den Beschleunigungsweg für maximale Geschwindigkeit", isCorrect: true),
            QuizAnswer(text: "Er dient nur der Show", isCorrect: false)
        ]
    ),

    // MARK: - Pronation & Contact

    QuizQuestion(
        text: "Was versteht man unter Pronation im Service?",
        type: .single,
        answers: [
            QuizAnswer(text: "Eine Beugung der Knie vor dem Absprung", isCorrect: false),
            QuizAnswer(text: "Eine Drehbewegung des Unterarms kurz vor dem Treffpunkt", isCorrect: true),
            QuizAnswer(text: "Ein seitliches Abkippen des Oberkörpers", isCorrect: false),
            QuizAnswer(text: "Eine Verlangsamung des Schlages", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum ist die Pronation im Service entscheidend?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Sie erhöht Schlägerkopfgeschwindigkeit", isCorrect: true),
            QuizAnswer(text: "Sie ermöglicht präzisere Ballkontrolle", isCorrect: true),
            QuizAnswer(text: "Sie verhindert jeglichen Spin", isCorrect: false),
            QuizAnswer(text: "Sie reduziert die Belastung für Schulter und Ellbogen", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Wo sollte der Treffpunkt beim Service idealerweise liegen?",
        type: .single,
        answers: [
            QuizAnswer(text: "Auf Hüfthöhe", isCorrect: false),
            QuizAnswer(text: "Leicht vor dem Körper und auf maximaler Streckung", isCorrect: true),
            QuizAnswer(text: "Hinter dem Kopf", isCorrect: false),
            QuizAnswer(text: "Direkt vor dem Gesicht", isCorrect: false)
        ]
    ),

    // MARK: - Serve Variants

    QuizQuestion(
        text: "Wodurch unterscheidet sich der Kick-Aufschlag vom Slice-Aufschlag?",
        type: .single,
        answers: [
            QuizAnswer(text: "Durch den Griffwechsel", isCorrect: false),
            QuizAnswer(text: "Durch den Ballwurf hinter dem Kopf und stärkeren Topspin", isCorrect: true),
            QuizAnswer(text: "Durch geringere Beinarbeit", isCorrect: false),
            QuizAnswer(text: "Durch fehlende Pronation", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Aussagen zum Slice-Service sind korrekt?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Der Ballwurf ist leicht nach rechts (bei Rechtshändern)", isCorrect: true),
            QuizAnswer(text: "Der Schläger streicht seitlich über den Ball", isCorrect: true),
            QuizAnswer(text: "Der Ball springt besonders hoch ab", isCorrect: false),
            QuizAnswer(text: "Er ist besonders effektiv auf der Einstandsseite", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Welches Ziel verfolgen Topspieler mit identischen Servicebewegungen für verschiedene Aufschläge?",
        type: .single,
        answers: [
            QuizAnswer(text: "Sie wollen den Gegner verwirren und Täuschung erzeugen", isCorrect: true),
            QuizAnswer(text: "Sie sparen Energie", isCorrect: false),
            QuizAnswer(text: "Sie vermeiden Rotation im Oberkörper", isCorrect: false),
            QuizAnswer(text: "Sie wechseln den Griff im letzten Moment", isCorrect: false)
        ]
    ),

    // MARK: - Stability & Errors

    QuizQuestion(
        text: "Was ist für das Gleichgewicht im Moment des Treffpunkts besonders wichtig?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Ruhige Kopfposition", isCorrect: true),
            QuizAnswer(text: "Aufrechter Oberkörper", isCorrect: true),
            QuizAnswer(text: "Extremes Vorlehnen", isCorrect: false),
            QuizAnswer(text: "Breite Standposition", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Welcher Fehler tritt häufig bei ineffizientem Service auf?",
        type: .single,
        answers: [
            QuizAnswer(text: "Zu frühe Pronation", isCorrect: false),
            QuizAnswer(text: "Zu spätes Einsetzen der Beine in die Bewegung", isCorrect: true),
            QuizAnswer(text: "Zu ruhiger Kopf", isCorrect: false),
            QuizAnswer(text: "Zu viel Einsatz der Hüfte", isCorrect: false)
        ]
    )

]
