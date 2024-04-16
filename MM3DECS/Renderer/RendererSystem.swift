//
//  RendererSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
import MetalKit

class RenderSystem: SystemProtocol {
    var timer : Float = 0.0
    var cameraEntity: Entity?
    var cameraComponent: CameraComponent?
    
    init(cameraEntity: Entity) {
        updateCameraEntity(cameraEntity)
    }
    
    
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: MTLRenderCommandEncoder) {
        //Camera entity for, multple camera maybe later
        

            // Assume that there's only one camera entity for simplicity
        guard let cameraEntity = cameraEntity else {
            fatalError("No Camere Entity found")
        }
        guard  let cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity) else {
            fatalError("No camera transform component found")
        }
        
        let cameraComponent: CameraComponent
        if let perspectiveCamera = entityManager.getComponent(type: PerspectiveCameraComponent.self, for: cameraEntity) {
            cameraComponent = perspectiveCamera
        } else if let arcballCamera = entityManager.getComponent(type: ArcballCameraComponent.self, for: cameraEntity) {
            cameraComponent = arcballCamera
        } else if let orthographicCamera = entityManager.getComponent(type: OrthographicCameraComponent.self, for: cameraEntity) {
            cameraComponent = orthographicCamera
        } else {
            fatalError("No camera component found")
        }

        // Compute the view matrix using the camera's transform
        let viewMatrix = cameraComponent.calculateViewMatrix(transform: cameraTransform)
        // The projection matrix is already part of the CameraComponent protocol
        let projectionMatrix = cameraComponent.projectionMatrix


        // Render entities with calculated matrices
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self, TransformComponent.self])
        for entity in entities {
            guard let renderable = entityManager.getComponent(type: RenderableComponent.self, for: entity),
                  let transform = entityManager.getComponent(type: TransformComponent.self, for: entity) else {
                continue
            }
            render(with: renderable, transformConstant: transform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix, renderEncoder: renderEncoder)
        }
    }

    
    private func render(with renderable: RenderableComponent, transformConstant: TransformComponent, viewMatrix: float4x4, projectionMatrix: float4x4, renderEncoder: MTLRenderCommandEncoder) {
        // Animation or temporary transformation adjustments
            // Here, use the renderEncoder to set pipeline states, vertex buffers, and draw.
            // This involves translating the entity's components into Metal draw calls.
            // E.g., setting the pipeline state, updating uniforms, and calling mesh.draw().
//        timer += 0.005
//        var transform = transformConstant
//            transform.rotation.y = sin(timer)
        // Encode the uniforms
            var uniforms = Uniforms()
           
            uniforms.viewMatrix = viewMatrix
            uniforms.modelMatrix = transformConstant.modelMatrix
            uniforms.projectionMatrix = projectionMatrix
        
        renderEncoder.setVertexBytes(
            &uniforms,
          length: MemoryLayout<Uniforms>.stride,
          index: 11)

        renderable.render(encoder: renderEncoder)
        }
    
    // Call this when the camera entity is changed/updated
        func updateCameraEntity(_ newCameraEntity: Entity) {
            cameraEntity = newCameraEntity
        }
   
}
