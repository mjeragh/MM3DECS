//
//  CameraControlSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 21/04/2024.
//

import Metal

import os.log
import os.signpost


class CameraControlSystem: SystemProtocol {
    let logger = Logger(subsystem: "com.lanterntech.mm3d", category: "CameraControlSystem")
    
    func update(deltaTime: Float, renderEncoder: any MTLRenderCommandEncoder) {
        // Get camera input component and apply movement to camera's transform component
        if let cameraEntity = SceneManager.entityManager.entities(for: CameraInputComponent.self).first,
           var cameraInput = SceneManager.entityManager.getComponent(type: CameraInputComponent.self, for: cameraEntity),
           var transform = SceneManager.entityManager.getComponent(type: TransformComponent.self, for: cameraEntity),
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
            SceneManager.entityManager.addComponent(component: transform, to: cameraEntity)
                    cameraInput.dragStartPosition = dragCurrentPosition
            SceneManager.entityManager.addComponent(component: cameraInput, to: cameraEntity)
                    }
    }
 
    //MARK: - Camera Control Methods
    private func applyArcballControl(_ input: inout CameraInputComponent, _ transform: inout TransformComponent, _ deltaTime: Float) {
        // Existing arcball control logic here
        var captainLog = "CameraControlSystem: Updating camera transform startPosition:\(input.dragStartPosition!.x),\(input.dragStartPosition!.y)\ncurrentPosition:\(input.dragCurrentPosition!.x),\(input.dragCurrentPosition!.y))\n"
        logger.debug("\(captainLog)")
        if let dragStart = input.dragStartPosition, let dragCurrent = input.dragCurrentPosition {
            // Handle rotation
            let rotationChange = float2(Float(dragCurrent.x - dragStart.x), Float(dragCurrent.y - dragStart.y)) * deltaTime
            transform.rotation.y += rotationChange.x * Settings.rotationSpeed
            transform.rotation.x -= rotationChange.y * Settings.rotationSpeed
            var cameraComponent = SceneManager.entityManager.getComponent(type: ArcballCameraComponent.self, for: SceneManager.cameraManager.getActiveCameraEntity()!)
            // Handle zoom based on drag distance
            let zoomChange = Float(dragCurrent.y - dragStart.y) * deltaTime * Settings.mouseScrollSensitivity
            cameraComponent!.distance += zoomChange
            cameraComponent!.distance = max(cameraComponent!.minDistance, min(cameraComponent!.distance, cameraComponent!.maxDistance))
        
            // Save changes back to components
           
            input.dragStartPosition = dragCurrent // Update drag position for continuous interaction
            SceneManager.entityManager.addComponent(component: cameraComponent!, to: SceneManager.cameraManager.getActiveCameraEntity()!)
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

    func applyOrbitControl(_ input: inout CameraInputComponent, _ transform: inout TransformComponent, _ deltaTime: Float) {
        let orbitCenter = float3(0, 0, 0)  // Assume a fixed orbit center, e.g., the origin
        
        // Sensitivity factors for rotation
        let rotationSensitivity: Float = 0.005
        
        // Calculate rotation change
        let rotationChange = CGPoint(
            x: input.dragCurrentPosition!.x - input.dragStartPosition!.x,
            y: input.dragCurrentPosition!.y - input.dragStartPosition!.y
        )
        let rotationDelta = float2(Float(rotationChange.x), Float(rotationChange.y)) * rotationSensitivity
        
        // Update camera rotation angles based on input
        transform.rotation.y -= rotationDelta.x * deltaTime
        transform.rotation.x += rotationDelta.y * deltaTime
        
        // Clamp the elevation angle to prevent flipping at the poles
        transform.rotation.x = max(-Float.pi / 2, min(Float.pi / 2, transform.rotation.x))
        
        // Calculate camera's new position using spherical coordinates
        let distance = length(transform.position - orbitCenter) // Distance from orbit center
        transform.position.x = orbitCenter.x + distance * cos(transform.rotation.x) * sin(transform.rotation.y)
        transform.position.y = orbitCenter.y + distance * sin(transform.rotation.x)
        transform.position.z = orbitCenter.z + distance * cos(transform.rotation.x) * cos(transform.rotation.y)
        
//        // Update camera's view matrix or equivalent, to look at orbitCenter
//        // Use your MathLibrary's lookAt function or similar to create the view matrix
//        let viewMatrix = float4x4(eye: transform.position, center: orbitCenter, up: float3(0, 1, 0))
//        transform.matrix = viewMatrix
    }

    func applyOrthographicControl(_ input: inout CameraInputComponent, _ transform: inout TransformComponent, _ deltaTime: Float) {
        // Calculate panning based on drag
        let panChange = CGPoint(x: input.dragCurrentPosition!.x - input.dragStartPosition!.x,
                                y: input.dragCurrentPosition!.y - input.dragStartPosition!.y)
        let panDelta = float2(Float(panChange.x), Float(panChange.y)) * deltaTime * Settings.translationSpeed

        // Convert panDelta.x to account for the rotation of the camera
        // When camera is rotated around Y by -pi/2, left/right panning is along world's z-axis
        let worldPanDeltaZ = panDelta.x * (transform.rotation.y == -Float.pi / 2 ? 1 : -1)

        // Apply the pan deltas to the position, y is for up/down panning
        transform.position.z -= worldPanDeltaZ
        transform.position.y += panDelta.y // y remains unchanged since it's screen space up/down
        // transform.position.x remains unchanged for orthographic panning

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
