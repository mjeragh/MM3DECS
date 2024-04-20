//
//  InputSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/04/2024.
//
import Foundation
import MetalKit
import SwiftUI



class InputSystem: SystemProtocol {
    var currentTouches = [CGPoint]()
    
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: MTLRenderCommandEncoder) {
        // Here, you would process the currentTouches or other input states
        // For each entity that can be moved or interacted with via touch:
        let entities = entityManager.entitiesWithComponents([InputComponent.self])
        for entity in entities {
            if var inputComponent = entityManager.getComponent(type: InputComponent.self, for: entity) {
                // Process the input component, e.g., update position based on touch
                if let transformComponent = entityManager.getComponent(type: TransformComponent.self, for: entity) {
                    var mutableTransform = transformComponent
                    mutableTransform.position.x += Float(inputComponent.translation.width) * deltaTime
                    mutableTransform.position.y += Float(inputComponent.translation.height) * deltaTime
                    entityManager.addComponent(component: mutableTransform, to: entity)
                }
            }
        }


    }
    
    func touchMoved(gesture: DragGesture.Value) {
        let translation = gesture.translation
        // Store or update touch location in a more comprehensive manner
        currentTouches.append(CGPoint(x: translation.width, y: translation.height))
    }

    func touchEnded() {
        currentTouches.removeAll()
    }
}
