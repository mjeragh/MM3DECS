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
    var currentScene: SceneProtocol?
    
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

    func updateCurrentSceneCamera(with aspectRatio: Float) {
        // Update Perspective Camera
        if let cameraEntity = currentScene?.entityManager.entitiesWithAnyComponents([PerspectiveCameraComponent.self]).first,
           var cameraComponent = currentScene?.entityManager.getComponent(type: PerspectiveCameraComponent.self, for: cameraEntity) {
            cameraComponent.aspectRatio = aspectRatio
            currentScene?.entityManager.addComponent(component: cameraComponent, to: cameraEntity)
        }
        
        // Update Arcball Camera
        if let arcballCameraEntity = currentScene?.entityManager.entitiesWithAnyComponents([ArcballCameraComponent.self]).first,
           var arcballCameraComponent = currentScene?.entityManager.getComponent(type: ArcballCameraComponent.self, for: arcballCameraEntity) {
            arcballCameraComponent.aspect = aspectRatio
            currentScene?.entityManager.addComponent(component: arcballCameraComponent, to: arcballCameraEntity)
        }
        
        // Update Orthographic Camera
        if let orthoCameraEntity = currentScene?.entityManager.entitiesWithAnyComponents([OrthographicCameraComponent.self]).first,
           var orthoCameraComponent = currentScene?.entityManager.getComponent(type: OrthographicCameraComponent.self, for: orthoCameraEntity) {
            orthoCameraComponent.aspect = aspectRatio
            currentScene?.entityManager.addComponent(component: orthoCameraComponent, to: orthoCameraEntity)
        }
        
    }
    
    func updateCurrentScene(deltaTime: Float) {
        currentScene?.update(deltaTime: deltaTime)
    }
    
    func updateCurrentSceneSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        currentScene?.updateSystems(deltaTime: deltaTime, renderEncoder: renderEncoder)
    }
}

