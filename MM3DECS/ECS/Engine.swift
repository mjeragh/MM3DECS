//
//  Engine.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 17/04/2024.
//

import Foundation
import MetalKit
import os.log

class Engine : NSObject, ObservableObject{
    var sceneManager: SceneManager?
    var renderer: Renderer?
    var running = false
    var options: Options?
//    var metalView: MTKView
    var logger = Logger(subsystem: "MM3DECS", category: "Engine")
    override init() {
    }

    func start() {
        // Set up the game and start the game loop
        running = true
        
        //setupGame()
    }

    func setupGame(metalView: MTKView,
                   options: Options) {
        // Perform initial setup before the game starts
        self.options = options
        
        self.renderer = Renderer(metalView: metalView)
        self.sceneManager = SceneManager()
        self.renderer?.delegate = self
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
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
}

extension Engine : RendererDelegate{
   
    func updateSceneSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        sceneManager?.updateCurrentSceneSystems(deltaTime: deltaTime, renderEncoder: renderEncoder)
    }
    
}

extension Engine : MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(view.bounds.width) / Float(view.bounds.height)
        Renderer.params.width = Float(view.bounds.width) //UInt32(size.width)
        Renderer.params.height = Float(view.bounds.height)//UInt32(size.height)
        logger.debug("inside Engine: width: \(Renderer.params.width), height: \(Renderer.params.height)")
        sceneManager?.updateCurrentSceneCameraAspectRatio(with: aspect)
    }
    
    func draw(in view: MTKView) {
        guard running == true else {
            return
        }
        renderer?.draw(in: view)
    }
    
}
