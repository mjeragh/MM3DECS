//
//  GamrScene.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 13/04/2024.
//

import MetalKit
import os.log

class GameScene: SceneProtocol {
    var systems: [SystemProtocol] = []
    
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "GameScene")
    
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
        
        // Set up entities specific to this scene
        entityManager.addEntity(entity: entityManager.createCameraEntity(type: .arcball))
        
        setupEntites()
        
        if let cameraEntity = entityManager.entities(for: ArcballCameraComponent.self).first,
           var cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity){
            cameraTransform.position = [0, 0, 150]
            cameraTransform.rotation = [0,0,0]
            entityManager.addComponent(component: cameraTransform, to: cameraEntity)
            entityManager.addComponent(component: CameraInputComponent(cameraType: .arcball), to: cameraEntity)
            //setup Systems
            systems.append(RenderSystem(cameraEntity: cameraEntity))
            systems.append(InputSystem())
            systems.append(CameraControlSystem())
        } else {
            logger.info("Failed to retrieve transform component of camera entity.")
        }
    }

    func update(deltaTime: Float) {
        // Update the scene and entities
    }

    func tearDown() {
        // Clean up the scene before transition
        entityManager.removeAllEntities()
        systems.removeAll()
    }

    func setupEntites() {
        let trainEntity = Entity()
        entityManager.addEntity(entity: trainEntity)
        entityManager.addComponent(component: RenderableComponent(device: Renderer.device, name: "train.usd"), to: trainEntity)
        entityManager.addComponent(component: TransformComponent(position: float3(1, 0.6, 0), rotation: float3(0, 0, 0), scale: float3(1, 1, 1)), to: trainEntity)
        entityManager.addComponent(component: InputComponent(), to: trainEntity)
//               // Add other entities and components as needed
//        let landEntity = Entity()
//        entityManager.addEntity(entity: landEntity)
//        entityManager.addComponent(component: RenderableComponent(device: Renderer.device, name: "plane1000.usda"), to: landEntity)
//        entityManager.addComponent(component: TransformComponent(position: float3(0,0,0), rotation: float3(0,0,0), scale: float3(1,1,1)), to: landEntity)
//        entityManager.addComponent(component: InputComponent(), to: landEntity)
//        
//        let sunEntity = Entity()
//        let scale = Float(0.1)
//        entityManager.addEntity(entity: sunEntity)
//        entityManager.addComponent(component: RenderableComponent(device: Renderer.device, name: "peg.usda"), to: sunEntity)
//        entityManager.addComponent(component: TransformComponent(position: float3(0,0,0), rotation: float3(0,0,0), scale: float3(scale,scale,scale)), to: sunEntity)
//        entityManager.addComponent(component: InputComponent(), to: sunEntity)
    }
}

