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
    var selectedEntity: Entity? = nil
    let epsilon: Float = 0
    func nearlyEqual(a: Float, b: Float, epsilon: Float) -> Bool {
        return abs(a - b) < epsilon
    }
    // let rayDebugSystem : RayDebugSystem
    
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "InputSystem")
   
    func handleZoomGesture() {
        if InputManager.shared.mouseScroll.x != 0 {
            SceneManager.cameraManager.updateCameraDistance()
            ///look at the comment inside touchEnd method
            touchEnded()
        }
        
    }
    
    func update(deltaTime: Float, renderEncoder: any MTLRenderCommandEncoder) {
        handleZoomGesture()
        handleTouches(deltaTime: deltaTime)
        }

    private func handleTouches(deltaTime: Float) {
            // Check if a new touch has begun
        if InputManager.shared.touchState {
            touchMovedOrBegan(location: InputManager.shared.touchLocation!, deltaTime: deltaTime)
            return
            } 
        else {
            touchEnded()
            }


        }
    
    // Other methods...
    
    
    func touchMovedOrBegan(location: CGPoint, deltaTime: Float) {
        let touchLocation = location
        // Get the camera entity
            
            // Check if this is the first touch
        if InputManager.shared.previousTranslation == .zero {//it is began
                selectedEntity = handleTouchOnXZPlane(at: touchLocation)
                if let selected = selectedEntity {
                    // An object was touched, mark it as selected
                    var selectionComponent = SceneManager.entityManager.getComponent(type: SelectionComponent.self, for: selected)!
                    SceneManager.entityManager.addComponent(component: selectionComponent, to: selected)
                    logger.debug("Object:\(selected.name) has been selected")
                } else {
                    // No object was touched, the camera should be marked as selected
                    
                }
            }//began
            else {//it is moved
                // Similar logic as touchBegan, update camera position if it's the selected entity
                if let selected = selectedEntity{
                    //move item
                    moveEntityOnXZPlane(touchLocation: touchLocation)
                }else {
                    //move Camera
                   SceneManager.cameraManager.updateCameraTransformFromInputManager()
                    //later I need to check if the camera is selected
                }
                
                
            }//else moved
            
       
        
        
    }//touchedMovedOrBegan
    
    func touchEnded() {
        // Clear selected state or camera input as needed
        ///Im adding reset resetTouchDelta, because for some reason when Im adjusting the screen the system gestures are interfering(I guess) this solved the issue for now
        ///still with the ipad in stage manager it has the bug when swipe over the right bottom
        ///samething with the iphone when you hit the system bar at the bottom. I saw the guying on the developer vidoe talking about system gestures overriding your gestures.
        ///I have to listen to him again
        ///I tried teh deferSystemgesture from chat but still no use, same result
        ///I will move on since I have spent a lot of time and I might not need it at the end
        ///an idea that I will explore later is to use on the view when in switch app to call teh resettouch and switching to app call the resetrouch
        ///.onAppear{InputManager.shared.resetTouchDelta()} but for some reason it did not work also
        InputManager.shared.resetTouchDelta()
        selectedEntity = nil
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
    
    func moveEntityOnXZPlane(touchLocation: CGPoint) {
            guard let entity = selectedEntity,
                  var transform = SceneManager.entityManager.getComponent(type: TransformComponent.self, for: entity)
            else {
                    logger.warning("Something is wrong with the selected Entity")
                    return
                }
            let ndc = touchToNDC(touchPoint: touchLocation)
            let viewMatrix = SceneManager.getViewMatrix()!
            let projectionMatrix = SceneManager.getProjectionMatrix()
            let rayDirection = calculateRayDirection(ndc: ndc, projectionMatrix: projectionMatrix!, viewMatrix: viewMatrix)
            let rayOrigin = SceneManager.cameraManager.getActiveTransformComponent().position
            
            let intersectionPoint = rayPlaneIntersection(rayOrigin: rayOrigin, rayDirection: rayDirection, planeNormal: [0, 1, 0], planePoint: transform.position)
            transform.position = intersectionPoint
            SceneManager.entityManager.addComponent(component: transform, to: entity)
        }
    
    func rayPlaneIntersection(rayOrigin: float3, rayDirection: float3, planeNormal: float3, planePoint: float3) -> float3 {
            let d = dot(planeNormal, planePoint)
            let t = (d - dot(planeNormal, rayOrigin)) / dot(planeNormal, rayDirection)
            return rayOrigin + t * rayDirection
        }
}
