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

struct TransformComponent: Component {
    var position: float3
    var rotation: float3 // Use Euler angles for simplicity here; consider quaternions for complex rotations
    var scale: float3

    init(position: float3 = [0, 0, 0], rotation: float3 = [0, 0, 0], scale: float3 = [1, 1, 1]) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
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
        
        // Combine transformations
        return translationMatrix * rotationMatrix * scaleMatrix
    }
}


struct RenderableComponent: Component {
    var mesh: MTKMesh
    var texture: MTLTexture?
    let name: String
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
}

// Similar implementations would be needed for ArcballCameraComponent and OrthographicCameraComponent


struct ArcballCameraComponent: CameraComponent {
    
    var aspect: Float
    var fov: Float
    var near: Float
    var far: Float
    var target: float3
    var distance: Float
    var minDistance: Float
    var maxDistance: Float

    // Implement required properties and methods...
    func calculateViewMatrix(transform: TransformComponent) -> float4x4 {
        // Calculate camera's position based on the transform component
               let cameraPosition = transform.position
               let cameraOrientation = transform.rotation
               let rotatedUp = float3(0, 1, 0).rotatedBy(rotation: cameraOrientation)
               let lookAtPosition = target + rotatedUp * distance
               return float4x4(eye: cameraPosition, center: lookAtPosition, up: rotatedUp)
    }
    
    var projectionMatrix: float4x4 {
        // Calculate projection matrix
        float4x4(projectionFov: fov, near: near, far: far, aspect: aspect)
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
}


