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
    
    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }
    
    func update(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self, TransformComponent.self])

        for entity in entities {
            guard let renderable = entityManager.getComponent(type: RenderableComponent.self, for: entity),
                  let transform = entityManager.getComponent(type: TransformComponent.self, for: entity) else {
                continue
            }
            
            // Proceed with the rendering logic for each entity
            render(entity: entity, with: renderable, transform: transform, renderEncoder: renderEncoder)
        }
    }
    
    private func render(entity: Entity, with renderable: RenderableComponent, transform: TransformComponent, renderEncoder: MTLRenderCommandEncoder) {
        // Implement your Metal rendering logic here
        // This may involve setting vertex buffers, applying transformations, and issuing draw calls
    }
}
