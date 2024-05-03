//
//  InputSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/04/2024.
//
import Foundation
import MetalKit
import SwiftUI
import os.log
import simd

class InputSystem: SystemProtocol {
    var entityManager: EntityManager
    let cameraEntity: Entity
    var cameraComponent:CameraComponent
    var selectedEntity: Entity? = nil
    let epsilon: Float = 0
    func nearlyEqual(a: Float, b: Float, epsilon: Float) -> Bool {
        return abs(a - b) < epsilon
    }
    // let rayDebugSystem : RayDebugSystem
    
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "InputSystem")
    
    init(entityManager: EntityManager, cameraEntity: Entity){//, rayDebugSystem: RayDebugSystem) {
        self.entityManager = entityManager
        self.cameraEntity = cameraEntity
        self.cameraComponent = entityManager.getComponent(type: PerspectiveCameraComponent.self, for: cameraEntity)!
        // self.rayDebugSystem = rayDebugSystem
    }
    
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: any MTLRenderCommandEncoder) {
        //not implemented
        self.entityManager = entityManager
    }
    
    // Other methods...
    
    
    func touchMovedOrBegan(gesture: DragGesture.Value) {
        let touchLocation = gesture.location
        // Get the camera entity
        if let cameraEntity = entityManager.entities(for: CameraInputComponent.self).first,
           var cameraInput = entityManager.getComponent(type: CameraInputComponent.self, for: cameraEntity) {
            
            // Check if this is the first touch
            if cameraInput.dragStartPosition == nil {//it is began
                selectedEntity = handleTouchOnXZPlane(at: touchLocation, using: cameraEntity)
                if let selected = selectedEntity {
                    // An object was touched, mark it as selected
                    var selectionComponent = entityManager.getComponent(type: SelectionComponent.self, for: selected)!
                    entityManager.addComponent(component: selectionComponent, to: selected)
                    logger.debug("Object has been selected")
                } else {
                    // No object was touched, the camera should be marked as selected
                    cameraInput.dragStartPosition = touchLocation
                    entityManager.addComponent(component: cameraInput, to: cameraEntity)
                }
            }//began
            else {//it is moved
                // Similar logic as touchBegan, update camera position if it's the selected entity
                cameraInput.dragCurrentPosition = touchLocation
                entityManager.addComponent(component: cameraInput, to: cameraEntity)
                //later I need to check if the camera is selected
                
            }//else moved
            
        }
        
        
    }//touchedMovedOrBegan
    
    func touchEnded(gesture: DragGesture.Value) {
        // Clear selected state or camera input as needed
        if let cameraEntity = entityManager.entities(for: CameraInputComponent.self).first {
            var cameraInput = entityManager.getComponent(type: CameraInputComponent.self, for: cameraEntity) ?? CameraInputComponent()
            cameraInput.dragStartPosition = nil
            cameraInput.dragCurrentPosition = nil
            cameraInput.lastTouchPosition = nil
            entityManager.addComponent(component: cameraInput, to: cameraEntity)
            selectedEntity = nil
            self.cameraComponent = entityManager.getComponent(type: PerspectiveCameraComponent.self, for: cameraEntity)!
        }
    }
    
    
    
    func handleTouchOnXZPlane(at point: CGPoint, using cameraEntity: Entity) -> Entity? {
        guard let cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity) else {
            logger.warning("Camera components not found")
            return nil
        }
        
        logger.debug("in function handleTouchOnXZPlane Picking at \(point.x), \(point.y)")
        logger.debug("in function handleTouchOnXZPlane Camera position: \(cameraTransform.position)")
        
        let ndc = touchToNDC(touchPoint: point)
        let viewMatrix = cameraComponent.calculateViewMatrix(transform: cameraTransform)
        let projectionMatrix = cameraComponent.projectionMatrix
        
        let rayDirection = calculateRayDirection(ndc: ndc, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix)
        let rayOrigin = cameraTransform.position
        
        logger.debug("ndc: \(ndc), rayOrigin: \(rayOrigin), rayDirection: \(rayDirection)")
        
        var closestEntity: Entity? = nil
        var minDistance: Float = Float.greatestFiniteMagnitude
        
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self])
        
        for entity in entities {
            if let boundingBox = entityManager.getComponent(type: RenderableComponent.self, for: entity)?.boundingBox,
               let transform = entityManager.getComponent(type: TransformComponent.self, for: entity) {
                let modelMatrix = transform.modelMatrix
                let modelMatrixInverse = modelMatrix.inverse
                
                let localRayOrigin = (modelMatrixInverse * float4(rayOrigin, 1.0)).xyz
                let localRayDirection = (modelMatrixInverse * float4(rayDirection, 0.0)).xyz
                
                let ray = Ray(origin: localRayOrigin, direction: localRayDirection)
                
                logger.debug("Checking for entity: \(entity.name)")
                let bounds = [boundingBox.minBounds, boundingBox.maxBounds]
                if hitResult(bounds: bounds, ray: ray) {
                    let distance = length(transform.position - rayOrigin)
                    if distance < minDistance {
                        minDistance = distance
                        closestEntity = entity
                        logger.debug("Hit: \(entity.name)")
                    }
                } else {
                    logger.debug("\(entity.name) miss")
                }
            }
        }
        
        return closestEntity
    }
    
    func hitResult(bounds: [float3], ray: Ray) -> Bool {
        let tMin = float3(x: Float(bounds[0].x - ray.origin.x) / ray.direction.x,
                          y: Float(bounds[0].y - ray.origin.y) / ray.direction.y,
                          z: Float(bounds[0].z - ray.origin.z) / ray.direction.z)
        
        let tMax = float3(x: Float(bounds[1].x - ray.origin.x) / ray.direction.x,
                          y: Float(bounds[1].y - ray.origin.y) / ray.direction.y,
                          z: Float(bounds[1].z - ray.origin.z) / ray.direction.z)
        let t1 = min(tMin, tMax)
        let t2 = max(tMin, tMax)
        logger.debug("tmin: \(tMin),\tmax:\(tMax)")
        logger.debug("BoundingBox: min:\(bounds[0])\tmax:\(bounds[1])")
        logger.debug("t1: \(t1),\tt2: \(t2)\n")

        let tNear = max(max(t1.x, t1.y), t1.z)
        let tFar = min(min(t2.x, t2.y), t2.z)
        logger.debug("tNear: \(tNear),\ttFar: \(tFar)")

        return nearlyEqual(a: tNear, b: tFar, epsilon: epsilon) || (tNear <= tFar && tFar >= 0)
    }
    
//    func hitResult(boundingBox: MDLAxisAlignedBoundingBox, ray: Ray) -> Bool {
//        let tMin = (boundingBox.minBounds - ray.origin) / ray.direction
//        let tMax = (boundingBox.maxBounds - ray.origin) / ray.direction
//        logger.debug("tmin: \(tMin),\tmax:\(tMax)")
//        logger.debug("BoundingBox: min:\(boundingBox.minBounds)\tmax:\(boundingBox.maxBounds)")
//        let t1 = min(tMin, tMax)
//        let t2 = max(tMin, tMax)
//        logger.debug("t1: \(t1),\tt2: \(t2)\n")
//
//        let tNear = max(max(t1.x, t1.y), t1.z)
//        let tFar = min(min(t2.x, t2.y), t2.z)
//
//        logger.debug("tNear: \(tNear),\ttFar: \(tFar)")
//
//        return tNear <= tFar && tFar >= 0
//    }
    
//    func calculateRayDirection(ndc: float3, projectionMatrix: float4x4, viewMatrix: float4x4) -> float3 {
//        let clipCoords = float4(ndc.x, ndc.y, 0, 1.0) // Use -1.0 if your NDC z ranges from -1 to 1
//        let eyeCoords = projectionMatrix.inverse * clipCoords
//        let worldCoords = (viewMatrix.inverse * float4(eyeCoords.x, eyeCoords.y, 1.0, 0.0)).xyz
//        return normalize(worldCoords)
//    }
    
    func calculateRayDirection(ndc: float3, projectionMatrix: float4x4, viewMatrix: float4x4) -> float3 {
        // Transform NDC to clip space; Metal uses left-handed coordinate system
        let clipCoords = float4(ndc.x, ndc.y, -1.0, 1.0)  // Setting z to -1.0 to point from the near plane into the scene

        // Apply the inverse of the projection matrix to go from clip space to eye space
        var eyeCoords = projectionMatrix.inverse * clipCoords
        eyeCoords.z = 1.0   // We set z to 1.0 to point forwards in eye space
        eyeCoords.w = 0.0   // Make it a direction vector

        // Transform the eye space coordinates to world space using the inverse of the view matrix
        let worldRayDir = normalize((viewMatrix.inverse * eyeCoords).xyz)
        return worldRayDir
    }
    
    func touchToNDC(touchPoint: CGPoint) -> float3 {
        let clipX = (2.0 * Float(touchPoint.x) / Float(Renderer.params.width)) - 1.0
        let clipY = 1.0 - (2.0 * Float(touchPoint.y) / Float(Renderer.params.height))
        return float3(x: clipX, y: clipY, z: 0.0)  // Assume clip space is hemicube, -Z is into the screen
    }
    
//    func unprojectToWorldSpace(ndc: float3, viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4) -> float3 {
//        let clipCoords = float4(ndc.x, ndc.y, 1.0, 1.0) // z set to 1.0 to define a direction vector
//        let invVP = (projectionMatrix * viewMatrix).inverse
//        let worldCoords = invVP * clipCoords
//        return (worldCoords / worldCoords.w).xyz // Ensuring homogenous coordinate normalization
//    }
    
    
}
