//
//  SceneManager.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 13/04/2024.
//
import MetalKit

protocol SceneProtocol {
    var entityManager: EntityManager { get }
    var systems: [SystemProtocol] { get set }
    func setUp()
    func update(deltaTime: Float)
    func tearDown()
    
    func updateSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder)
}



class SceneManager {
    private var scenes: [String: SceneProtocol] = [:]
    private var currentScene: SceneProtocol?
    
    init(scene: SceneProtocol) {
        addScene(scene, name: "Initial Scene")
        currentScene = scene
        scene.setUp()
    }

    func addScene(_ scene: SceneProtocol, name: String) {
        scenes[name] = scene
    }

    func transitionToScene(withName name: String) {
        currentScene?.tearDown()
        guard let scene = scenes[name] else { return }
        currentScene = scene
        scene.setUp()
    }

    func updateCurrentScene(deltaTime: Float) {
        currentScene?.update(deltaTime: deltaTime)
    }
}

