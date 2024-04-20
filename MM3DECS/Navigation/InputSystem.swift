//
//  InputSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/04/2024.
//

import SwiftUI

class InputSystem: SystemProtocol {
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: any MTLRenderCommandEncoder) {
        <#code#>
    }
    
    func touchMoved(gesture: DragGesture.Value) {
        // Update the input component of the entities
        let translation = gesture.translation
        let inputComponent = InputComponent(translation: translation)
        // Get entities that are affected by touch input and update their components
    }

    func touchEnded() {
        // Update the input component to indicate that the touch has ended
    }
}
