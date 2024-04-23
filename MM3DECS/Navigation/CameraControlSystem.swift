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
            // Constants for the distance scale can be adjusted to fit the needs of your application.
            // It could be based on the initial distance of the camera or just a fixed value that feels right.
            let fixedDistanceScale: Float = 125.0
            // This value should be tuned to your liking. large numbers for big worlds, while smaller numbers for smaller worlds

            
            
                    // Calculate the amount of drag
                    let dragDelta = CGPoint(x: dragCurrentPosition.x - dragStartPosition.x, y: dragCurrentPosition.y - dragStartPosition.y)
            logger.debug("CameraControlSystem: transform(\(transform.position.x), \(transform.position.y), \(transform.position.z)\n")
            
                    let rotationDelta = -Float(dragDelta.x) * deltaTime * Settings.rotationSpeed
            
            
            // Apply incremental rotation around the Y axis
                    transform.rotation.y += rotationDelta
       
            // Calculate the right vector for horizontal movement
            let rightVector = normalize(cross(transform.up, normalize(transform.forward)))

                 
            
            // Apply horizontal and vertical movement
            let horizontalMove = rightVector * Float(dragDelta.x) * deltaTime * Settings.translationSpeed * fixedDistanceScale
            let verticalMove = transform.up * Float(-dragDelta.y) * deltaTime * Settings.translationSpeed * fixedDistanceScale

            // Update the transform position
            transform.position += horizontalMove + verticalMove
                    
            // Clamping the rotation and position to avoid erratic behavior.
                transform.rotation.y = clampAngle(transform.rotation.y)
                transform.position = clampPosition(transform.position, within: [-180, 180]) // Example bounds
                //The clamp position bounderis effect the smoothness of the camera movement, the bigger the smoother the movement
                
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
    
//    private func clamp<T: Comparable>(value: T, min: T, max: T) -> T {
//            return Swift.max(min, Swift.min(max, value))
//        }
//        
        private func isFinite(_ value: Float) -> Bool {
            return !value.isInfinite && !value.isNaN
        }
    
    private func clampAngle(_ angle: Float) -> Float {
        // Assuming angle is in radians and we want to keep it between -PI and PI
        return fmod(angle + .pi, 2 * .pi) - .pi
    }

    private func clampPosition(_ position: float3, within bounds: [Float]) -> float3 {
        return float3(
            clamp(position.x, min: bounds[0], max: bounds[1]),
            clamp(position.y, min: bounds[0], max: bounds[1]),
            clamp(position.z, min: bounds[0], max: bounds[1])
        )
    }

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        return Swift.max(min, Swift.min(max, value))
    }

    private func normalize(_ vector: float3) -> float3 {
        let lengthSquared = dot(vector, vector)
        if lengthSquared > 0 {
            let invLength = rsqrt(lengthSquared)
            return vector * invLength
        }
        return vector // If length is zero, return the original vector
    }
}
