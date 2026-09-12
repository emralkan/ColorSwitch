
import GameplayKit
import SpriteKit

// MARK: - Oyun Durumları

class GameStateMachine: GKStateMachine {
    
    unowned let scene: GameScene
    
    init(scene: GameScene) {
        self.scene = scene
        super.init(states: [
            GSMenuState(scene: scene),
            GSPlayingState(scene: scene),
            GSPausedState(scene: scene),
            GSGameOverState(scene: scene)
        ])
    }
}

class GSBaseState: GKState {
    unowned let scene: GameScene
    
    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }
}

class GSMenuState: GSBaseState {
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GSPlayingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        scene.showMenu()
    }
}

class GSPlayingState: GSBaseState {
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GSPausedState.self ||
               stateClass == GSGameOverState.self ||
               stateClass == GSMenuState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is GSPausedState {
            return
        }
        if previousState is GSGameOverState && scene.continueCount > 0 {
            return
        }
        scene.startGame()
    }
    
    override func update(deltaTime seconds: TimeInterval) {
    }
}

class GSPausedState: GSBaseState {
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GSPlayingState.self || stateClass == GSMenuState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        scene.isPaused = true
    }
    
    override func willExit(to nextState: GKState) {
        scene.isPaused = false
    }
}

class GSGameOverState: GSBaseState {
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GSPlayingState.self ||
               stateClass == GSMenuState.self
    }
    
}
