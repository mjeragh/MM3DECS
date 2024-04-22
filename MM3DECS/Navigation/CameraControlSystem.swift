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
    static var rotationSpeed : Float { 1.5 }
    static var translationSpeed : Float { 3.0 }
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
                   var transform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity),
                   let dragStartPosition = cameraInput.dragStartPosition,
                   let dragCurrentPosition = cameraInput.dragCurrentPosition {
            
            logger.debug("CameraControlSystem: Updating camera transform startPosition(\(dragStartPosition.x), \(dragStartPosition.y))\n currentPosition(\(dragCurrentPosition.x),\(dragCurrentPosition.y))\n")
                    
                    // Calculate the amount of drag
                    let dragDelta = CGPoint(x: dragCurrentPosition.x - dragStartPosition.x, y: dragCurrentPosition.y - dragStartPosition.y)
            logger.debug("CameraControlSystem: transform(\(transform.position.x), \(transform.position.y), \(transform.position.z)\n")
            
                    let rotationDelta = -Float(dragDelta.x) * deltaTime * Settings.rotationSpeed
            // Clamp rotationDelta to avoid large values
                    let clampedRotationDelta = clamp(value: rotationDelta, min: -1, max: 1)
            
            // Apply incremental rotation around the Y axis
                    transform.rotation.y += clampedRotationDelta
                        
            
            // Assuming camera looks at point (0,0,0), you could adjust this to be a real target point
                  let target = float3(0, 0, 0)
            
            // Compute the normalized direction from the camera to the target point.
                let cameraToTargetNormalized = normalize(target - transform.position)
                  
            // Calculate the right vector for horizontal movement
                let rightVector = normalize(cross(transform.up, cameraToTargetNormalized))

            
            // The distance scale should not be the length from the camera to the target but rather a fixed scaling factor.
                // You could use a fixed value or compute a scaling factor based on the initial distance from the camera to the target.
                // For example:
                let initialDistance = length(float3(0, 0, 5) - target) // Replace with your initial camera distance
                let distanceScale = min(length(transform.position - target) / initialDistance, 1.0)

                    
            
            
            // Apply incremental horizontal and vertical movement
                let horizontalMove = rightVector * Float(dragDelta.x) * deltaTime * Settings.translationSpeed
                let verticalMove = transform.up * Float(-dragDelta.y) * deltaTime * Settings.translationSpeed
                
                        
            // Incrementally update the position, clamped by a factor of the initial distance
                transform.position += horizontalMove * distanceScale
                transform.position += verticalMove * distanceScale
                    
            
            guard isFinite(transform.position.x) && isFinite(transform.position.y) && isFinite(transform.position.z) else {
                            // Reset transform if values become extreme or NaN
                            transform.position = float3(0, 0, 5) // Example default position
                            transform.rotation = float3(0, 0, 0) // Example default rotation
                            cameraInput.dragStartPosition = nil
                            logger.warning("CameraControlSystem: Resetting camera transform due to extreme values")
                            entityManager.addComponent(component: transform, to: cameraEntity)
                            cameraInput.dragCurrentPosition = nil
                            entityManager.addComponent(component: cameraInput, to: cameraEntity)
                            return
                        }
            // Update components
                    entityManager.addComponent(component: transform, to: cameraEntity)
                    cameraInput.dragStartPosition = dragCurrentPosition
                    entityManager.addComponent(component: cameraInput, to: cameraEntity)
                    }
    }
    
    private func clamp<T: Comparable>(value: T, min: T, max: T) -> T {
            return Swift.max(min, Swift.min(max, value))
        }
        
        private func isFinite(_ value: Float) -> Bool {
            return !value.isInfinite && !value.isNaN
        }
}
