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
    let cameraComponent:CameraComponent
    var selectedEntity: Entity? = nil
   // let rayDebugSystem : RayDebugSystem
    
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "InputSystem")
    
    init(entityManager: EntityManager, cameraComponent:CameraComponent){//, rayDebugSystem: RayDebugSystem) {
        self.entityManager = entityManager
        self.cameraComponent = cameraComponent
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
                }
    }

    
    
    func handleTouchOnXZPlane(at point: CGPoint, using cameraEntity: Entity) -> Entity? {
        guard let cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity),
              let cameraComponent = entityManager.getComponent(type: PerspectiveCameraComponent.self, for: cameraEntity) else {
            logger.warning("Camera components not found")
            return nil
        }
        
        logger.debug("in function handleTouchOnXZPlane Picking at \(point.x), \(point.y)")
        logger.debug("in function handleTouchOnXZPlane Camera position: \(cameraTransform.position)")
        
        let ndc = touchToNDC(touchPoint: point)
        let viewMatrix = cameraComponent.calculateViewMatrix(transform: cameraTransform)
        let projectionMatrix = cameraComponent.projectionMatrix
        
        let rayDirection = unprojectToWorldSpace(ndc: ndc, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
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
                if hitResult(boundingBox: boundingBox, ray: ray) {
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
    
    func hitResult(boundingBox: MDLAxisAlignedBoundingBox, ray: Ray) -> Bool {
        let tMin = (boundingBox.minBounds - ray.origin) / ray.direction
        let tMax = (boundingBox.maxBounds - ray.origin) / ray.direction
        logger.debug("tmin: \(tMin),\tmax:\(tMax)")
        
        let t1 = min(tMin, tMax)
        let t2 = max(tMin, tMax)
        logger.debug("t1: \(t1),\tt2: \(t2)\n")
        
        let tNear = max(max(t1.x, t1.y), t1.z)
        let tFar = min(min(t2.x, t2.y), t2.z)
        
        logger.debug("tNear: \(tNear),\ttFar: \(tFar)")
        
        return tNear <= tFar && tFar >= 0
    }
    
    func touchToNDC(touchPoint: CGPoint) -> float3 {
        let clipX = (2.0 * Float(touchPoint.x) / Float(Renderer.params.width)) - 1.0
        let clipY = 1.0 - (2.0 * Float(touchPoint.y) / Float(Renderer.params.height))
        return float3(x: clipX, y: clipY, z: 0.0)  // Assume clip space is hemicube, -Z is into the screen
    }
    
    func unprojectToWorldSpace(ndc: float3, viewMatrix: float4x4, projectionMatrix: float4x4) -> float3 {
        let clipCoords = float4(ndc.x, ndc.y, 0.0, 1.0)
        
        var eyeRayDir = projectionMatrix.inverse * clipCoords
        eyeRayDir.z = 1.0
        eyeRayDir.w = 0.0
        
        let worldRayDir = (viewMatrix.inverse * eyeRayDir).xyz
        let direction = normalize(worldRayDir)
        
        return direction
    }
    
    
    func unprojectToXZPlane(ndc: float3, inverseVPMatrix: matrix_float4x4) -> float3 {
        let nearClip = float4(ndc.x, ndc.y, 0, 1)  // Near plane at zero to ensure we get a direction
        let farClip = float4(ndc.x, ndc.y, 1, 1)   // Far plane at one

        let nearWorld = (inverseVPMatrix * nearClip).xyz
        let farWorld = (inverseVPMatrix * farClip).xyz
        
        logger.debug("Clip Space Near: \(nearClip), Clip Space Far: \(farClip)")
        logger.debug("World Space Near: \(nearWorld), World Space Far: \(farWorld)")
        

        logger.debug("nearWorld:\(nearWorld), farWorld:\(farWorld)")
        var rayDirection = float3(x: farWorld.x - nearWorld.x,
                                  y: farWorld.y - nearWorld.y,
                                  z: farWorld.z - nearWorld.z)
        if rayDirection.length == 0 {
            logger.error("Invalid ray direction; both near and far world points are the same.")
            return nearWorld  // Return a default or handle this case appropriately
        }

        logger.debug("Ray Direction Before Normalization: \(rayDirection)")
        rayDirection = rayDirection.normalized
        logger.debug("ray origin:\(nearWorld), direction:\(rayDirection)")

        let planeY = Float(0.0)  // XZ plane
        let t = (planeY - nearWorld.y) / rayDirection.y
        logger.debug("t= \(t)")

        if t >= 0 {
            logger.debug("before return the answer: \(nearWorld + t * rayDirection)")
            return nearWorld + t * rayDirection  // Intersection point on XZ plane
        } else {
            logger.debug("Intersection behind the camera or ray parallel to plane")
            return nearWorld  // This would indicate an error or no intersection
        }
    }

    
    func transformBoundingBox(boundingBox: MDLAxisAlignedBoundingBox, with transform: matrix_float4x4) -> MDLAxisAlignedBoundingBox {
        // Transform the minimum and maximum points
        let minPoint = float4(boundingBox.minBounds, 1)
        let maxPoint = float4(boundingBox.maxBounds, 1)

        let transformedMin = (transform * minPoint).xyz
        let transformedMax = (transform * maxPoint).xyz

        // Recalculate the new bounds in case rotation has occurred
        let newMin = min(transformedMin, transformedMax)
        let newMax = max(transformedMin, transformedMax)

        logger.debug("Original Min: \(boundingBox.minBounds), Max: \(boundingBox.maxBounds)")
            logger.debug("Transformed Min: \(newMin), Max: \(newMax)")
        return MDLAxisAlignedBoundingBox(maxBounds: newMax, minBounds: newMin)
    }

//    func checkIntersectionWithWorldRay(worldRayOrigin: float3, boundingBox: MDLAxisAlignedBoundingBox, objectTransform: TransformComponent) -> Bool {
//        let worldBoundingBox = transformBoundingBox(boundingBox: boundingBox, with: objectTransform.modelMatrix)
//        return hitResult(boundingBox: worldBoundingBox, contains: worldRayOrigin)
//    }
    
    func intersectionWithXZPlane(ray: Ray, planeY: Float = 0.0) -> float3? {
        if ray.direction.y == 0 {
            logger.debug("Ray is parallel to the XZ plane.")
            return nil
        }

        let t = (planeY - ray.origin.y) / ray.direction.y
        if t < 0 {
            logger.debug("Intersection is behind the ray's origin.")
            return nil
        }

        return ray.origin + ray.direction * t
    }
}
