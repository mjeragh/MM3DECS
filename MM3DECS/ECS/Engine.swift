//
//  Engine.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 17/04/2024.
//

import Foundation
import MetalKit

class Engine {
    var sceneManager: SceneManager
    var renderer: Renderer?
    var isRunning = false
    var options: Options
    var metalView: MTKView

    init(metalView: MTKView,
         options: Options) {
        // Initialize SceneManager, Renderer, and any other systems
        self.metalView = metalView
        self.options = options
        
        self.renderer = Renderer(metalView: metalView)
        let initialScene = GameScene(entityManager: EntityManager())
        self.sceneManager = SceneManager(scene: initialScene)
        
        self.renderer?.sceneManager = sceneManager
    }

    func start() {
        // Set up the game and start the game loop
        isRunning = true
        setupGame()
    }

    private func setupGame() {
        // Perform initial setup before the game starts
        sceneManager.transitionToScene(withName: "Initial Scene")
        
        
        // More setup as needed...
    }

   

    func stop() {
        // Clean up before the game stops
        isRunning = false
    }

    // Additional methods for transitioning scenes, handling input, etc.
    func updateOptions(options: Options) {
        renderer?.updateOptions(options: options)
    }
}
