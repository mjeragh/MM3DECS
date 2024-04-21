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
    var entityManager: EntityManager?
    
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: any MTLRenderCommandEncoder) {
        //not implemented
        self.entityManager = entityManager
    }
    
    // Other methods...

    func touchBegan(gesture: DragGesture.Value) {
        let touchLocation = gesture.location
        if let selectedEntity = performPicking(at: touchLocation) {
            // An object was touched, mark it as selected
            var selectionComponent = entityManager!.getComponent(type: SelectionComponent.self, for: selectedEntity) ?? SelectionComponent(isSelected: false)
            selectionComponent.isSelected = true
            entityManager!.addComponent(component: selectionComponent, to: selectedEntity)
        } else {
            // No object was touched, the camera should be marked as selected
            if let cameraEntity = entityManager!.entities(for: CameraInputComponent.self).first {
                var cameraInput = entityManager!.getComponent(type: CameraInputComponent.self, for: cameraEntity) ?? CameraInputComponent()
                cameraInput.lastTouchPosition = touchLocation
                entityManager!.addComponent(component: cameraInput, to: cameraEntity)
            }
        }
    }

    func touchMoved(gesture: DragGesture.Value) {
        // Similar logic as touchBegan, update camera position if it's the selected entity
        let position = gesture.location
        if let cameraEntity = entityManager!.entities(for: CameraInputComponent.self).first {
                    var cameraInput = entityManager!.getComponent(type: CameraInputComponent.self, for: cameraEntity) ?? CameraInputComponent()
                    cameraInput.dragCurrentPosition = position
                    entityManager!.addComponent(component: cameraInput, to: cameraEntity)
                }
    }

    func touchEnded(gesture: DragGesture.Value) {
        // Clear selected state or camera input as needed
        if let cameraEntity = entityManager!.entities(for: CameraInputComponent.self).first {
                    var cameraInput = entityManager!.getComponent(type: CameraInputComponent.self, for: cameraEntity) ?? CameraInputComponent()
                    cameraInput.dragStartPosition = nil
                    cameraInput.dragCurrentPosition = nil
                    entityManager!.addComponent(component: cameraInput, to: cameraEntity)
                }
    }

    private func performPicking(at location: CGPoint) -> Entity? {
        // Implement picking logic and return the entity if touched
        return nil // Replace with actual logic
    }
}
