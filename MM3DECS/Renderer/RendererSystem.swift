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
        // Assuming the existence of a function/component to identify the camera type
        guard let cameraEntity = entityManager.entitiesWithAnyComponents([CameraComponent.self, ArcballCameraComponent.self, OrthographicCameraComponent.self]).first else {
            fatalError("No camera entity found")
        }

        let viewMatrix: float4x4
        let projectionMatrix: float4x4

        if let cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity) {
            viewMatrix = float4x4(translation: cameraTransform.position).inverse
        } else {
            fatalError("Camera entity missing TransformComponent")
        }

        // Determine the type of camera and calculate the matrices accordingly
        if let perspectiveCamera = entityManager.getComponent(type: CameraComponent.self, for: cameraEntity) {
            projectionMatrix = float4x4(projectionFov: perspectiveCamera.fieldOfView, near: perspectiveCamera.nearClippingPlane, far: perspectiveCamera.farClippingPlane, aspect: perspectiveCamera.aspectRatio, lhs: true)
        } else if let arcballCamera = entityManager.getComponent(type: ArcballCameraComponent.self, for: cameraEntity) {
            // Arcball camera calculations here
            projectionMatrix = float4x4(projectionFov: arcballCamera.fov, near: arcballCamera.near, far: arcballCamera.far, aspect: arcballCamera.aspect)
            // Arcball specific view matrix can also be calculated here if different from the basic view matrix
        } // Inside the update function of RenderSystem.swift
        
        else if let orthographicCamera = entityManager.getComponent(type: OrthographicCameraComponent.self, for: cameraEntity) {
            let aspectRatio = CGFloat(orthographicCamera.aspect)
            let viewSize = CGFloat(orthographicCamera.viewSize)
            let rect = CGRect(x: -viewSize * aspectRatio * 0.5,
                              y: viewSize * 0.5,
                              width: viewSize * aspectRatio,
                              height: viewSize)
            projectionMatrix = float4x4(orthographic: rect,
                                        near: orthographicCamera.near,
                                        far: orthographicCamera.far)
        } else {
            fatalError("Unsupported camera type")
        }

        // Render entities with calculated matrices
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
