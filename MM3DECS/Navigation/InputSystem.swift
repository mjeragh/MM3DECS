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
        self.cameraComponent = entityManager.getComponent(type: ArcballCameraComponent.self, for: cameraEntity)!
        // self.rayDebugSystem = rayDebugSystem
    }
    
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: any MTLRenderCommandEncoder) {
        //not implemented
       
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
                    logger.debug("Object:\(selected.name) has been selected")
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
            self.cameraComponent = entityManager.getComponent(type: ArcballCameraComponent.self, for: cameraEntity)!
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
        //logger.debug("in function handleTouchOnXZPlane cameracomponent aspect: \(cameraComponent.aspect)")
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
                if ray.intersects(with: bounds) {
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
    
  
    func touchToNDC(touchPoint: CGPoint) -> float3 {
        let clipX = (2.0 * Float(touchPoint.x) / Float(Renderer.params.width)) - 1.0
        let clipY = 1.0 - (2.0 * Float(touchPoint.y) / Float(Renderer.params.height))
        return float3(x: clipX, y: clipY, z: 0.0)  // Assume clip space is hemicube, -Z is into the screen
    }
    
    
    func calculateRayDirection(ndc: float3, projectionMatrix: float4x4, viewMatrix: float4x4) -> float3 {
        // Transform NDC to clip space; Metal uses left-handed coordinate system
        let clipCoords = float4(ndc.x, ndc.y, 0, 1.0)  // Setting z to -1.0 to point from the near plane into the scene

        // Apply the inverse of the projection matrix to go from clip space to eye space
        var eyeCoords = projectionMatrix.inverse * clipCoords
        eyeCoords.z = 1.0   // We set z to 1.0 to point forwards in eye space
        eyeCoords.w = 0.0   // Make it a direction vector

        // Transform the eye space coordinates to world space using the inverse of the view matrix
        let worldRayDir = normalize((viewMatrix.inverse * eyeCoords).xyz)
        return worldRayDir
    }
    
}
