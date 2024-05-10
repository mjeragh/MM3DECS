//
//  SceneManager.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 13/04/2024.
//
import MetalKit

protocol SceneProtocol {
   // var entityManager: EntityManager { get }
    var systems: [SystemProtocol] { get set }
    func setUp()
    func update(deltaTime: Float)
    func tearDown()
    
   // func updateSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder)
}



class SceneManager {
    private var scenes: [String: SceneProtocol] = [:]
    var currentScene: SceneProtocol?
    static var cameraManager:  CameraManager!
    static var entityManager: EntityManager!
    
    init() {
        let scene = GameScene(delegate: self)
        let entityManager = EntityManager()
        SceneManager.cameraManager = CameraManager(entityManager: entityManager)
        SceneManager.entityManager = entityManager
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
        SceneManager.cameraManager.updateAspect(aspectRatio)
        
    }
    
    func updateCurrentScene(deltaTime: Float) {
        currentScene?.update(deltaTime: deltaTime)
    }
    
    func updateCurrentSceneSystems(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
//        currentScene?.updateSystems(deltaTime: deltaTime, renderEncoder: renderEncoder)
        currentScene?.systems.forEach { system in
            system.update(deltaTime: deltaTime, entityManager: SceneManager.entityManager, renderEncoder: renderEncoder)
        }
    }
    
    //Static function for the Systems
    // Static functions to retrieve the camera matrices
        static func getViewMatrix() -> float4x4? {
            // Retrieve the camera manager from the current scene's manager
            guard let manager = cameraManager else { return nil }
            return manager.getViewMatrix()
        }

        static func getProjectionMatrix() -> float4x4? {
            // Retrieve the camera manager from the current scene's manager
            return SceneManager.cameraManager.getProjectionMatrix()
        }
    
    static func entitesToRender() -> [Entity]{
        return entityManager.entitiesWithComponents([RenderableComponent.self, TransformComponent.self])
    }
}

// Protocol definition for SceneDelegate
protocol SceneDelegate: AnyObject {
    // Camera Management
    func createCamera(type: CameraType,withCameraInputComponent: Bool)
    func updateActiveCamera(with transform: TransformComponent)
    func updateActiveCamera(with cameraInputComponent: CameraInputComponent)
    
    // Additional scene management
    //TODO: Implement these functions
    func addEntityToScene(name: String, with renderableComponent:RenderableComponent, with tranformComponent:TransformComponent, withInputComponent: Bool, withSelectionComponent: Bool)
//    func removeEntityFromScene(_ entity: Entity)
//    func findEntityByName(_ name: String) -> Entity?
}

extension SceneManager : SceneDelegate{
    
    func addEntityToScene(name: String, with renderableComponent:RenderableComponent, with tranformComponent:TransformComponent, withInputComponent: Bool = false, withSelectionComponent: Bool = false) {
        let entity = Entity(name: name)
        SceneManager.entityManager.addEntity(entity: entity)
        SceneManager.entityManager.addComponent(component: renderableComponent, to: entity)
        SceneManager.entityManager.addComponent(component: tranformComponent, to: entity)
        if withInputComponent {
            SceneManager.entityManager.addComponent(component: InputComponent(), to: entity)
        }
        if withSelectionComponent {
            SceneManager.entityManager.addComponent(component: SelectionComponent(), to: entity)
        }
    }
    
    func createCamera(type: CameraType, withCameraInputComponent: Bool = false) {
        SceneManager.cameraManager.setCamera(type: type, withCameraInputComponent: withCameraInputComponent)
    }
    
    func updateActiveCamera(with transform: TransformComponent) {
        SceneManager.entityManager.addComponent(component: transform, to: SceneManager.cameraManager.getActiveCameraEntity()!)
    }
    
    func updateActiveCamera(with cameraInputComponent: CameraInputComponent) {
        SceneManager.entityManager.addComponent(component: cameraInputComponent, to: SceneManager.cameraManager.getActiveCameraEntity()!)
    }
    
    func getAcctiveCameraInputComponent() -> CameraInputComponent {
        return SceneManager.entityManager.getComponent(type: CameraInputComponent.self, for: SceneManager.cameraManager.getActiveCameraEntity()!)!
    }
//    func addEntityToScene(_ entity: Entity) {
//        currentScene?.entityManager.addEntity(entity: entity)
//    }
//
//    func removeEntityFromScene(_ entity: Entity) {
//        currentScene?.entityManager.removeEntity(entity: entity)
//    }
//
//    func findEntityByName(_ name: String) -> Entity? {
//        return currentScene?.entityManager.findEntityByName(name)
//    }
}

