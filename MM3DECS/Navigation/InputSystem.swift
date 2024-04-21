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

    func touchMovedOrBegan(gesture: DragGesture.Value) {
        let touchLocation = gesture.location
        // Get the camera entity
            if let cameraEntity = entityManager!.entities(for: CameraInputComponent.self).first,
               var cameraInput = entityManager!.getComponent(type: CameraInputComponent.self, for: cameraEntity) {
                
                // Check if this is the first touch
                if cameraInput.dragStartPosition == nil {//it is began
                    
                    if let selectedEntity = performPicking(at: touchLocation) {
                        // An object was touched, mark it as selected
                        var selectionComponent = entityManager!.getComponent(type: SelectionComponent.self, for: selectedEntity) ?? SelectionComponent(isSelected: false)
                        selectionComponent.isSelected = true
                        entityManager!.addComponent(component: selectionComponent, to: selectedEntity)
                    } else {
                        // No object was touched, the camera should be marked as selected
                        if let cameraEntity = entityManager!.entities(for: CameraInputComponent.self).first {
                            var cameraInput = entityManager!.getComponent(type: CameraInputComponent.self, for: cameraEntity) ?? CameraInputComponent()
                            cameraInput.dragStartPosition = touchLocation
                            entityManager!.addComponent(component: cameraInput, to: cameraEntity)
                        }
                    }
                }//began
                else {//it is moved
                    // Similar logic as touchBegan, update camera position if it's the selected entity
                    cameraInput.dragCurrentPosition = touchLocation
                    entityManager!.addComponent(component: cameraInput, to: cameraEntity)
                    //later I need to check if the camera is selected
                            
                }//else moved
                
            }
        
       
    }//touchedMovedOrBegan

    func touchEnded(gesture: DragGesture.Value) {
        // Clear selected state or camera input as needed
        if let cameraEntity = entityManager!.entities(for: CameraInputComponent.self).first {
                    var cameraInput = entityManager!.getComponent(type: CameraInputComponent.self, for: cameraEntity) ?? CameraInputComponent()
                    cameraInput.dragStartPosition = nil
                    cameraInput.dragCurrentPosition = nil
                    cameraInput.lastTouchPosition = nil
                    entityManager!.addComponent(component: cameraInput, to: cameraEntity)
                }
    }

    private func performPicking(at location: CGPoint) -> Entity? {
        // Implement picking logic and return the entity if touched
        return nil // Replace with actual logic
    }
}
