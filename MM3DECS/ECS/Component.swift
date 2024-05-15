//
//  Protocol.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
import MetalKit
protocol Component { }

// Example components
import simd
import os.log



struct TransformComponent: Component {
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "TransformComponent")
    var position: float3
    var rotation: float3 // Use Euler angles for simplicity here; consider quaternions for complex rotations
    var scale: float3
    var up: float3 = [0, 1, 0] // Up vector for the camera
    let epsilon: Float = 0.0001
    func nearlyEqual(a: Float, b: Float, epsilon: Float) -> Bool {
        return abs(a - b) < epsilon
    }

    init(position: float3 = [0, 0, 0], rotation: float3 = [0, 0, 0], scale: float3 = [1, 1, 1], up: float3 = [0,1,0]) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }

    var forward : float3 {
        // Compute the forward direction of the camera
        //Any change to calculating forward, update right and up
        let yaw = rotation.y
        return float3(-sin(yaw), 0, cos(yaw)) // Assuming y is up and z is backward
    }
    
    var right : float3 {
        [forward.z, forward.y, -forward.x] //since there is no pitch, and roll. otherwise we need a perpedicular vector, which we do the expensive
        //cross product below.
        //cross(up, forward) //since forward is already normalized, we don't need to normalize the result
    }
    
    // Compute the model matrix using your math utilities
    var modelMatrix: float4x4 {
        // Translation matrix from your math utilities
        let translationMatrix = float4x4(translation: position)
        
        // Rotation matrices from your math utilities
        let rotationXMatrix = float4x4(rotationX: rotation.x)
        let rotationYMatrix = float4x4(rotationY: rotation.y)
        let rotationZMatrix = float4x4(rotationZ: rotation.z)
        let rotationMatrix = rotationZMatrix * rotationYMatrix * rotationXMatrix // Combine rotations
        
        // Scaling matrix from your math utilities
        let scaleMatrix = float4x4(scaling: scale)
        
//       let combinedMatrix = translationMatrix * rotationMatrix * scaleMatrix
//        if !nearlyEqual(a: combinedMatrix.determinant, b: 1.0, epsilon: epsilon) {
//            logger.error("Potential precision loss detected in model matrix.")
//        }
        
        // Combine transformations
        return translationMatrix * rotationMatrix * scaleMatrix
    }
}


struct RenderableComponent: Component {
    var mesh: MTKMesh
    var texture: MTLTexture?
    let name: String
    let boundingBox: MDLAxisAlignedBoundingBox
    // Other rendering-related properties such as materials, shaders, etc.
    // Initialize the RenderableComponent with a mesh loaded from the given asset name.
        init(device: MTLDevice, name: String) {
            guard let assetURL = Bundle.main.url(forResource: name, withExtension: nil) else {
                fatalError("Model: \(name) not found")
            }

            let allocator = MTKMeshBufferAllocator(device: device)
            let asset = MDLAsset(url: assetURL, vertexDescriptor: .defaultLayout, bufferAllocator: allocator)
            guard let mdlMesh = asset.childObjects(of: MDLMesh.self).first as? MDLMesh else {
                fatalError("No mesh available")
            }

            do {
                self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
            } catch {
                fatalError("Failed to load mesh: \(error)")
            }
            self.name = name
            self.boundingBox = asset.boundingBox
        }
}

extension RenderableComponent{
    func render(encoder: MTLRenderCommandEncoder) {
      encoder.setVertexBuffer(
        mesh.vertexBuffers[0].buffer,
        offset: 0,
        index: 0)

      for submesh in mesh.submeshes {
        encoder.drawIndexedPrimitives(
          type: .triangle,
          indexCount: submesh.indexCount,
          indexType: submesh.indexType,
          indexBuffer: submesh.indexBuffer.buffer,
          indexBufferOffset: submesh.indexBuffer.offset
        )
      }
    }
}

struct UniformsComponent: Component {
    var uniforms: Uniforms  // Uniforms is defined in your Common.h
}

//MARK: - Camera Components

// Define a protocol for common camera functionality
protocol CameraComponent: Component {
    var projectionMatrix: float4x4 { get }
    mutating func updateAspect(_ aspect: Float)
    func calculateViewMatrix(transform: TransformComponent) -> float4x4
    mutating func update(deltaTime: Float, transform: inout TransformComponent)
    
}

// Example implementation for a PerspectiveCameraComponent:
struct PerspectiveCameraComponent: CameraComponent {
   
    var fieldOfView: Float
    var nearClippingPlane: Float
    var farClippingPlane: Float
    var aspectRatio: Float // This could be dynamic based on the viewport size.

    var projectionMatrix: float4x4 {
        return float4x4(projectionFov: fieldOfView, near: nearClippingPlane, far: farClippingPlane, aspect: aspectRatio, lhs: true)
    }

    mutating func updateAspect(_ aspect: Float) {
        aspectRatio = aspect
    }
    
    func calculateViewMatrix(transform: TransformComponent) -> float4x4 {
        let rotationMatrix = float4x4(rotationYXZ: transform.rotation)
        let translationMatrix = float4x4(translation: transform.position)
        return (rotationMatrix * translationMatrix).inverse
    }
    mutating func update(deltaTime: Float, transform: inout TransformComponent){
        let input = InputManager.shared
        // Calculate rotation
        let rotationChange = CGPoint(x: input.mouseDelta.x,
                                     y: input.mouseDelta.y)
        let rotationDelta = float2(Float(rotationChange.x), Float(rotationChange.y)) * deltaTime * Settings.rotationSpeed

        // Apply rotation around Y axis and a free rotation around X axis
        transform.rotation.y += rotationDelta.x
        transform.rotation.x += rotationDelta.y

        // Calculate zoom based on vertical mouse drag or scroll wheel
        let zoomDelta = Float(input.mouseDelta.y) * deltaTime * Settings.mouseScrollSensitivity
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
}

// Similar implementations would be needed for ArcballCameraComponent and OrthographicCameraComponent


struct ArcballCameraComponent : CameraComponent{
    var target: float3
    var distance: Float
    var minDistance: Float
    var maxDistance: Float
    var aspect: Float
    var fov: Float
    var near: Float
    var far: Float
   // var rotation: float3 // Managed externally, likely by a CameraControlSystem
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "ArcBallComponentComponent")

    init(target: float3, distance: Float, minDistance: Float, maxDistance: Float, aspect: Float, fov: Float, near: Float, far: Float) {
        self.target = target
        self.distance = distance
        self.minDistance = minDistance
        self.maxDistance = maxDistance
        self.aspect = aspect
        self.fov = fov
        self.near = near
        self.far = far
    }
    
    mutating func update(deltaTime: Float, transform: inout TransformComponent) {
        logger.info("Updating Arcball Camera")
        var constantTransform = transform
        logger.debug("position: \(constantTransform.position.x), \(constantTransform.position.y), \(constantTransform.position.z),\trotation:\(constantTransform.rotation.x),\(constantTransform.rotation.y),\(constantTransform.rotation.z)\n")
            let maxRotationX: CGFloat = 0.27 // don't rotate below the horizon
            let input = InputManager.shared
            let scrollSensitivity = Settings.mouseScrollSensitivity
        distance -= Float((input.mouseScrollDelta.x + input.mouseScrollDelta.y))
              * scrollSensitivity
            distance = min(maxDistance, distance)
            distance = max(minDistance, distance)
            input.mouseScrollDelta = .zero
            if input.leftMouseDown {
              let sensitivity = Settings.mousePanSensitivity
                let testRotation = CGFloat(transform.rotation.x) + input.mouseDelta.y * CGFloat(sensitivity)
              if testRotation < maxRotationX {
                  transform.rotation.x += Float(input.mouseDelta.y * CGFloat(sensitivity))
                  transform.rotation.x = max(-.pi / 2, min(transform.rotation.x, .pi / 2))
              }
                transform.rotation.y += Float(input.mouseDelta.x) * sensitivity
              input.mouseDelta = .zero
            }
            let rotateMatrix = float4x4(
                rotationYXZ: [-transform.rotation.x, transform.rotation.y, 0])
            let distanceVector = float4(0, 0, -distance, 0)
            let rotatedVector = rotateMatrix * distanceVector
            transform.position = target + rotatedVector.xyz
            constantTransform = transform
        logger.debug("At the end of arcball updating\n")
        logger.debug("position: \(constantTransform.position.x), \(constantTransform.position.y), \(constantTransform.position.z),\trotation:\(constantTransform.rotation.x),\(constantTransform.rotation.y),\(constantTransform.rotation.z)\n")
          }
    
   func calculateViewMatrix(transform: TransformComponent) -> float4x4 {
       if target == transform.position {
            return (float4x4(translation: target) * float4x4(rotationYXZ: transform.rotation)).inverse
        } else {
            return float4x4(eye: transform.position, center: target, up: [0, 1, 0])
        }
    }

    var projectionMatrix: float4x4 {
        return float4x4(projectionFov: fov, near: near, far: far, aspect: aspect, lhs: true)
    }

    mutating func updateAspect(_ aspect: Float) {
        self.aspect = aspect
    }
}




struct OrthographicCameraComponent: CameraComponent {
    
    var aspect: Float
    var viewSize: Float
    var near: Float
    var far: Float

    // Implement required properties and methods...
    func calculateViewMatrix(transform: TransformComponent) -> float4x4 {
        let translationMatrix = float4x4(translation: transform.position)
        let rotationMatrix = float4x4(rotation: transform.rotation)
        return (translationMatrix * rotationMatrix).inverse
    }
    
    var projectionMatrix: float4x4 {
        // Calculate projection matrix
        let aspectRatio = CGFloat(aspect)
        let viewSize = CGFloat(viewSize)
        let rect = CGRect(x: -viewSize * aspectRatio * 0.5,
                        y: viewSize * 0.5,
                        width: viewSize * aspectRatio,
                        height: viewSize)
        return float4x4(orthographic: rect, near: near, far: far)
    }
    mutating func updateAspect(_ aspect: Float) {
        self.aspect = aspect
    }
    mutating func update(deltaTime: Float, transform: inout TransformComponent){
        let input = InputManager.shared
        // Calculate panning based on drag
        let panChange = CGPoint(x: input.mouseDelta.x,
                                y: input.mouseDelta.y)
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


