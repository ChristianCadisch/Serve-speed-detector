//
//  ForehandQuestions.swift
//  Clay Tennis
//
//

import Foundation

let forehandQuestions: [QuizQuestion] = [

    // MARK: - Forehand Fundamentals

    QuizQuestion(
        text: "Warum gilt die Vorhand als Hauptangriffsschlag?",
        type: .single,
        answers: [
            QuizAnswer(text: "Sie ist technisch am einfachsten", isCorrect: false),
            QuizAnswer(text: "Sie bestimmt Tempo, Druck und Punktaufbau", isCorrect: true),
            QuizAnswer(text: "Sie wird nur defensiv gespielt", isCorrect: false),
            QuizAnswer(text: "Sie wird nur im Doppel eingesetzt", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum ist die Vorhand eine Ganzkörperbewegung?",
        type: .single,
        answers: [
            QuizAnswer(text: "Weil nur die Beine Kraft erzeugen", isCorrect: false),
            QuizAnswer(text: "Weil nur das Handgelenk entscheidend ist", isCorrect: false),
            QuizAnswer(text: "Weil die Kraft über die kinematische Kette vom Boden bis zum Schläger übertragen wird", isCorrect: true),
            QuizAnswer(text: "Weil der Oberkörper sich nicht bewegen darf", isCorrect: false)
        ]
    ),

    // MARK: - Grip & Stance

    QuizQuestion(
        text: "Welche Griffarten werden am häufigsten für die Vorhand verwendet?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Eastern Griff", isCorrect: true),
            QuizAnswer(text: "Semi-Western Griff", isCorrect: true),
            QuizAnswer(text: "Kontinentalgriff", isCorrect: false),
            QuizAnswer(text: "Extreme Western Griff", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum können extreme Vorhandgriffe problematisch sein?",
        type: .single,
        answers: [
            QuizAnswer(text: "Sie sind zu einfach zu erlernen", isCorrect: false),
            QuizAnswer(text: "Sie erschweren flache Schläge und Anpassungsfähigkeit", isCorrect: true),
            QuizAnswer(text: "Sie erzeugen zu wenig Topspin", isCorrect: false),
            QuizAnswer(text: "Sie verbessern die Schlaggenauigkeit", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Aussage zu den Schlagstellungen bei der Vorhand trifft zu?",
        type: .single,
        answers: [
            QuizAnswer(text: "Die geschlossene Stellung ist immer falsch", isCorrect: false),
            QuizAnswer(text: "Offene Stellung hilft besonders unter Zeitdruck", isCorrect: true),
            QuizAnswer(text: "Man darf nur halb-offen spielen", isCorrect: false),
            QuizAnswer(text: "Die Stellung beeinflusst den Schlag nicht", isCorrect: false)
        ]
    ),

    // MARK: - Preparation & Loop

    QuizQuestion(
        text: "Warum ist eine frühe Schulterrotation in der Vorbereitung wichtig?",
        type: .single,
        answers: [
            QuizAnswer(text: "Sie verzögert den Schlag", isCorrect: false),
            QuizAnswer(text: "Sie erzeugt Vorspannung und speichert Energie", isCorrect: true),
            QuizAnswer(text: "Sie reduziert die Schlägerkopfgeschwindigkeit", isCorrect: false),
            QuizAnswer(text: "Sie hat keinen Einfluss auf den Treffpunkt", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was beschreibt die Schleifenbewegung (Loop) bei der Vorhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Ein Rückwärtsziehen des Schlägers nach dem Treffpunkt", isCorrect: false),
            QuizAnswer(text: "Ein Absenken des Schlägers unter den Ball vor der Beschleunigung", isCorrect: true),
            QuizAnswer(text: "Ein seitliches Schwenken des Schlägers", isCorrect: false),
            QuizAnswer(text: "Ein Stoppen des Schlages vor dem Kontakt", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welchen Zweck erfüllt die Schleife bei der Vorhand?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Sie verlängert den Beschleunigungsweg", isCorrect: true),
            QuizAnswer(text: "Sie ermöglicht mehr Topspin", isCorrect: true),
            QuizAnswer(text: "Sie vermindert die Kontrolle", isCorrect: false),
            QuizAnswer(text: "Sie verbessert die Schlägerkopfbeschleunigung", isCorrect: true)
        ]
    ),

    // MARK: - Kinematic Chain & Leg Drive

    QuizQuestion(
        text: "In welcher Reihenfolge arbeitet die kinematische Kette bei der Vorhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Arm → Schulter → Beine", isCorrect: false),
            QuizAnswer(text: "Beine → Hüfte → Rumpf → Schulter → Arm → Handgelenk", isCorrect: true),
            QuizAnswer(text: "Schulter → Handgelenk → Beine", isCorrect: false),
            QuizAnswer(text: "Nur der Arm ist beteiligt", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum ist der Beinantrieb für die Vorhand entscheidend?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Er sorgt für Stabilität im Treffpunkt", isCorrect: true),
            QuizAnswer(text: "Er erhöht die Schlägerkopfgeschwindigkeit", isCorrect: true),
            QuizAnswer(text: "Er verhindert jegliche Rotation", isCorrect: false),
            QuizAnswer(text: "Er unterstützt die Energieübertragung nach oben", isCorrect: true)
        ]
    ),

    // MARK: - Contact Point & Swing Path

    QuizQuestion(
        text: "Wo liegt der ideale Treffpunkt bei der Vorhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Direkt neben dem Körper", isCorrect: false),
            QuizAnswer(text: "Hinter dem Körper", isCorrect: false),
            QuizAnswer(text: "Vor dem Körper zwischen Hüfte und Schulterhöhe", isCorrect: true),
            QuizAnswer(text: "Über dem Kopf", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum führt ein zu später Treffpunkt zu Problemen?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Er verringert Kontrolle", isCorrect: true),
            QuizAnswer(text: "Er reduziert Schlagkraft", isCorrect: true),
            QuizAnswer(text: "Er erhöht automatisch den Topspin", isCorrect: false),
            QuizAnswer(text: "Er erschwert die Richtungssteuerung", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Was bedeutet das Prinzip 'low to high' bei der Vorhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Der Schläger bewegt sich von oben nach unten", isCorrect: false),
            QuizAnswer(text: "Der Schläger beschleunigt von unterhalb des Balles nach oben durch den Treffpunkt", isCorrect: true),
            QuizAnswer(text: "Der Ball wird möglichst flach gespielt", isCorrect: false),
            QuizAnswer(text: "Nur für Slice relevant", isCorrect: false)
        ]
    ),

    // MARK: - Stability & Follow Through

    QuizQuestion(
        text: "Warum ist eine stabile Kopfhaltung während der Vorhand wichtig?",
        type: .single,
        answers: [
            QuizAnswer(text: "Sie erhöht automatisch die Schlagkraft", isCorrect: false),
            QuizAnswer(text: "Sie verbessert Gleichgewicht, Timing und Präzision", isCorrect: true),
            QuizAnswer(text: "Sie hat nur mentale Bedeutung", isCorrect: false),
            QuizAnswer(text: "Sie beeinflusst nur den Rückhandschlag", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was ist die Funktion des Ausschwungs bei der Vorhand?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Sanfte Abbremsung der Bewegung", isCorrect: true),
            QuizAnswer(text: "Unterstützung der Richtungssteuerung", isCorrect: true),
            QuizAnswer(text: "Verkürzung der Schlagbewegung", isCorrect: false),
            QuizAnswer(text: "Stabilisierung des Körpers nach dem Treffpunkt", isCorrect: true)
        ]
    ),

    // MARK: - Errors & Training

    QuizQuestion(
        text: "Welcher Fehler tritt häufig bei einer schlechten Vorhand auf?",
        type: .single,
        answers: [
            QuizAnswer(text: "Zu frühes Treffen des Balles", isCorrect: false),
            QuizAnswer(text: "Steifer Arm ohne ausreichende Körperrotation", isCorrect: true),
            QuizAnswer(text: "Zu ruhiger Kopf", isCorrect: false),
            QuizAnswer(text: "Zu aktive Beinbewegung", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was ist laut den Technikprinzipien besonders wichtig beim Trainieren der Vorhand?",
        type: .single,
        answers: [
            QuizAnswer(text: "Nur isolierte Armbewegungen üben", isCorrect: false),
            QuizAnswer(text: "Die Vorhand ohne Spielkontext trainieren", isCorrect: false),
            QuizAnswer(text: "Vorhand in Spielsituationen trainieren (defensiv, neutral, offensiv)", isCorrect: true),
            QuizAnswer(text: "Nur Topspin-Vorhände schlagen", isCorrect: false)
        ]
    )

]
