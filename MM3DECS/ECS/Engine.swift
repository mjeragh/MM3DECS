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
//    var metalView: MTKView

    init(renderer: Renderer,
         sceneManager: SceneManager,
         options: Options) {
        // Initialize SceneManager, Renderer, and any other systems
//        self.metalView = metalView
        self.options = options
        
        self.renderer = renderer
        self.sceneManager = sceneManager
        renderer.delegate = self
    }

    func start() {
        // Set up the game and start the game loop
        isRunning = true
        //setupGame()
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

protocol RendererDelegate: AnyObject {
    func updateSceneSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder)
    func updateSceneCamera(aspectRatio: Float)
}

extension Engine : RendererDelegate{
    func updateSceneSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        sceneManager.updateCurrentSceneSystems(deltaTime: deltaTime, renderEncoder: renderEncoder)
    }
    
    func updateSceneCamera(aspectRatio: Float) {
        sceneManager.updateCurrentSceneCamera(with: aspectRatio)
    }
}
