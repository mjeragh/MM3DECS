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
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self, TransformComponent.self])

        for entity in entities {
                    guard let renderable = entityManager.getComponent(type: RenderableComponent.self, for: entity),
                          let transform = entityManager.getComponent(type: TransformComponent.self, for: entity),
                          let uniforms = entityManager.getComponent(type: UniformsComponent.self, for: entity) else {
                        continue
                    }

                    render(entity: entity, with: renderable, transform: transform, uniforms: uniforms, renderEncoder: renderEncoder)
                }
    }
    
    private func render(entity: Entity, with renderable: RenderableComponent, transform: TransformComponent, uniforms: UniformsComponent, renderEncoder: MTLRenderCommandEncoder) {
            // Here, use the renderEncoder to set pipeline states, vertex buffers, and draw.
            // This involves translating the entity's components into Metal draw calls.
            // E.g., setting the pipeline state, updating uniforms, and calling mesh.draw().
        timer += 0.005
          Renderer.cameraUniforms.viewMatrix = float4x4(translation: [0, 0, -2]).inverse
//        transform.position.y = -0.6
//        transform.rotation.y = sin(timer)
        Renderer.cameraUniforms.modelMatrix = transform.modelMatrix
        renderEncoder.setVertexBytes(
            &Renderer.cameraUniforms,
          length: MemoryLayout<Uniforms>.stride,
          index: 11)

        renderable.render(encoder: renderEncoder)
        }
}
