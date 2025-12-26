//
//  GameManager.swift
//  SwiftUI-Interface
//
//  Created by Christian on 15.05.2024.
//

/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 This class manages the game state.
 */

import GameKit

class GameManager {
    
    class State: GKState {
        private(set) var validNextStates: [State.Type]
        
        init(_ validNextStates: [State.Type]) {
            self.validNextStates = validNextStates
            super.init()
        }
        
        func addValidNextState(_ state: State.Type) {
            validNextStates.append(state)
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return validNextStates.contains(where: { stateClass == $0 })
        }
        
        override func didEnter(from previousState: GKState?) {
            let note = GameStateChangeNotification(newState: self, previousState: previousState as? State)
            note.post()
        }
    }
    
    
    class TryDetectingTrophyPose: State {
    }
    
    class TryDetectingServe: State {
    }
    
    
    
    
    class ShowSummaryState: State {
    }
    
    fileprivate var activeObservers = [UIViewController: NSObjectProtocol]()
    
    let stateMachine: GKStateMachine
    var recordedVideoSource: AVAsset?
    var playerStats = PlayerStats()
    
    static var shared = GameManager()
    
    private init() {
        let states = [
            TryDetectingTrophyPose([TryDetectingServe.self]),
            TryDetectingServe([TryDetectingTrophyPose.self])
        ]
        // Allow transitions to Inactive from any state except itself
        for state in states {
            state.addValidNextState(TryDetectingTrophyPose.self)
        }
        stateMachine = GKStateMachine(states: states)
    }
    
    
    func reset() {
        // Reset all stored values
        recordedVideoSource = nil
        playerStats = PlayerStats()
        // Remove all observers and enter inactive state.
        let notificationCenter = NotificationCenter.default
        for observer in activeObservers {
            notificationCenter.removeObserver(observer)
        }
        activeObservers.removeAll()
        stateMachine.enter(TryDetectingTrophyPose.self)
    }
}

protocol GameStateChangeObserver: AnyObject {
    func gameManagerDidEnter(state: GameManager.State, from previousState: GameManager.State?)
}

extension GameStateChangeObserver where Self: UIViewController {
    func startObservingStateChanges() {
        let token = NotificationCenter.default.addObserver(forName: GameStateChangeNotification.name,
                                                           object: GameStateChangeNotification.gameManager,
                                                           queue: nil) { [weak self] (notification) in
            guard let note = GameStateChangeNotification(notification: notification) else {
                return
            }
            self?.gameManagerDidEnter(state: note.newState, from: note.previousState)
        }
        let gameManager = GameManager.shared
        gameManager.activeObservers[self] = token
    }
    
    func stopObservingStateChanges() {
        let gameManager = GameManager.shared
        guard let token = gameManager.activeObservers[self] else {
            return
        }
        NotificationCenter.default.removeObserver(token)
        gameManager.activeObservers.removeValue(forKey: self)
    }
}

struct GameStateChangeNotification {
    static let name = NSNotification.Name("GameStateChangeNotification")
    static let gameManager = GameManager.shared
    
    let newStateKey = "newState"
    let previousStateKey = "previousState"
    
    let newState: GameManager.State
    let previousState: GameManager.State?
    
    init(newState: GameManager.State, previousState: GameManager.State?) {
        self.newState = newState
        self.previousState = previousState
    }
    
    init?(notification: Notification) {
        guard notification.name == Self.name, let newState = notification.userInfo?[newStateKey] as? GameManager.State else {
            return nil
        }
        self.newState = newState
        self.previousState = notification.userInfo?[previousStateKey] as? GameManager.State
    }
    
    func post() {
        var userInfo = [newStateKey: newState]
        if let previousState = previousState {
            userInfo[previousStateKey] = previousState
        }
        NotificationCenter.default.post(name: Self.name, object: Self.gameManager, userInfo: userInfo)
    }
}

typealias GameStateChangeObserverViewController = UIViewController & GameStateChangeObserver



class GameStateObserver: ObservableObject {
    @Published var feedbackArray: [String] = []
    @Published var feedbackArrayDetailed : [String] = []
    @Published var positiveFeedbackArray: [String] = []
    @Published var positiveFeedbackArrayDetailed: [String] = []
    @Published var videoProgress: CGFloat = 0.0
    @Published var trophyFramePosition: CGFloat? = nil
    @Published var serveFramePosition: CGFloat? = nil
    @Published var highlightInstructions: [HighlightInstruction] = []
    @Published var highlightMap: [String: [HighlightInstruction]] = [:]

    let gameManager = GameManager.shared
    static let shared = GameStateObserver()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChange(notification:)), name: GameStateChangeNotification.name, object: GameStateChangeNotification.gameManager)
    }
    
    @objc private func handleStateChange(notification: Notification) {
        guard let note = GameStateChangeNotification(notification: notification) else {
            return
        }
        feedbackArray = gameManager.playerStats.feedbackArray
        feedbackArrayDetailed = gameManager.playerStats.feedbackArrayDetailed
        positiveFeedbackArray = gameManager.playerStats.positiveFeedbackArray
        positiveFeedbackArrayDetailed = gameManager.playerStats.positiveFeedbackArrayDetailed
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: GameStateChangeNotification.name, object: GameStateChangeNotification.gameManager)
    }
}


struct PlayerStats {
    var feedbackText = String()
    var feedbackArray = [String]()
    var feedbackArrayDetailed = [String]()
    var positiveFeedbackArray = [String]()
    var positiveFeedbackArrayDetailed = [String]()
}
