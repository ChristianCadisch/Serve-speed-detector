//
//  VolleyQuestions.swift
//  Clay Tennis
//
//

import Foundation

let volleyQuestions: [QuizQuestion] = [

    // MARK: - Volley Fundamentals

    QuizQuestion(
        text: "Wozu dient der Volley im modernen Tennis hauptsächlich?",
        type: .single,
        answers: [
            QuizAnswer(text: "Um Zeit zu gewinnen", isCorrect: false),
            QuizAnswer(text: "Um dem Gegner Zeit zu nehmen und den Punkt abzuschliessen", isCorrect: true),
            QuizAnswer(text: "Um defensive Bälle abzuwehren", isCorrect: false),
            QuizAnswer(text: "Um den Gegner in lange Rallys zu zwingen", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum unterscheidet sich der Volley technisch stark vom Grundlinienschlag?",
        type: .single,
        answers: [
            QuizAnswer(text: "Weil er nur mit viel Topspin gespielt wird", isCorrect: false),
            QuizAnswer(text: "Weil kaum Zeit für eine grosse Ausholbewegung bleibt", isCorrect: true),
            QuizAnswer(text: "Weil er nur aus dem Handgelenk ausgeführt wird", isCorrect: false),
            QuizAnswer(text: "Weil er nur mit Rückhandgriff gespielt wird", isCorrect: false)
        ]
    ),

    // MARK: - Grip & Ready Position

    QuizQuestion(
        text: "Welcher Griff ist die Basis für Vorhand- und Rückhandvolley?",
        type: .single,
        answers: [
            QuizAnswer(text: "Eastern-Griff", isCorrect: false),
            QuizAnswer(text: "Semi-Western-Griff", isCorrect: false),
            QuizAnswer(text: "Kontinentalgriff", isCorrect: true),
            QuizAnswer(text: "Western-Griff", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was kennzeichnet die optimale Ready Position am Netz?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Schlägerkopf vor dem Körper auf Brusthöhe", isCorrect: true),
            QuizAnswer(text: "Leicht gebeugte Knie und dynamische Haltung", isCorrect: true),
            QuizAnswer(text: "Gewicht auf den Fersen", isCorrect: false),
            QuizAnswer(text: "Schläger hinter dem Körper", isCorrect: false)
        ]
    ),

    // MARK: - Preparation & Movement

    QuizQuestion(
        text: "Wie sollte die Ausholbewegung beim Volley aussehen?",
        type: .single,
        answers: [
            QuizAnswer(text: "Lang und flüssig wie bei Grundschlägen", isCorrect: false),
            QuizAnswer(text: "Sehr kurz und kompakt", isCorrect: true),
            QuizAnswer(text: "Über dem Kopf beginnend", isCorrect: false),
            QuizAnswer(text: "Mit grossem Rückschwung", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Rolle spielt die Schulterrotation beim Volley?",
        type: .single,
        answers: [
            QuizAnswer(text: "Sie ersetzt die Beinarbeit", isCorrect: false),
            QuizAnswer(text: "Sie unterstützt die kurze Führbewegung des Schlägers", isCorrect: true),
            QuizAnswer(text: "Sie ist nicht notwendig", isCorrect: false),
            QuizAnswer(text: "Sie erzeugt hauptsächlich Topspin", isCorrect: false)
        ]
    ),

    // MARK: - Contact Point & Racket Position

    QuizQuestion(
        text: "Wo sollte der Treffpunkt beim Volley idealerweise sein?",
        type: .single,
        answers: [
            QuizAnswer(text: "Hinter dem Körper", isCorrect: false),
            QuizAnswer(text: "Direkt neben dem Körper", isCorrect: false),
            QuizAnswer(text: "Weit vor dem Körper", isCorrect: true),
            QuizAnswer(text: "Über Kopfhöhe", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum ist ein hoher Schlägerkopf beim Volley wichtig?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Er erleichtert das Spielen von niedrigen Volleys", isCorrect: false),
            QuizAnswer(text: "Er ermöglicht kontrolliertes Blocken von oben nach unten", isCorrect: true),
            QuizAnswer(text: "Er verkürzt die Reaktionszeit", isCorrect: true),
            QuizAnswer(text: "Er erhöht automatisch die Schlaggeschwindigkeit", isCorrect: false)
        ]
    ),

    // MARK: - Footwork & Forward Movement

    QuizQuestion(
        text: "Warum ist eine Vorwärtsbewegung beim Volley entscheidend?",
        type: .single,
        answers: [
            QuizAnswer(text: "Sie erhöht den Rückschlag des Gegners", isCorrect: false),
            QuizAnswer(text: "Sie verbessert Stabilität und Kontrolle beim Treffpunkt", isCorrect: true),
            QuizAnswer(text: "Sie verlangsamt die Reaktionszeit", isCorrect: false),
            QuizAnswer(text: "Sie ist nur bei Schmetterbällen relevant", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was ist das Ziel des Schritts in den Volley hinein?",
        type: .single,
        answers: [
            QuizAnswer(text: "Nähe zum Netz aufbauen", isCorrect: false),
            QuizAnswer(text: "Kraft aus dem Körper in den Ball übertragen", isCorrect: true),
            QuizAnswer(text: "Zeit für einen längeren Schwung gewinnen", isCorrect: false),
            QuizAnswer(text: "Den Gegner überraschen", isCorrect: false)
        ]
    ),

    // MARK: - Forehand vs Backhand Volley

    QuizQuestion(
        text: "Was unterscheidet den Rückhandvolley vom Vorhandvolley technisch?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Die linke Hand unterstützt die Stabilität bei der Vorbereitung", isCorrect: true),
            QuizAnswer(text: "Der Rückhandvolley benötigt einen anderen Griff", isCorrect: false),
            QuizAnswer(text: "Die Schulterachse bleibt besonders stabil", isCorrect: true),
            QuizAnswer(text: "Der Schläger muss stärker schwingen", isCorrect: false)
        ]
    ),

    // MARK: - Wrist & Control

    QuizQuestion(
        text: "Welche Rolle spielt das Handgelenk beim Volley?",
        type: .single,
        answers: [
            QuizAnswer(text: "Es bleibt komplett locker während des Schlages", isCorrect: false),
            QuizAnswer(text: "Es wird kurz vor dem Treffpunkt stabilisiert", isCorrect: true),
            QuizAnswer(text: "Es erzeugt den Hauptteil der Schlagkraft", isCorrect: false),
            QuizAnswer(text: "Es sollte stark abgeknickt werden", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Warum ist ein fester Schlägerwinkel beim Volley entscheidend?",
        type: .single,
        answers: [
            QuizAnswer(text: "Damit der Ball mehr Topspin erhält", isCorrect: false),
            QuizAnswer(text: "Damit die Richtung über den Schlägerkopf und nicht über einen grossen Schwung gesteuert wird", isCorrect: true),
            QuizAnswer(text: "Damit der Ball höher abspringt", isCorrect: false),
            QuizAnswer(text: "Damit der Gegner weniger Reaktionszeit hat", isCorrect: false)
        ]
    ),

    // MARK: - Touch & Defensive Volleys

    QuizQuestion(
        text: "Was ist für einen erfolgreichen Stopp-Volley entscheidend?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Reduzierter Griffdruck", isCorrect: true),
            QuizAnswer(text: "Geschwindigkeitsabsorption mit weicher Hand", isCorrect: true),
            QuizAnswer(text: "Maximaler Schwung", isCorrect: false),
            QuizAnswer(text: "Hoher Treffpunkt", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Wie soll ein defensiver Volley in einer Drucksituation gespielt werden?",
        type: .single,
        answers: [
            QuizAnswer(text: "Kurz und ohne Richtung", isCorrect: false),
            QuizAnswer(text: "Tief und lang zurück, um Zeit zu gewinnen", isCorrect: true),
            QuizAnswer(text: "Mit maximalem Topspin", isCorrect: false),
            QuizAnswer(text: "Immer parallel zur Seitenlinie", isCorrect: false)
        ]
    ),

    // MARK: - Advanced Concepts

    QuizQuestion(
        text: "Wann kann ein Topspin-Volley sinnvoll eingesetzt werden?",
        type: .single,
        answers: [
            QuizAnswer(text: "Bei sehr flachen, schnellen Bällen", isCorrect: false),
            QuizAnswer(text: "Bei höheren Bällen für zusätzliche Kontrolle", isCorrect: true),
            QuizAnswer(text: "Nur beim Return", isCorrect: false),
            QuizAnswer(text: "Nur im Doppel", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was ist die Hauptfunktion eines gut gespielten Volleys im Spielaufbau?",
        type: .single,
        answers: [
            QuizAnswer(text: "Den Gegner hinter die Grundlinie zwingen", isCorrect: false),
            QuizAnswer(text: "Den Punkt schnell und kontrolliert beenden", isCorrect: true),
            QuizAnswer(text: "Zeit für eine Erholungspause schaffen", isCorrect: false),
            QuizAnswer(text: "Den Gegner in die Defensive locken und dann abzuwarten", isCorrect: false)
        ]
    ),

    // MARK: - Common Errors

    QuizQuestion(
        text: "Welcher Fehler tritt häufig bei fehlerhaften Volleys auf?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Zu grosse Ausholbewegung", isCorrect: true),
            QuizAnswer(text: "Zu tiefer Schlägerkopf vor dem Treffpunkt", isCorrect: true),
            QuizAnswer(text: "Zu aktives Handgelenk", isCorrect: true),
            QuizAnswer(text: "Ruhiger Oberkörper", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Massnahme hilft bei unsicheren Volleys am meisten?",
        type: .single,
        answers: [
            QuizAnswer(text: "Mehr Armkraft einsetzen", isCorrect: false),
            QuizAnswer(text: "Früheres Positionieren und kompaktere Bewegung", isCorrect: true),
            QuizAnswer(text: "Längere Ausholbewegung verwenden", isCorrect: false),
            QuizAnswer(text: "Den Ball näher am Körper treffen", isCorrect: false)
        ]
    )
]
