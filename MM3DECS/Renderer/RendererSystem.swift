//
//  RendererSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
import MetalKit

class RenderSystem: SystemProtocol {
    var timer: Float = 0.0

    func update(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        for entity in SceneManager.getEntitesToRender() {
            guard let renderable = SceneManager.entityManager.getComponent(type: RenderableComponent.self, for: entity),
                  let transform = SceneManager.entityManager.getComponent(type: TransformComponent.self, for: entity) else {
                continue
            }
            renderEncoder.pushDebugGroup(entity.name)
            render(with: renderable, transformConstant: transform, viewMatrix: SceneManager.getViewMatrix()!, projectionMatrix: SceneManager.getProjectionMatrix()!, renderEncoder: renderEncoder)
            renderEncoder.popDebugGroup()
        }
    }

    private func render(with renderable: RenderableComponent, transformConstant: TransformComponent, viewMatrix: float4x4, projectionMatrix: float4x4, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = Uniforms()
        uniforms.viewMatrix = viewMatrix
        uniforms.modelMatrix = transformConstant.modelMatrix
        uniforms.projectionMatrix = projectionMatrix

        //renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        renderable.render(encoder: renderEncoder, uniformsConstant: uniforms)
    }
}
