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


class InputSystem: SystemProtocol {
    var entityManager: EntityManager
    let cameraComponent:CameraComponent
    var selectedEntity: Entity? = nil
    
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "InputSystem")
    
    init(entityManager: EntityManager, cameraComponent:CameraComponent) {
        self.entityManager = entityManager
        self.cameraComponent = cameraComponent
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
                    selectedEntity = performPicking(at: touchLocation, using: cameraEntity)
                    if let selected = selectedEntity {
                        // An object was touched, mark it as selected
                        var selectionComponent = entityManager.getComponent(type: SelectionComponent.self, for: selected) ?? SelectionComponent(isSelected: false, distance: float3(10000,10000,10000))
                            selectionComponent.isSelected = true
                        entityManager.addComponent(component: selectionComponent, to: selected)
                    } else {
                        // No object was touched, the camera should be marked as selected
                        cameraInput.dragStartPosition = nil//touchLocation
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

    private func performPicking(at location: CGPoint, using camera: Entity) -> Entity? {
        guard let cameraEntity = entityManager.entities(for: CameraInputComponent.self).first,
              let cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity) else {
            logger.warning("Camera component not found")
            return nil
        }
        
        logger.debug("Picking at \(location.x), \(location.y)")
        logger.debug("Camera position: \(cameraTransform.position)")
        
        //logger.debug("Ray direction: \(ray.direction)")
        
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self])
        for entity in entities {
            if let renderable = entityManager.getComponent(type: RenderableComponent.self, for: entity)
                {
                calculateRayIntersction(from: entity, to: cameraTransform, at: location)
            }
        }
        return nil
    }

    private func calculateRayIntersction(from entity: Entity, to camera: TransformComponent, at point: CGPoint) {
        if let selection = entityManager.getComponent(type: SelectionComponent.self, for: entity)
        {
            // Convert CGPoint to NDC
            let clipX = Float(2 * point.x) / Renderer.params.width - 1;
            let clipY = Float(1 - (2 * point.y)) / Renderer.params.height;
            let clipCoords = float4(clipX, clipY, 0, 1) // Assume clip space is hemicube, -Z is into the screen
            
            var eyeRayDir = cameraComponent.projectionMatrix * clipCoords
            eyeRayDir.z = 1
            eyeRayDir.w = 0
            
            
            let currentViewMatrix = cameraComponent.calculateViewMatrix(transform: camera)
            let worldRayDir = float4(currentViewMatrix * eyeRayDir).xyz
            let direction = worldRayDir.normalized
            
            
            let eyeRayOrigin = float4(0, 0, 0, 1);
            let origin = (currentViewMatrix * eyeRayOrigin).xyz;
            
            let entityTransformComponent = entityManager.getComponent(type: TransformComponent.self, for: entity)
            
            let ray = Ray(origin: ((entityTransformComponent?.modelMatrix.inverse)! * float4(origin.x,origin.y,origin.z,1)).xyz,
                          direction: direction)
            
            if let boundingBox = entityManager.getComponent(type: RenderableComponent.self, for: entity)!.boundingBox
            {
                
                ray.intersects(with: boundingBox, with: selection)
            }
            
            
            // Unproject NDC to world coordinates
            //            let inverseProjection = cameraComponent.projectionMatrix.inverse
            //            let eyeCoords = inverseProjection * clipCoords
            //            let rayDir = float3(eyeCoords.x, eyeCoords.y, -1)
            //            let worldRayDir = (cameraComponent.calculateViewMatrix(transform: camera).inverse * float4(rayDir, 0)).xyz.normalized
            
            //            return Ray(origin: camera.position, direction: worldRayDir)
        }//if let
    }
}
