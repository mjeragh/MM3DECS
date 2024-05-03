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
                if ray.intersects(with: boundingBox) {
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
        logger.debug("BoundingBox: min:\(boundingBox.minBounds)\tmax:\(boundingBox.maxBounds)")
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
    
    
}
