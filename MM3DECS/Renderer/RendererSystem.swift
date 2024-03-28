//
//  RendererSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
import MetalKit

class RenderSystem: System {
    var entityManager: EntityManager
    var timer : Float = 0.0
    
    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }
    
    func update(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        
        guard let cameraEntity = entityManager.entitiesWithComponents([CameraComponent.self]).first,
                  let cameraComponent = entityManager.getComponent(type: CameraComponent.self, for: cameraEntity),
                  let cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity) else {
                fatalError("Camera entity or components not found")
            }
        
        // Calculate the view and projection matrices
           let viewMatrix = float4x4(translation: cameraTransform.position).inverse
           let projectionMatrix = float4x4(projectionFov: cameraComponent.fieldOfView, near: cameraComponent.nearClippingPlane, far: cameraComponent.farClippingPlane, aspect: cameraComponent.aspectRatio, lhs: true)
           
        
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self, TransformComponent.self])

        for entity in entities {
                    guard let renderable = entityManager.getComponent(type: RenderableComponent.self, for: entity),
                          let transform = entityManager.getComponent(type: TransformComponent.self, for: entity) else {
                        continue
                    }
            render(entity: entity, with: renderable, transformConstant: transform, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix, renderEncoder: renderEncoder)
                }
    }
    
    private func render(entity: Entity, with renderable: RenderableComponent, transformConstant: TransformComponent, viewMatrix: float4x4, projectionMatrix: float4x4, renderEncoder: MTLRenderCommandEncoder) {
        // Animation or temporary transformation adjustments
            // Here, use the renderEncoder to set pipeline states, vertex buffers, and draw.
            // This involves translating the entity's components into Metal draw calls.
            // E.g., setting the pipeline state, updating uniforms, and calling mesh.draw().
        timer += 0.005
        var transform = transformConstant
            transform.rotation.y = sin(timer)
        // Encode the uniforms
            var uniforms = Uniforms()
           
            uniforms.viewMatrix = viewMatrix
            uniforms.modelMatrix = transform.modelMatrix
            uniforms.projectionMatrix = projectionMatrix
        
        renderEncoder.setVertexBytes(
            &uniforms,
          length: MemoryLayout<Uniforms>.stride,
          index: 11)

        renderable.render(encoder: renderEncoder)
        }
    
    func updateProjectionMatrix(for entity: Entity) -> float4x4? {
        guard let camera = entityManager.getComponent(type: CameraComponent.self, for: entity) else {
            return nil
        }

        return float4x4(projectionFov: camera.fieldOfView, near: camera.nearClippingPlane, far: camera.farClippingPlane, aspect: camera.aspectRatio, lhs: true)
    }

}
