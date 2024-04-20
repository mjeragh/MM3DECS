//
//  MovementSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/04/2024.
//

import Foundation
import Metal

class MovementSystem: SystemProtocol {
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: any MTLRenderCommandEncoder) {
        // Get entities with InputComponent and TransformComponent
        let entities = entityManager.getEntities(withComponents: [InputComponent.self, TransformComponent.self])

        for entity in entities {
            if let input = entityManager.getComponent(InputComponent.self, from: entity),
               var transform = entityManager.getComponent(TransformComponent.self, from: entity) {
                
                // Process input to update the transform
                if input.isTouching {
                    transform.position.x += Float(input.translation.width)
                    transform.position.y += Float(input.translation.height)
                }
                
                // Update the component in the entity manager
                entityManager.updateComponent(transform, from: entity)
            }
        }
    }
}
    
   
