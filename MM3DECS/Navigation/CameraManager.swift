//
//  CameraManager.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 09/05/2024.
//

import Foundation
// CameraManager.swift
import simd

import os.log

enum CameraType {
        case perspective
        case arcball
        case orthographic
    }

class CameraManager {
    
    private var entityManager: EntityManager
    private var activeCameraEntity: Entity?
    private var activeCameraType: CameraType?
    
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "CameraManager")
    
    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }
    
    func setCamera(type: CameraType, withCameraInputComponent:Bool = false) {
        activeCameraType = type
        activeCameraEntity = createCameraEntity(type: type)
    }
    
    func getActiveCameraEntity() -> Entity? {
        return activeCameraEntity
    }
    
    func updateAspect(_ aspectRatio: Float) {
        guard let cameraEntity = activeCameraEntity else { return }
        switch activeCameraType {
        case .perspective:
            if var cameraComponent = entityManager.getComponent(type: PerspectiveCameraComponent.self, for: cameraEntity) {
                cameraComponent.updateAspect(aspectRatio)
                entityManager.addComponent(component: cameraComponent, to: cameraEntity)
            }
        case .arcball:
            if var cameraComponent = entityManager.getComponent(type: ArcballCameraComponent.self, for: cameraEntity) {
                cameraComponent.updateAspect(aspectRatio)
                entityManager.addComponent(component: cameraComponent, to: cameraEntity)
            }
        case .orthographic:
            if var cameraComponent = entityManager.getComponent(type: OrthographicCameraComponent.self, for: cameraEntity) {
                cameraComponent.updateAspect(aspectRatio)
                entityManager.addComponent(component: cameraComponent, to: cameraEntity)
            }
        default:
            return
        }
        logger.debug("CameraManager: Aspect ratio updated to: \(aspectRatio)")
    }
    
    func getActiveCameraComponent() -> CameraComponent? {
        switch activeCameraType {
        case .perspective:
            return entityManager.getComponent(type: PerspectiveCameraComponent.self, for: activeCameraEntity!)!
        case .arcball:
            return entityManager.getComponent(type: ArcballCameraComponent.self, for: activeCameraEntity!)!
        case .orthographic:
            return entityManager.getComponent(type: OrthographicCameraComponent.self, for: activeCameraEntity!)!
        default:
            return nil
        }
    }
    
    func moveActiveCamera(to transform: TransformComponent){
        entityManager.addComponent(component: transform, to: activeCameraEntity!)
    }
    
    private func createCameraEntity(type: CameraType) -> Entity {
        let cameraEntity = Entity(name: "Camera")
        entityManager.addEntity(entity: cameraEntity)
        
        // Common transform component for all cameras
        let transformComponent = TransformComponent(position: [0, 2, 15])
        entityManager.addComponent(component: transformComponent, to: cameraEntity)
        
        let aspect = Float(Renderer.params.width) / Float(Renderer.params.height) // Example aspect ratio
        logger.debug("inside creating camera Aspect ratio: \(aspect)")
        
        switch type {
        case .perspective:
            let perspectiveCameraComponent = PerspectiveCameraComponent(fieldOfView: Float(70).degreesToRadians, nearClippingPlane: 0.5, farClippingPlane: 100, aspectRatio: aspect)
            entityManager.addComponent(component: perspectiveCameraComponent, to: cameraEntity)
            
        case .arcball:
            let arcballCameraComponent = ArcballCameraComponent(target: [0,0,0], distance: 15, minDistance: 1, maxDistance: 100, aspect: aspect, fov: Float(70).degreesToRadians, near: 0.1, far: 100)
            
            entityManager.addComponent(component: arcballCameraComponent, to: cameraEntity)
            
        case .orthographic:
            let orthographicCameraComponent = OrthographicCameraComponent(aspect: aspect, viewSize: 10, near: 0.1, far: 100)
            entityManager.addComponent(component: orthographicCameraComponent, to: cameraEntity)
        }
        
        return cameraEntity
    }
    
    // Retrieve the view matrix of the active camera
    func getViewMatrix() -> float4x4? {
        guard let cameraEntity = activeCameraEntity,
              let transformComponent = entityManager.getComponent(type: TransformComponent.self, for: cameraEntity) else { return nil }
        
        switch activeCameraType {
        case .perspective:
            if let cameraComponent = entityManager.getComponent(type: PerspectiveCameraComponent.self, for: cameraEntity) {
                return cameraComponent.calculateViewMatrix(transform: transformComponent)
            }
        case .arcball:
            if let cameraComponent = entityManager.getComponent(type: ArcballCameraComponent.self, for: cameraEntity) {
                return cameraComponent.calculateViewMatrix(transform: transformComponent)
            }
        case .orthographic:
            if let cameraComponent = entityManager.getComponent(type: OrthographicCameraComponent.self, for: cameraEntity) {
                return cameraComponent.calculateViewMatrix(transform: transformComponent)
            }
        default:
            return nil
        }
        return nil
    }
    
    // Retrieve the projection matrix of the active camera
    func getProjectionMatrix() -> float4x4? {
        guard let cameraEntity = activeCameraEntity else { return nil }
        
        switch activeCameraType {
        case .perspective:
            return entityManager.getComponent(type: PerspectiveCameraComponent.self, for: cameraEntity)?.projectionMatrix
        case .arcball:
            return entityManager.getComponent(type: ArcballCameraComponent.self, for: cameraEntity)?.projectionMatrix
        case .orthographic:
            return entityManager.getComponent(type: OrthographicCameraComponent.self, for: cameraEntity)?.projectionMatrix
        default:
            return nil
        }
    }
    
    func getActiveTransformComponent() -> TransformComponent {
        entityManager.getComponent(type: TransformComponent.self, for: activeCameraEntity!)!
    }
    
    func updateCameraDistance() {
        guard let camera = getActiveCameraEntity(),
        var archballCamera = entityManager.getComponent(type: ArcballCameraComponent.self, for: camera),
        var archballTranspose = entityManager.getComponent(type: TransformComponent.self, for: camera)
            else {
            logger.warning("Updating non archball camera!!!!")
            return
        }
        let input = InputManager.shared
        let scrollSensitivity = Settings.mouseScrollSensitivity
        archballCamera.distance -= Float(input.mouseScroll.x + input.mouseScroll.y)
          * scrollSensitivity
        archballCamera.distance = min(archballCamera.maxDistance, archballCamera.distance)
        archballCamera.distance = max(archballCamera.minDistance, archballCamera.distance)
        input.mouseScroll = .zero
        
        
        let rotateMatrix = float4x4(
            rotationYXZ: [-archballTranspose.rotation.x, archballTranspose.rotation.y, 0])
        let distanceVector = float4(0, 0, -archballCamera.distance, 0)
        let rotatedVector = rotateMatrix * distanceVector
        archballTranspose.position = archballCamera.target + rotatedVector.xyz
        entityManager.addComponent(component: archballTranspose, to: camera)
        entityManager.addComponent(component: archballCamera, to: camera)
        logger.debug("new distance: \(archballCamera.distance)")
    }
}
