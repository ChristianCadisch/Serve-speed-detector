//
//  BackhandQuestions.swift
//  Clay Tennis
//
//

import Foundation

let backhandQuestions: [QuizQuestion] = [

    // MARK: - Backhand Fundamentals

    QuizQuestion(
        text: "Warum ist die Rückhand technisch besonders entscheidend?",
        type: .single,
        answers: [
            QuizAnswer(text: "Weil sie weniger wichtige Punkte entscheidet", isCorrect: false),
            QuizAnswer(text: "Weil sie über Kontrolle unter Druck entscheidet", isCorrect: true),
            QuizAnswer(text: "Weil sie nur im Defensivspiel gebraucht wird", isCorrect: false),
            QuizAnswer(text: "Weil sie weniger Kraft erfordert als die Vorhand", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was ist ein zentrales biomechanisches Prinzip der Rückhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Nur der Arm erzeugt die Schlagenergie", isCorrect: false),
            QuizAnswer(text: "Die Energie wird über die kinematische Kette vom Boden übertragen", isCorrect: true),
            QuizAnswer(text: "Der Schlag kommt ausschließlich aus dem Handgelenk", isCorrect: false),
            QuizAnswer(text: "Die Bewegung startet immer aus den Schultern", isCorrect: false)
        ]
    ),

    // MARK: - One-Handed vs Two-Handed

    QuizQuestion(
        text: "Was ist ein Hauptvorteil der einhändigen Rückhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Mehr Stabilität bei hohem Tempo", isCorrect: false),
            QuizAnswer(text: "Größere Reichweite und bessere Slice-Optionen", isCorrect: true),
            QuizAnswer(text: "Mehr Kraft durch beide Arme", isCorrect: false),
            QuizAnswer(text: "Weniger Timing erforderlich", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was kennzeichnet die beidhändige Rückhand?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Die obere Hand liefert den Großteil der Schlagkraft", isCorrect: true),
            QuizAnswer(text: "Die untere Hand stabilisiert die Bewegung", isCorrect: true),
            QuizAnswer(text: "Beide Arme arbeiten gleich stark", isCorrect: false),
            QuizAnswer(text: "Sie basiert auf der Vorhandbewegung der oberen Hand", isCorrect: true)
        ]
    ),

    // MARK: - Grip & Stance

    QuizQuestion(
        text: "Welcher Griff wird bei der einhändigen Rückhand empfohlen?",
        type: .single,
        answers: [
            QuizAnswer(text: "Kontinentalgriff", isCorrect: false),
            QuizAnswer(text: "Eastern-Rückhandgriff", isCorrect: true),
            QuizAnswer(text: "Semi-Western Griff", isCorrect: false),
            QuizAnswer(text: "Western Griff", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Stellung wird klassisch bei der Rückhand verwendet?",
        type: .single,
        answers: [
            QuizAnswer(text: "Offene Stellung", isCorrect: false),
            QuizAnswer(text: "Geschlossene Stellung", isCorrect: true),
            QuizAnswer(text: "Parallelstellung", isCorrect: false),
            QuizAnswer(text: "Frontale Stellung", isCorrect: false)
        ]
    ),

    // MARK: - Preparation & Shoulder Turn

    QuizQuestion(
        text: "Warum ist eine frühe Schulterdrehung bei der Rückhand wichtig?",
        type: .single,
        answers: [
            QuizAnswer(text: "Sie reduziert die Schlaggeschwindigkeit", isCorrect: false),
            QuizAnswer(text: "Sie speichert elastische Energie im Rumpf", isCorrect: true),
            QuizAnswer(text: "Sie ersetzt den Beinantrieb", isCorrect: false),
            QuizAnswer(text: "Sie verhindert den Ausschwung", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was ist das Ziel der Schläger-Vorbereitung bei der Rückhand?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Schläger kompakt und auf Kopfhöhe führen", isCorrect: true),
            QuizAnswer(text: "Zeit für die Schleifenbewegung schaffen", isCorrect: true),
            QuizAnswer(text: "Den Schläger erst kurz vor dem Treffer bewegen", isCorrect: false),
            QuizAnswer(text: "Die Vorspannung im Körper speichern", isCorrect: true)
        ]
    ),

    // MARK: - Loop & Swing Path

    QuizQuestion(
        text: "Was beschreibt die Schleife bei der Rückhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Der Schläger bewegt sich seitlich ohne Höhenänderung", isCorrect: false),
            QuizAnswer(text: "Der Schläger senkt sich unter den Ball vor der Beschleunigung", isCorrect: true),
            QuizAnswer(text: "Der Schläger bleibt während des gesamten Schlages oben", isCorrect: false),
            QuizAnswer(text: "Der Schläger stoppt vor dem Treffpunkt", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was bewirkt der Low-to-High-Schwung bei der Rückhand?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Topspin-Erzeugung", isCorrect: true),
            QuizAnswer(text: "Bessere Netzüberspielung", isCorrect: true),
            QuizAnswer(text: "Flachere Flugbahn ohne Rotation", isCorrect: false),
            QuizAnswer(text: "Stabilere Energieübertragung", isCorrect: true)
        ]
    ),

    // MARK: - Kinematic Chain & Legwork

    QuizQuestion(
        text: "Welche Rolle spielen die Beine bei der Rückhand?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Sie sorgen für Stabilität und Balance", isCorrect: true),
            QuizAnswer(text: "Sie leiten die Energieübertragung ein", isCorrect: true),
            QuizAnswer(text: "Sie haben keinen Einfluss auf Power", isCorrect: false),
            QuizAnswer(text: "Sie unterstützen die Rumpfrotation", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Warum ist ein tiefer Körperschwerpunkt bei der Rückhand wichtig?",
        type: .single,
        answers: [
            QuizAnswer(text: "Er erhöht die Ausholbewegung", isCorrect: false),
            QuizAnswer(text: "Er verbessert Gleichgewicht und Schlagstabilität", isCorrect: true),
            QuizAnswer(text: "Er reduziert die Reichweite", isCorrect: false),
            QuizAnswer(text: "Er verlangsamt den Schwung", isCorrect: false)
        ]
    ),

    // MARK: - Contact Point

    QuizQuestion(
        text: "Wo liegt der ideale Treffpunkt bei der Rückhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Direkt neben dem Körper", isCorrect: false),
            QuizAnswer(text: "Gut vor dem Körper auf Schulter- bis Hüfthöhe", isCorrect: true),
            QuizAnswer(text: "Hinter der Körperachse", isCorrect: false),
            QuizAnswer(text: "Über dem Kopf", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Probleme entstehen durch einen zu späten Treffpunkt?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Verlust von Kontrolle", isCorrect: true),
            QuizAnswer(text: "Reduktion der Schlagkraft", isCorrect: true),
            QuizAnswer(text: "Besserer Winkel für den Crossball", isCorrect: false),
            QuizAnswer(text: "Schlechtere Richtungssteuerung", isCorrect: true)
        ]
    ),

    // MARK: - One-Handed Specifics

    QuizQuestion(
        text: "Was ist für die einhändige Rückhand unmittelbar vor dem Treffpunkt entscheidend?",
        type: .single,
        answers: [
            QuizAnswer(text: "Ein stark gebeugter Arm", isCorrect: false),
            QuizAnswer(text: "Ein gestreckter Schlagarm und ein stabiles Handgelenk", isCorrect: true),
            QuizAnswer(text: "Ein lockeres Handgelenk ohne Spannung", isCorrect: false),
            QuizAnswer(text: "Ein Abbruch der Bewegung", isCorrect: false)
        ]
    ),

    // MARK: - Follow-Through & Errors

    QuizQuestion(
        text: "Was ist die Hauptfunktion des Ausschwungs bei der Rückhand?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Sicheres Abbremsen der Bewegung", isCorrect: true),
            QuizAnswer(text: "Unterstützung der Schlagrichtung", isCorrect: true),
            QuizAnswer(text: "Erzeugen zusätzlicher Rotation nach dem Treffpunkt", isCorrect: false),
            QuizAnswer(text: "Stabilisierung des Körpers", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Welcher Fehler ist typisch für eine instabile Rückhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Zu frühe Rotation des Oberkörpers", isCorrect: true),
            QuizAnswer(text: "Zu ruhiger Kopf", isCorrect: false),
            QuizAnswer(text: "Zu tiefe Beinstellung", isCorrect: false),
            QuizAnswer(text: "Zu lange Ausschwungphase", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Maßnahme hilft bei einer wackeligen oder unkontrollierten Rückhand am meisten?",
        type: .single,
        answers: [
            QuizAnswer(text: "Mehr Kraft im Arm", isCorrect: false),
            QuizAnswer(text: "Frühere Vorbereitung und bessere Beinarbeit", isCorrect: true),
            QuizAnswer(text: "Stärkeres Durchschwingen ohne Kontrolle", isCorrect: false),
            QuizAnswer(text: "Den Ball später treffen", isCorrect: false)
        ]
    )

]
