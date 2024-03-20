//
//  RendererSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
class RenderSystem: System {
    func update(deltaTime: Float, entityManager: EntityManager) {
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self, TransformComponent.self])

        for entity in entities {
            guard let renderable = entityManager.getComponent(type: RenderableComponent.self, for: entity),
                  let transform = entityManager.getComponent(type: TransformComponent.self, for: entity) else {
                continue
            }
            
            // Proceed with the rendering logic for each entity
            render(entity: entity, with: renderable, transform: transform)
        }
    }
    
    private func render(entity: Entity, with renderable: RenderableComponent, transform: TransformComponent) {
        // Implement your Metal rendering logic here
        // This may involve setting vertex buffers, applying transformations, and issuing draw calls
    }
}
