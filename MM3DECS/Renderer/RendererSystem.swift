//
//  RendererSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
class RenderSystem: System {
    var entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime: Float) {
        let entities = entityManager.entitiesWithComponents(RenderableComponent.self, TransformComponent.self)

        for entity in entities {
            guard let renderable = entityManager.getComponent(type: RenderableComponent.self, for: entity),
                  let transform = entityManager.getComponent(type: TransformComponent.self, for: entity) else { continue }

            // Example rendering code, adjust based on your project specifics
            render(entity: entity, with: renderable, and: transform)
        }
    }

    private func render(entity: Entity, with renderable: RenderableComponent, and transform: TransformComponent) {
        // Implement the actual rendering logic here
        // This could involve setting up buffers, textures, and applying transformations before drawing
    }
}
