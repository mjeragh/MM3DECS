//
//  GamrScene.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 13/04/2024.
//

import MetalKit

class GameScene: SceneProtocol {
    var systems: [SystemProtocol] = []
    
    let entityManager: EntityManager
    
    func updateSystems(deltaTime: Float, renderEncoder: any MTLRenderCommandEncoder) {
        systems.forEach { system in
            system.update(deltaTime: deltaTime, entityManager: entityManager, renderEncoder: renderEncoder)
            
        }
    }


    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func setUp() {
        //setup Systems
        systems.append(RenderSystem())
        // Set up entities specific to this scene
        entityManager.addEntity(entity: entityManager.createCameraEntity(type: .perspective))
        
        setupEntites()
        
        if let cameraEntity = entityManager.entities(for: PerspectiveCameraComponent.self).first,
           var cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity){
            cameraTransform.position = [2, 2, -5]
            cameraTransform.rotation = [0,0,0]
            entityManager.addComponent(component: cameraTransform, to: cameraEntity)
        } else {
            print("Failed to retrieve transform component of camera entity.")
        }
    }

    func update(deltaTime: Float) {
        // Update the scene and entities
    }

    func tearDown() {
        // Clean up the scene before transition
    }

    func setupEntites() {
        let trainEntity = Entity()
                entityManager.addEntity(entity: trainEntity)
                entityManager.addComponent(component: RenderableComponent(device: Renderer.device, name: "train.usd"), to: trainEntity)
        entityManager.addComponent(component: TransformComponent(position: float3(0, -0.6, 0), rotation: float3(0, 0, 0), scale: float3(1, 1, 1)), to: trainEntity)
               // Add other entities and components as needed
        
    }
}

