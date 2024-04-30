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
    let rayDebugSystem : RayDebugSystem
    
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "InputSystem")
    
    init(entityManager: EntityManager, cameraComponent:CameraComponent, rayDebugSystem: RayDebugSystem) {
        self.entityManager = entityManager
        self.cameraComponent = cameraComponent
        self.rayDebugSystem = rayDebugSystem
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

    private func performPicking(at location: CGPoint, using cameraEntity: Entity) -> Entity? {
        guard let cameraTransform = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity) else {
            logger.warning("Camera component not found")
            return nil
        }
        
        logger.debug("in function performPicking Picking at \(location.x), \(location.y)")
        logger.debug("in function performPicking Camera position: \(cameraTransform.position)")
        
        //logger.debug("Ray direction: \(ray.direction)")
        
        let entities = entityManager.entitiesWithComponents([RenderableComponent.self])
        for entity in entities {
                calculateRayIntersection(from: entity, to: cameraTransform, at: location)
            if let select = entityManager.getComponent(type: SelectionComponent.self, for: entity){
                if select.isSelected {
                    //check it is the shortest
                    logger.warning("Something is slected")
                    if selectedEntity == nil {
                        selectedEntity = entity
                    } else{
                        if (select.distance < entityManager.getComponent(type: SelectionComponent.self, for: selectedEntity!)!.distance){
                            
                        }
                    }
                }
            }
        }
        return nil
    }

    private func calculateRayIntersection(from entity: Entity, to camera: TransformComponent, at point: CGPoint) {
        if var selection = entityManager.getComponent(type: SelectionComponent.self, for: entity)
        {
            // Convert CGPoint to NDC
            let clipX = Float(2 * Float(point.x)) / Renderer.params.width - 1 //ndcX
            let clipY = Float(1 - Float((2 * point.y))) / Renderer.params.height //ndcY
            let clipCoords = float4(clipX, clipY, 0, 1) // Assume clip space is hemicube, -Z is into the screen the depth range is from [0,1] could be [-1,1]
            //[0,1] and z is 1 from previous projects
            var eyeRayDir = cameraComponent.projectionMatrix * clipCoords
            eyeRayDir.z = 1 //Assuming the camera looks along the Z in NDC
            eyeRayDir.w = 0
            
            
            let currentViewMatrix = cameraComponent.calculateViewMatrix(transform: camera)
            let worldRayDir = float4(currentViewMatrix * eyeRayDir).xyz
            let direction = worldRayDir.normalized
            
            
            let eyeRayOrigin = float4(0, 0, 0, 1);
            let origin = (currentViewMatrix * eyeRayOrigin).xyz;
            
            let entityTransformComponent = entityManager.getComponent(type: TransformComponent.self, for: entity)
            let inverseDirection = (camera.position - entityTransformComponent!.position).normalized
            logger.debug("inverseDirection computation: \(inverseDirection)\n")
            //testRayIntersectsBoundingBox()
            //testRayIntersectsObjectBoundingBoxThetaPhi()
            var ray = Ray(origin: ((entityTransformComponent?.modelMatrix.inverse)! * float4(origin.x,origin.y,origin.z,1)).xyz,
                          direction: direction)
            ray.INVdirection = inverseDirection
            logger.debug("\nray: origin\(ray.origin), direction:\(ray.direction)")
            
            // Prepare ray for rendering (for debugging purposes)
            let debugModeEnabled = true
            if debugModeEnabled {
                rayDebugSystem.updateCameraProjectionMatrix(projectionMatrix: cameraComponent.projectionMatrix)
                rayDebugSystem.updateLineVertices(vertices: ray.vertexData())
            }
            
            if let boundingBox = entityManager.getComponent(type: RenderableComponent.self, for: entity)?.boundingBox
            {
                let tmin = boundingBox.minBounds;
                let tmax = boundingBox.maxBounds
                selection.isSelected = false
                
                let bounds = [tmin, tmax]
                
                ray.intersects(with: bounds, with: &selection)
            }
            
        }//if let
    }
    
    func testRayIntersectsBoundingBox() {
        let ray = Ray(origin: float3(0, 0, 0), direction: float3(1, 0, 0).normalized)
        var selection = SelectionComponent()
        let bounds = [float3(-1, -1, -1), float3(1, 1, 1)]
        
        ray.intersects(with: bounds, with: &selection)
        
        assert(selection.isSelected, "Ray should intersect with the bounding box.")
    }
    
    func testRayIntersectsObjectBoundingBox() {
        // Setup camera
        let aspect = Float(16) / Float(9)  // Adjust aspect ratio as necessary
        let cameraComponent = ArcballCameraComponent(aspect: aspect, fov: Float(70).degreesToRadians, near: 0.1, far: 1000, target: [0, 0, 0], distance: 15, minDistance: 1, maxDistance: 120)
        
        // Calculate camera world position and view direction
        let cameraPosition = float3(0, 0, cameraComponent.distance)  // Position in front of the target
        let viewDirection = float3(0, 0, -1)  // Looking towards the target
        
        // Setup object transform and bounding box
        let objectTransform = TransformComponent(position: float3(5, 0.6, 0), rotation: float3(0, 0, 0), scale: float3(1, 1, 1))
        let bounds = [float3(-5.058, -4.922, -5.0), float3(4.942, 4.589, 5.0)]
        
        // Create ray
        let rayDirection = normalize(objectTransform.position - cameraPosition)
        let ray = Ray(origin: cameraPosition, direction: rayDirection)
        
        // Perform intersection test
        var selection = SelectionComponent()
        ray.intersects(with: bounds, with: &selection)
        
        // Assert if ray intersects
        assert(selection.isSelected, "Ray should intersect with the bounding box.")
        logger.debug("Intersection Distance: \(selection.distance)")
    }
    
    func testRayIntersectsObjectBoundingBoxThetaPhi() {
        // Setup camera
        let aspect = Float(16) / Float(9)  // Adjust aspect ratio as necessary
        let cameraComponent = ArcballCameraComponent(aspect: aspect, fov: Float(70).degreesToRadians, near: 0.1, far: 1000, target: [0, 0, 0], distance: 15, minDistance: 1, maxDistance: 120)

        // Assuming the camera is looking directly at the target and rotating around it
        let target = float3(0, 0, 0)  // The point the camera is looking at
        let theta = Float.pi  // Horizontal angle in radians
        let phi = -Float.pi  // Vertical angle in radians

        // Calculate camera's position relative to the target
        let sinPhi = Float(sin(phi))
        let cosPhi =    Float(cos(phi))
        let sinTheta =  Float(sin(theta))
        let cosTheta =  Float(cos(theta))

        let x = target.x + cameraComponent.distance * sinPhi * cosTheta
        let y = target.y + cameraComponent.distance * sinPhi * sinTheta
        let z = target.z + cameraComponent.distance * cosPhi

        let cameraPosition = float3(x, y, z)

        // Compute view direction
        let viewDirection = normalize(target - cameraPosition)  // Direction from camera to the target

        // Setup object transform and bounding box
        let objectTransform = TransformComponent(position: float3(5, 0.6, 0), rotation: float3(0, 0, 0), scale: float3(1, 1, 1))
        let bounds = [float3(-5.058, -4.922, -5.0), float3(4.942, 4.589, 5.0)]

        // Create ray
        let rayDirection = normalize(objectTransform.position - cameraPosition)
        let ray = Ray(origin: cameraPosition, direction: rayDirection)

        // Perform intersection test
        var selection = SelectionComponent()
        ray.intersects(with: bounds, with: &selection)

        // Assert if ray intersects
        assert(selection.isSelected, "Ray should intersect with the bounding box.")
        logger.debug("Intersection Distance: \(selection.distance)")
    }
    
}
