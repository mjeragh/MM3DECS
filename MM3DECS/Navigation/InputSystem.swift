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
//    var entityManager: EntityManager
//    let cameraEntity: Entity
//    var cameraComponent:CameraComponent
    var selectedEntity: Entity? = nil
    let epsilon: Float = 0
    func nearlyEqual(a: Float, b: Float, epsilon: Float) -> Bool {
        return abs(a - b) < epsilon
    }
    // let rayDebugSystem : RayDebugSystem
    
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "InputSystem")
   
    
    func update(deltaTime: Float, renderEncoder: any MTLRenderCommandEncoder) {
            handleTouches(deltaTime: deltaTime)
        }

        private func handleTouches(deltaTime: Float) {
            // Check if a new touch has begun
            if InputManager.shared.touchStarted {
                touchMovedOrBegan(location: InputManager.shared.touchLocation!, deltaTime: deltaTime)
                return
            }

            // Check for ongoing touch movement
            if InputManager.shared.isTouchActive && !InputManager.shared.touchEnded {
                touchMovedOrBegan(location: InputManager.shared.touchLocation!, deltaTime: deltaTime)
            }

            // Check if the touch has ended
            if InputManager.shared.touchEnded {
                touchEnded()
            }

        }
    
    // Other methods...
    
    
    func touchMovedOrBegan(location: CGPoint, deltaTime: Float) {
        let touchLocation = location
        // Get the camera entity
        
        var cameraInput = SceneManager.cameraManager.getActiveCameraInputComponent()
            
            // Check if this is the first touch
            if cameraInput.dragStartPosition == nil {//it is began
                selectedEntity = handleTouchOnXZPlane(at: touchLocation)
                if let selected = selectedEntity {
                    // An object was touched, mark it as selected
                    var selectionComponent = SceneManager.entityManager.getComponent(type: SelectionComponent.self, for: selected)!
                    SceneManager.entityManager.addComponent(component: selectionComponent, to: selected)
                    logger.debug("Object:\(selected.name) has been selected")
                } else {
                    // No object was touched, the camera should be marked as selected
                    cameraInput.dragStartPosition = touchLocation
                    SceneManager.entityManager.addComponent(component: cameraInput, to: SceneManager.cameraManager.getActiveCameraEntity()!)
                }
            }//began
            else {//it is moved
                // Similar logic as touchBegan, update camera position if it's the selected entity
                if let selected = selectedEntity{
                    //move item
                }else {
                    //move Camera
//                    cameraInput.dragCurrentPosition = touchLocation
                    var cameraComponent = SceneManager.cameraManager.getActiveCameraComponent()
                    var transform = SceneManager.cameraManager.getActiveTransformComponent()
                    logger.debug("camera Movement:\(transform.position.x), \(transform.position.y), \(transform.position.z)\n")
                    cameraComponent?.update(deltaTime: deltaTime, transform: &transform)
                    logger.debug("camera Movement after update:\(transform.position.x), \(transform.position.y), \(transform.position.z)\n")
                    SceneManager.cameraManager.moveActiveCamera(to: transform)
                    //later I need to check if the camera is selected
                }
                
                
            }//else moved
            
       
        
        
    }//touchedMovedOrBegan
    
    func touchEnded() {
        // Clear selected state or camera input as needed
        var cameraInput = SceneManager.cameraManager.getActiveCameraInputComponent()
            cameraInput.dragStartPosition = nil
            cameraInput.dragCurrentPosition = nil
            cameraInput.lastTouchPosition = nil
        SceneManager.entityManager.addComponent(component: cameraInput, to: SceneManager.cameraManager.getActiveCameraEntity()!)
            selectedEntity = nil
            //self.cameraComponent = entityManager.getComponent(type: ArcballCameraComponent.self, for: cameraEntity)!
    }
    
    
    
    func handleTouchOnXZPlane(at point: CGPoint) -> Entity? {
        let cameraTransform = SceneManager.cameraManager.getActiveTransformComponent()
        
//        logger.debug("in function handleTouchOnXZPlane Picking at \(point.x), \(point.y)")
//        logger.debug("in function handleTouchOnXZPlane Camera position: \(cameraTransform.position)")
        
        let ndc = touchToNDC(touchPoint: point)
        let viewMatrix = SceneManager.getViewMatrix()!
        let projectionMatrix = SceneManager.getProjectionMatrix()
        //logger.debug("in function handleTouchOnXZPlane cameracomponent aspect: \(cameraComponent.aspect)")
        let rayDirection = calculateRayDirection(ndc: ndc, projectionMatrix: projectionMatrix!, viewMatrix: viewMatrix)
        let rayOrigin = cameraTransform.position
        
//        logger.debug("ndc: \(ndc), rayOrigin: \(rayOrigin), rayDirection: \(rayDirection)")
        
        var closestEntity: Entity? = nil
        var minDistance: Float = Float.greatestFiniteMagnitude
        
        let entities = SceneManager.getEntitesToBeSelected()
        
        for entity in entities {
            if let boundingBox = SceneManager.entityManager.getComponent(type: RenderableComponent.self, for: entity)?.boundingBox,
               let transform = SceneManager.entityManager.getComponent(type: TransformComponent.self, for: entity) {
                let modelMatrix = transform.modelMatrix
                let modelMatrixInverse = modelMatrix.inverse
                
                let localRayOrigin = (modelMatrixInverse * float4(rayOrigin, 1.0)).xyz
                let localRayDirection = (modelMatrixInverse * float4(rayDirection, 0.0)).xyz
                
                let ray = Ray(origin: localRayOrigin, direction: localRayDirection)
                
//                logger.debug("Checking for entity: \(entity.name)")
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
