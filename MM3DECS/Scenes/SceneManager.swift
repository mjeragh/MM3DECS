//
//  SceneManager.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 13/04/2024.
//
import MetalKit

protocol SceneContract {
    func setUp()
    func update(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder)
    func tearDown()
}



class SceneManager {
    private var scenes: [String: SceneContract] = [:]
    private var currentScene: SceneContract?
    
    init(scene: SceneContract) {
        addScene(scene, name: "Initial Scene")
        currentScene = scene
    }

    func addScene(_ scene: SceneContract, name: String) {
        scenes[name] = scene
    }

    func transitionToScene(withName name: String) {
        currentScene?.tearDown()
        guard let scene = scenes[name] else { return }
        currentScene = scene
        scene.setUp()
    }

    func updateCurrentScene(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        currentScene?.update(deltaTime: deltaTime, renderEncoder: renderEncoder)
    }
}

