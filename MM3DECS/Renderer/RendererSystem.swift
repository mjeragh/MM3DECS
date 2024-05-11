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
    
    func update(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
       // Render entities with calculated matrices
        for entity in SceneManager.getEntitesToRender() {
            guard let renderable = SceneManager.entityManager.getComponent(type: RenderableComponent.self, for: entity),
                  let transform = SceneManager.entityManager.getComponent(type: TransformComponent.self, for: entity) else {
                continue
            }
            render(with: renderable, transformConstant: transform, viewMatrix: SceneManager.getViewMatrix()!, projectionMatrix: SceneManager.getProjectionMatrix()!, renderEncoder: renderEncoder)
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
    
   
}
