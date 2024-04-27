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
                        var selectionComponent = entityManager.getComponent(type: SelectionComponent.self, for: selected) ?? SelectionComponent(isSelected: false)
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
            logger.debug("Camera component not found")
            return nil
        }

        logger.debug("Picking at \(location.x), \(location.y)")
        logger.debug("Camera position: \(cameraTransform.position)")
        let ray = calculateRay(from: cameraTransform, at: location)
        logger.debug("Ray direction: \(ray.direction)")
        
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self])
        for entity in entities {
            if let renderable = entityManager.getComponent(type: RenderableComponent.self, for: entity),
               ray.intersects(with: renderable.boundingBox) {
                return entity
            }
        }
        return nil
    }

    private func calculateRay(from camera: TransformComponent, at point: CGPoint) -> Ray {
        // Convert CGPoint to NDC
        let ndcX = (2.0 * point.x / UIScreen.main.bounds.width) - 1.0
        let ndcY = 1.0 - (2.0 * point.y / UIScreen.main.bounds.height)
        let clipCoords = SIMD4<Float>(Float(ndcX), Float(ndcY), 1.0, 1.0)

        // Unproject NDC to world coordinates
        let inverseProjection = cameraComponent.projectionMatrix.inverse
        let eyeCoords = inverseProjection * clipCoords
        let rayDir = float3(eyeCoords.x, eyeCoords.y, -1)
        let worldRayDir = (cameraComponent.calculateViewMatrix(transform: camera).inverse * float4(rayDir, 0)).xyz.normalized

        return Ray(origin: camera.position, direction: worldRayDir)
    }
}
