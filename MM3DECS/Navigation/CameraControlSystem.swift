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
            
                    // Apply camera control based on camera type
                    switch cameraInput.cameraType {
                    case .arcball:
                        applyArcballControl(&cameraInput, &transform, deltaTime)
                    case .perspective:
                        applyPerspectiveControl(&cameraInput, &transform, deltaTime)
                    case .orthographic:
                        applyOrthographicControl(&cameraInput, &transform, deltaTime)
                    }
            // Update components
                    entityManager.addComponent(component: transform, to: cameraEntity)
                    cameraInput.dragStartPosition = dragCurrentPosition
                    entityManager.addComponent(component: cameraInput, to: cameraEntity)
                    }
    }
 
    //MARK: - Camera Control Methods
    private func applyArcballControl(_ input: inout CameraInputComponent, _ transform: inout TransformComponent, _ deltaTime: Float) {
        // Existing arcball control logic here
        var captainLog = "CameraControlSystem: Updating camera transform startPosition:\(input.dragStartPosition!.x),\(input.dragStartPosition!.y)\ncurrentPosition:\(input.dragCurrentPosition!.x),\(input.dragCurrentPosition!.y))\n"
        logger.debug("\(captainLog)")
        // Constants for the distance scale can be adjusted to fit the needs of your application.
        // It could be based on the initial distance of the camera or just a fixed value that feels right.
        let fixedDistanceScale: Float = 125.0
        // This value should be tuned to your liking. large numbers for big worlds, while smaller numbers for smaller worlds

        
        
                // Calculate the amount of drag
        let dragDelta = CGPoint(x: input.dragCurrentPosition!.x - input.dragStartPosition!.x, y: input.dragCurrentPosition!.y - input.dragStartPosition!.y)
        captainLog = "CameraControlSystem: transform(\(transform.position.x), \(transform.position.y), \(transform.position.z)\n"
        logger.debug("\(captainLog)")
        
                let rotationDelta = -Float(dragDelta.x) * deltaTime * Settings.rotationSpeed
        
        
        // Apply incremental rotation around the Y axis
                transform.rotation.y += rotationDelta
       
        // Apply horizontal and vertical movement
        let horizontalMove = transform.right * Float(dragDelta.x) * deltaTime * Settings.translationSpeed * fixedDistanceScale
        let verticalMove = transform.up * Float(-dragDelta.y) * deltaTime * Settings.translationSpeed * fixedDistanceScale

        // Update the transform position
        transform.position += horizontalMove + verticalMove
                
        // Clamping the rotation and position to avoid erratic behavior.
            transform.rotation.y = clampAngle(transform.rotation.y)
        captainLog = "CameraControlSystem: transform Y rotation(\(transform.rotation.y)\n"
        logger.debug("\(captainLog)")
            transform.position = clampPosition(transform.position, within: [-180, 180]) // Example boundsOS
            //The clamp position bounderis effect the smoothness of the camera movement, the bigger the smoother the movement
            
        guard isFinite(transform.position.x) && isFinite(transform.position.y) && isFinite(transform.position.z) else {
                        // Reset transform if values become extreme or NaN
                        transform.position = float3(0, 0, 5) // Example default position
                        transform.rotation = float3(0, 0, 0) // Example default rotation
                        input.dragStartPosition = nil
                        logger.warning("CameraControlSystem: Resetting camera transform due to extreme values")
//                        entityManager.addComponent(component: transform, to: cameraEntity)
                        input.dragCurrentPosition = nil
//                        entityManager.addComponent(component: cameraInput, to: cameraEntity)
                        return
                    }
    }

    func applyPerspectiveControl(_ input: inout CameraInputComponent, _ transform: inout TransformComponent, _ deltaTime: Float) {
        // Calculate rotation
        let rotationChange = CGPoint(x: input.dragCurrentPosition!.x - input.dragStartPosition!.x,
                                     y: input.dragCurrentPosition!.y - input.dragStartPosition!.y)
        let rotationDelta = float2(Float(rotationChange.x), Float(rotationChange.y)) * deltaTime * Settings.rotationSpeed

        // Apply rotation around Y axis and a free rotation around X axis
        transform.rotation.y += rotationDelta.x
        transform.rotation.x += rotationDelta.y

        // Calculate zoom based on vertical mouse drag or scroll wheel
        let zoomDelta = Float(input.dragCurrentPosition!.y - input.dragStartPosition!.y) * deltaTime * Settings.mouseScrollSensitivity
        transform.position.z += zoomDelta // assuming the forward vector is along the z-axis

        // Calculate panning (left-right, up-down movement)
        let panDelta = float2(Float(rotationChange.x), Float(rotationChange.y)) * deltaTime * Settings.translationSpeed
        transform.position.x += panDelta.x
        transform.position.y -= panDelta.y

        // Ensure rotation angles and position are within acceptable limits
        transform.rotation.x = clampAngle(transform.rotation.x)
        transform.rotation.y = clampAngle(transform.rotation.y)
        transform.rotation.z = clampAngle(transform.rotation.z)
        transform.position = clampPosition(transform.position, within: [-180, 180])
    }

    func applyOrthographicControl(_ input: inout CameraInputComponent, _ transform: inout TransformComponent, _ deltaTime: Float) {
        var captainLog = ""
        
        // Calculate panning based on drag
        let panChange = CGPoint(x: input.dragCurrentPosition!.x - input.dragStartPosition!.x,
                                y: input.dragCurrentPosition!.y - input.dragStartPosition!.y)
        let panDelta = float2(Float(panChange.x), Float(panChange.y)) * deltaTime * Settings.translationSpeed
        
        captainLog = "CameraControlSystem(Orthographic): Touch pan Change: \(panChange.x) \(panChange.y)\t panDelta\(panDelta.x), \(panDelta.y)\n"
        logger.debug("\(captainLog)")

        // Assuming that the camera's rotation is stored in Euler angles in 'transform.rotation'
          let rotationMatrix = float4x4(rotationYXZ: transform.rotation) // Using the rotation YXZ constructor from your MathLibrary
          let inverseRotationMatrix = rotationMatrix.inverse // Invert the matrix to convert movement from camera space to world space
            captainLog = "CameraControlSystem(Orthographic): Rotation Matrix: \(rotationMatrix)\n"
            logger.debug("\(captainLog)")
        
          var worldPanDelta = inverseRotationMatrix * float4(panDelta.x, 0, 0, 0)
            captainLog = "CameraControlSystem(Orthographic): World Pan Delta: \(worldPanDelta)\n"
            logger.debug("\(captainLog)")

        // Since the camera is rotated around Y by -pi/2, swap the panning direction
            worldPanDelta = float4(worldPanDelta.z, worldPanDelta.y, -worldPanDelta.x, 0)
            
            // Apply the transformed pan deltas to the position
            transform.position += float3(worldPanDelta.x, panDelta.y, worldPanDelta.z) // y remains unchanged since it's screen space up/down
        // Clamp the position to avoid moving too far
        transform.position = clampPosition(transform.position, within: [-180,180])
    }
    
    
    
    // MARK: - Private Methods
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

//    private func normalize(_ vector: float3) -> float3 {
//        let lengthSquared = dot(vector, vector)
//        if lengthSquared > 0 {
//            let invLength = rsqrt(lengthSquared)
//            return vector * invLength
//        }
//        return vector // If length is zero, return the original vector
//    }
}
