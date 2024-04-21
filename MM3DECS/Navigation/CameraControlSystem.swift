//
//  CameraControlSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 21/04/2024.
//

import Metal

import os.log
import os.signpost

enum Settings {
    static var rotationSpeed : Float { 0.5 }
    static var translationSpeed : Float { 30.0 }
    static var mouseScrollSensitivity : Float { 0.1 }
    static var mousePanSensitivity : Float { 0.008 }
    static var touchZoomSensitivity: Float { 10 }
}

class CameraControlSystem: SystemProtocol {
    let logger = Logger(subsystem: "com.lanterntech.mm3d", category: "CameraControlSystem")
    
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: any MTLRenderCommandEncoder) {
        // Get camera input component and apply movement to camera's transform component
        if let cameraEntity = entityManager.entities(for: CameraInputComponent.self).first,
                   var cameraInput = entityManager.getComponent(type: CameraInputComponent.self, for: cameraEntity),
                   let transform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity),
                   let dragStartPosition = cameraInput.dragStartPosition,
                   let dragCurrentPosition = cameraInput.dragCurrentPosition {
            
            logger.debug("CameraControlSystem: Updating camera transform startPosition(\(dragStartPosition.x), \(dragStartPosition.y))\n currentPosition(\(dragCurrentPosition.x),\(dragCurrentPosition.y))\n")
                    
                    // Calculate the amount of drag
                    let dragDelta = CGPoint(x: dragCurrentPosition.x - dragStartPosition.x, y: dragCurrentPosition.y - dragStartPosition.y)
            logger.debug("CameraControlSystem: transform(\(transform.position.x), \(transform.position.y), \(transform.position.z)\n")
            
                    let rotationDelta = -Float(dragDelta.x) * deltaTime * Settings.rotationSpeed
                    // Convert the drag distance to a rotation or translation value
                    var newTransform = transform
                    
                    newTransform.position.y += rotationDelta
            // Add any other transformation updates here
            logger.debug("CameraControlSystem: newT(\(newTransform.position.x), \(newTransform.position.y), \(newTransform.position.z)\n")
                        // Update the transform component of the camera entity
                        entityManager.addComponent(component: newTransform, to: cameraEntity)
            
                        cameraInput.dragStartPosition = dragCurrentPosition
                        entityManager.addComponent(component: cameraInput, to: cameraEntity)
                    }
    }
}
