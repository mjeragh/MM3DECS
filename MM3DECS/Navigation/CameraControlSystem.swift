//
//  CameraControlSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 21/04/2024.
//

import Metal

class CameraControlSystem: SystemProtocol {
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: any MTLRenderCommandEncoder) {
        // Get camera input component and apply movement to camera's transform component
        let chosenRotationSpeed: Float = 0.01
        if let cameraEntity = entityManager.entities(for: CameraInputComponent.self).first,
                   let cameraInput = entityManager.getComponent(type: CameraInputComponent.self, for: cameraEntity),
                   let transform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity),
                   let dragStartPosition = cameraInput.dragStartPosition,
                   let dragCurrentPosition = cameraInput.dragCurrentPosition {

                    // Calculate the amount of drag
                    let dragDistance = CGPoint(x: dragCurrentPosition.x - dragStartPosition.x, y: dragCurrentPosition.y - dragStartPosition.y)
                    
                    // Convert the drag distance to a rotation or translation value
                    var newTransform = transform
                    // For simplicity, let's say dragging left/right rotates the camera around the Y axis
                    let rotationAmount = Float(dragDistance.x) * deltaTime * chosenRotationSpeed
                    newTransform.rotation.y += rotationAmount
            // Add any other transformation updates here

                        // Update the transform component of the camera entity
                        entityManager.addComponent(component: newTransform, to: cameraEntity)
                    }
    }
}
