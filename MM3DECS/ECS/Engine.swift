//
//  Engine.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 17/04/2024.
//

import Foundation
import MetalKit

class Engine : ObservableObject{
    var sceneManager: SceneManager?
    var renderer: Renderer?
    var running = false
    var options: Options?
//    var metalView: MTKView

    init() {
    }

    func start() {
        // Set up the game and start the game loop
        running = true
        //setupGame()
    }

    func setupGame(renderer: Renderer,
                           sceneManager: SceneManager,
                           options: Options) {
        // Perform initial setup before the game starts
        self.options = options
        
        self.renderer = renderer
        self.sceneManager = sceneManager
        self.renderer?.delegate = self
        
        //ensure this is the last call
        //self.renderer?.startRendering()
        
        
        // More setup as needed...
    }

   

    func stop() {
        // Clean up before the game stops
        running = false
    }

    // Additional methods for transitioning scenes, handling input, etc.
    func updateOptions(options: Options) {
        renderer?.updateOptions(options: options)
    }
}

protocol RendererDelegate: AnyObject {
    func updateSceneSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder)
    func updateSceneCamera(aspectRatio: Float)
    func isRunning() -> Bool
}

extension Engine : RendererDelegate{
   
    func isRunning() -> Bool {
        running
    }
    
    func updateSceneSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        sceneManager?.updateCurrentSceneSystems(deltaTime: deltaTime, renderEncoder: renderEncoder)
    }
    
    func updateSceneCamera(aspectRatio: Float) {
        sceneManager?.updateCurrentSceneCamera(with: aspectRatio)
    }
    
}
