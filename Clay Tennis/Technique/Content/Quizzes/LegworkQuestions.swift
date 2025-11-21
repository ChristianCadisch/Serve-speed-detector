//
//  LegworkQuestions.swift
//  Clay Tennis
//
//

import Foundation

let legworkQuestions: [QuizQuestion] = [

    // MARK: - Fundamentals

    QuizQuestion(
        text: "Warum ist die Beinarbeit im Tennis so entscheidend?",
        type: .single,
        answers: [
            QuizAnswer(text: "Weil sie hauptsächlich für schöne Fotos sorgt", isCorrect: false),
            QuizAnswer(text: "Weil sie den optimalen Treffpunkt und die richtige Distanz zum Ball ermöglicht", isCorrect: true),
            QuizAnswer(text: "Weil sie die Schlagtechnik ersetzt", isCorrect: false),
            QuizAnswer(text: "Weil sie nur für Profis relevant ist", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was beschreibt der Satz: \"Position creates quality\"?",
        type: .single,
        answers: [
            QuizAnswer(text: "Die Schlagqualität hängt fast nur vom Schläger ab", isCorrect: false),
            QuizAnswer(text: "Die Schlagqualität hängt stark von der Positionierung zum Ball ab", isCorrect: true),
            QuizAnswer(text: "Nur der Griff bestimmt die Schlagqualität", isCorrect: false),
            QuizAnswer(text: "Position spielt nur beim Service eine Rolle", isCorrect: false)
        ]
    ),

    // MARK: - Split Step

    QuizQuestion(
        text: "Welche Aussage zum Split-Step ist korrekt?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Er ist breit und dynamisch", isCorrect: true),
            QuizAnswer(text: "Er findet genau in dem Moment statt, in dem der Gegner den Ball trifft", isCorrect: true),
            QuizAnswer(text: "Er dient der Aktivierung der Beinmuskulatur für schnelle Starts", isCorrect: true),
            QuizAnswer(text: "Er ist nur beim Return wichtig", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was passiert, wenn der Split-Step zu früh oder zu spät ausgeführt wird?",
        type: .single,
        answers: [
            QuizAnswer(text: "Die Reaktionsfähigkeit in alle Richtungen nimmt ab", isCorrect: true),
            QuizAnswer(text: "Der Spieler springt höher", isCorrect: false),
            QuizAnswer(text: "Die Schlagtechnik wird automatisch besser", isCorrect: false),
            QuizAnswer(text: "Es hat keinen Einfluss auf das Spiel", isCorrect: false)
        ]
    ),

    // MARK: - Step Size & Last Step

    QuizQuestion(
        text: "Wie sollte die Schrittlänge an die Laufdistanz angepasst werden?",
        type: .single,
        answers: [
            QuizAnswer(text: "Immer nur kleine Schritte", isCorrect: false),
            QuizAnswer(text: "Immer nur grosse Schritte", isCorrect: false),
            QuizAnswer(text: "Kleine Distanz → kleine Schritte, grosse Distanz → grosse Schritte", isCorrect: true),
            QuizAnswer(text: "Schrittlänge ist egal, Hauptsache schnell", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was ist die Hauptaufgabe des letzten Schrittes vor dem Schlag (Schlagschritt)?",
        type: .single,
        answers: [
            QuizAnswer(text: "Er dient dem Abbremsen von Läufen ohne Einfluss auf die Stabilität", isCorrect: false),
            QuizAnswer(text: "Er sorgt für eine stabile Schlagposition und Gleichgewicht", isCorrect: true),
            QuizAnswer(text: "Er ist nur auf Sandplätzen notwendig", isCorrect: false),
            QuizAnswer(text: "Er dient dazu, näher am Netz zu stehen", isCorrect: false)
        ]
    ),

    // MARK: - Stance & Center of Mass

    QuizQuestion(
        text: "Welche Vorteile hat eine tiefe Position des Körperschwerpunkts?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Besseres Gleichgewicht", isCorrect: true),
            QuizAnswer(text: "Mehr Stabilität im Treffpunkt", isCorrect: true),
            QuizAnswer(text: "Schlechtere Beweglichkeit", isCorrect: false),
            QuizAnswer(text: "Mehr Kontrolle über aggressive Schläge", isCorrect: true)
        ]
    ),

    QuizQuestion(
        text: "Welche Aussage zu offener und geschlossener Schlagstellung trifft zu?",
        type: .single,
        answers: [
            QuizAnswer(text: "Nur die offene Schlagstellung ist modern und richtig", isCorrect: false),
            QuizAnswer(text: "Beide Schlagstellungen müssen situativ beherrscht werden", isCorrect: true),
            QuizAnswer(text: "Die geschlossene Stellung ist nur im Training erlaubt", isCorrect: false),
            QuizAnswer(text: "Die Stellung hat keinen Einfluss auf Balance und Präzision", isCorrect: false)
        ]
    ),

    // MARK: - Crossover Step & Recovery

    QuizQuestion(
        text: "Was ist der Hauptzweck des Kreuzschritts (Crossover Step)?",
        type: .single,
        answers: [
            QuizAnswer(text: "Dekoration für schöne Laufwege", isCorrect: false),
            QuizAnswer(text: "Die schnellste Rückkehr in die Platzmitte", isCorrect: true),
            QuizAnswer(text: "Er ersetzt den Split-Step", isCorrect: false),
            QuizAnswer(text: "Er wird nur im Doppel verwendet", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Merkmale kennzeichnen einen effizienten Kreuzschritt?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Explosives Abdrücken vom äusseren Bein", isCorrect: true),
            QuizAnswer(text: "Das innere Bein kreuzt vor dem Körper", isCorrect: true),
            QuizAnswer(text: "Ruhiger Oberkörper und tiefer Körperschwerpunkt", isCorrect: true),
            QuizAnswer(text: "Starke Hüftrotation während des Kreuzschritts", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was sollte direkt nach einem Kreuzschritt folgen?",
        type: .single,
        answers: [
            QuizAnswer(text: "Ein weiterer grosser Schritt ohne Split-Step", isCorrect: false),
            QuizAnswer(text: "Ein Split-Step, um für die nächste Richtungsänderung bereit zu sein", isCorrect: true),
            QuizAnswer(text: "Ein Schlag ohne Vorbereitung", isCorrect: false),
            QuizAnswer(text: "Ein Stopp in der Platzmitte", isCorrect: false)
        ]
    ),

    // MARK: - Movement Economy & Stability

    QuizQuestion(
        text: "Was bedeutet Bewegungsökonomie im Tennis?",
        type: .single,
        answers: [
            QuizAnswer(text: "Möglichst laut und kraftvoll laufen", isCorrect: false),
            QuizAnswer(text: "Leichtes, rhythmisches Bewegen mit minimalem Energieaufwand", isCorrect: true),
            QuizAnswer(text: "Nur gerade Linien laufen", isCorrect: false),
            QuizAnswer(text: "So wenig wie möglich zu laufen", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Aussagen zur Stabilität des Oberkörpers während des Schlages sind korrekt?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Der Oberkörper soll möglichst ruhig bleiben", isCorrect: true),
            QuizAnswer(text: "Die Beine schaffen die Basis für diese Stabilität", isCorrect: true),
            QuizAnswer(text: "Starke Oberkörperbewegungen verbessern die Kontrolle", isCorrect: false),
            QuizAnswer(text: "Ruhige Kopf- und Oberkörperposition unterstützen Präzision", isCorrect: true)
        ]
    ),

    // MARK: - First Step & Anticipation

    QuizQuestion(
        text: "Woran orientiert sich der erste Schritt zurück zur Mitte nach dem Schlag?",
        type: .single,
        answers: [
            QuizAnswer(text: "An der eigenen Lieblingsseite", isCorrect: false),
            QuizAnswer(text: "An der Richtung, aus der der letzte Ball kam", isCorrect: false),
            QuizAnswer(text: "An der erwarteten Richtung des nächsten gegnerischen Balls", isCorrect: true),
            QuizAnswer(text: "Zufällig, um unberechenbar zu sein", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Welche Aussage zur Unterstützung explosiver Starts ist korrekt?",
        type: .single,
        answers: [
            QuizAnswer(text: "Die Arme sollten ruhig bleiben, um Energie zu sparen", isCorrect: false),
            QuizAnswer(text: "Aktive Armbewegungen unterstützen den explosiven Start", isCorrect: true),
            QuizAnswer(text: "Der Schläger sollte immer mit beiden Händen gehalten werden", isCorrect: false),
            QuizAnswer(text: "Armbewegungen stören die Beinarbeit nur", isCorrect: false)
        ]
    ),

    // MARK: - Clay Movement & Sliding

    QuizQuestion(
        text: "Welche Faktoren sind für effizientes Rutschen auf Sandplätzen wichtig?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Tiefer Körperschwerpunkt", isCorrect: true),
            QuizAnswer(text: "Aufrechter Oberkörper", isCorrect: true),
            QuizAnswer(text: "Flacher Fusskontakt mit dem Boden während der Rutschphase", isCorrect: true),
            QuizAnswer(text: "Lange, unkontrollierte Rutschphasen", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was zeigt an, dass ein Spieler das Rutschen ineffizient nutzt?",
        type: .single,
        answers: [
            QuizAnswer(text: "Er rutscht nur selten", isCorrect: false),
            QuizAnswer(text: "Er rutscht zu lange und verliert dadurch Zeit und Dynamik", isCorrect: true),
            QuizAnswer(text: "Er stoppt die Rutschphase früh und kontrolliert", isCorrect: false),
            QuizAnswer(text: "Er rutscht nur in eine Richtung", isCorrect: false)
        ]
    ),

    // MARK: - Braking & Restart

    QuizQuestion(
        text: "Wie kann die Rutschphase kontrolliert beendet werden?",
        type: .single,
        answers: [
            QuizAnswer(text: "Indem der Oberkörper stark nach vorne kippt", isCorrect: false),
            QuizAnswer(text: "Indem der Körperschwerpunkt über das Knie gebracht wird, um Widerstand aufzubauen", isCorrect: true),
            QuizAnswer(text: "Indem man einfach aus der Rutschphase herausspringt", isCorrect: false),
            QuizAnswer(text: "Indem man den Oberkörper zur Seite dreht", isCorrect: false)
        ]
    ),

    QuizQuestion(
        text: "Was ist notwendig, bevor man nach einer Rutschphase explosiv starten kann?",
        type: .single,
        answers: [
            QuizAnswer(text: "Keine Vorbereitung – einfach loslaufen", isCorrect: false),
            QuizAnswer(text: "Zuerst muss zwischen Schuh und Boden Reibung/Widerstand aufgebaut werden", isCorrect: true),
            QuizAnswer(text: "Der Spieler muss zwei zusätzliche Split-Steps machen", isCorrect: false),
            QuizAnswer(text: "Der Spieler sollte zuerst stehen bleiben und dann langsam anlaufen", isCorrect: false)
        ]
    ),

    // MARK: - Common Errors

    QuizQuestion(
        text: "Welche Faktoren führen typischerweise zu schlechter Beinarbeit?",
        type: .multiple,
        answers: [
            QuizAnswer(text: "Zu spätes Ausführen des Split-Steps", isCorrect: true),
            QuizAnswer(text: "Zu viele unnötige Schritte", isCorrect: true),
            QuizAnswer(text: "Schlechter Gleichgewichtssinn und instabile Körperhaltung", isCorrect: true),
            QuizAnswer(text: "Konsequente Anpassung der Schrittgrösse an die Distanz", isCorrect: false)
        ]
    )

]
