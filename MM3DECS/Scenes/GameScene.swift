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
    
    //let entityManager: EntityManager
    weak var delegate: SceneDelegate?
    


    init(delegate: SceneDelegate? = nil) {
       // self.entityManager = entityManager
        self.delegate = delegate
    }

    func setUp() {
        
        // Set up entities specific to this scene
        delegate!.createCamera(type: .arcball, withCameraInputComponent: true)
        
        setupEntites()
    
            systems.append(RenderSystem())
            systems.append(InputSystem())//, rayDebugSystem: rayDebugSystem))
           
    }

    func update(deltaTime: Float) {
        // Update the scene and entities
    }

    func tearDown() {
        // Clean up the scene before transition
        SceneManager.entityManager.removeAllEntities()
        systems.removeAll()
    }

    func setupEntites() {
        delegate?.addEntityToScene(name: "land", with: RenderableComponent(device: Renderer.device, name: "plane1000.usda"), with: TransformComponent(position: float3(0,0,0), rotation: float3(0,0,0), scale: float3(1,1,1)), withInputComponent: false, withSelectionComponent: false)
        delegate?.addEntityToScene(name: "tree", with: RenderableComponent(device: Renderer.device, name: "tree_pineRoundC.obj"), with: TransformComponent(position: float3(-10,0,0), rotation: float3(0,0,0), scale: float3(1,1,1)), withInputComponent: true, withSelectionComponent: true)
        delegate?.addEntityToScene(name: "colored_cube_obj", with: RenderableComponent(device: Renderer.device, name: "colored_cube.obj"), with: TransformComponent(position: float3(-10,0,0), rotation: float3(0,0,0), scale: float3(1,1,1)), withInputComponent: true, withSelectionComponent: true)
        delegate?.addEntityToScene(name: "sc", with: RenderableComponent(device: Renderer.device, name: "sc.usda"), with: TransformComponent(position: float3(-1,0,0), rotation: float3(0,0,0), scale: float3(1,1,1)), withInputComponent: true, withSelectionComponent: true)
//        let scale = Float(0.1)
//        delegate?.addEntityToScene(name: "Sun", with: RenderableComponent(device: Renderer.device, name: "peg.usda"), with: TransformComponent(position: float3(0,0,0), rotation: float3(0,0,0), scale: float3(scale,scale,scale)), withInputComponent: true, withSelectionComponent: true)
//        delegate?.addEntityToScene(name: "Moon", with: RenderableComponent(device: Renderer.device, name: "peg.usda"), with: TransformComponent(position: float3(-10,0,3), rotation: float3(0,0,0), scale: float3(scale,scale,scale)), withInputComponent: true, withSelectionComponent: true)
        delegate?.addEntityToScene(name: "colored_cube2z", with: RenderableComponent(device: Renderer.device, name: "colored_cube2z.usdz"), with: TransformComponent(position: float3(10, 0, 0), rotation: float3(0, 0, 0), scale: float3(1, 1, 1)), withInputComponent: true, withSelectionComponent: true)
               // Add other entities and components as needed
       
        
        
    }
}

