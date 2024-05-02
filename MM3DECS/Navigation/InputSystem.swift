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
        guard let cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity) else {
            logger.warning("Camera component not found")
            return nil
        }
        
        logger.debug("in function handleTouchOnXZPlane Picking at \(point.x), \(point.y)")
        logger.debug("in function handleTouchOnXZPlane Camera position: \(cameraTransform.position)")
        
        let ndc = touchToNDC(touchPoint: point)
        let inverseVPMatrix = (cameraComponent.projectionMatrix * cameraComponent.calculateViewMatrix(transform: cameraTransform)).inverse

        let worldRayOrigin = unprojectToXZPlane(ndc: ndc, inverseVPMatrix: inverseVPMatrix)
        logger.debug("ndc: \(ndc), worldRayOrigin: \(worldRayOrigin)")

        // Assuming worldRay gives us a point on the XZ plane
        var closestEntity: Entity? = nil
        var minDistance: Float = Float.greatestFiniteMagnitude

        let entities = entityManager.entitiesWithComponents([RenderableComponent.self])
        
        for entity in entities {
            if let boundingBox = entityManager.getComponent(type: RenderableComponent.self, for: entity)?.boundingBox,
               let transform = entityManager.getComponent(type: TransformComponent.self, for: entity){
                let worldBoundBox = transformBoundingBox(boundingBox: boundingBox, with: transform.modelMatrix)
                if hitResult(boundingBox: worldBoundBox, contains: worldRayOrigin) {
                    let distance = (float3(transform.position.x - worldRayOrigin.x,
                                           transform.position.y - worldRayOrigin.y,
                                           transform.position.z - worldRayOrigin.z)).length // Calculate the distance to the entity's origin for depth sorting
                    if distance < minDistance {
                        minDistance = distance
                        closestEntity = entity
                    }
                }
            }
        }

        return closestEntity
    }
    
    func hitResult(boundingBox: MDLAxisAlignedBoundingBox, contains point: float3) -> Bool {
        logger.debug("min Bound: \(boundingBox.minBounds), maxBound: \(boundingBox.maxBounds)\npoint \(point)")
        return point.x >= boundingBox.minBounds.x && point.x <= boundingBox.maxBounds.x &&
               /*point.y >= boundingBox.minBounds.y && point.y <= boundingBox.maxBounds.y &&*/
               point.z >= boundingBox.minBounds.z && point.z <= boundingBox.maxBounds.z
    }
    
    func touchToNDC(touchPoint: CGPoint) -> float3 {
        let x = (2.0 * Float(touchPoint.x) / Float(Renderer.params.width)) - 1.0
        let y = 1.0 - (2.0 * Float(touchPoint.y) / Float(Renderer.params.height))
        return float3(x: x, y: y, z: 1.0)  // z = 1 for the purposes of ray casting
    }
    
    func unprojectToXZPlane(ndc: float3, inverseVPMatrix: matrix_float4x4) -> float3 {
        let nearClip = float4(ndc.x, ndc.y, 0, 1)  // Using -1 for near plane
        let farClip = float4(ndc.x, ndc.y, 1, 1)    // Using 1 for far plane

        let nearWorld = (inverseVPMatrix * nearClip).xyz
        let farWorld = (inverseVPMatrix * farClip).xyz

        logger.debug("nearWorld:\(nearWorld), farWorld:\(farWorld)")
        let rayOrigin = nearWorld
        var rayDirection = float3(x: farWorld.x - nearWorld.x,
                                  y: farWorld.y - nearWorld.y,
                                  z: farWorld.z - nearWorld.z)
        logger.debug("Clip Space Near: \(nearClip), Clip Space Far: \(farClip)")
        logger.debug("World Space Near: \(nearWorld), World Space Far: \(farWorld)")
        logger.debug("Ray Direction Before Normalization: \(farWorld - nearWorld)")
        
        rayDirection = rayDirection.normalized
        logger.debug("ray origin:\(rayOrigin), direction:\(rayDirection)")

        let planeY = Float(0.0)  // XZ plane
        let t = (planeY - rayOrigin.y) / rayDirection.y
        logger.debug("t= \(t)")

        if t >= 0 {
            return rayOrigin + t * rayDirection  // Intersection point on XZ plane
        } else {
            logger.debug("Intersection behind the camera or ray parallel to plane")
            return rayOrigin  // This would indicate an error or no intersection
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

        return MDLAxisAlignedBoundingBox(maxBounds: newMax, minBounds: newMin)
    }

    func checkIntersectionWithWorldRay(worldRayOrigin: float3, boundingBox: MDLAxisAlignedBoundingBox, objectTransform: TransformComponent) -> Bool {
        let worldBoundingBox = transformBoundingBox(boundingBox: boundingBox, with: objectTransform.modelMatrix)
        return hitResult(boundingBox: worldBoundingBox, contains: worldRayOrigin)
    }
    
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
