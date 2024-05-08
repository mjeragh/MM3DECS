//
//  EntityManager.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
class EntityManager {
    private var entities: [UUID: Entity] = [:]
    private var componentsByType: [String: [UUID: Component]] = [:]

    func addEntity(entity: Entity) {
        entities[entity.id] = entity
    }
    
    func addComponent<T: Component>(component: T, to entity: Entity) {
        let componentKey = String(describing: T.self)
        componentsByType[componentKey, default: [:]][entity.id] = component
    }
    
    func getComponent<T: Component>(type: T.Type, for entity: Entity) -> T? {
        let componentKey = String(describing: T.self)
        return componentsByType[componentKey]?[entity.id] as? T
    }

    func entities(for type: Component.Type) -> [Entity] {
        let componentKey = String(describing: type)
        guard let componentEntities = componentsByType[componentKey]?.keys else { return [] }
        return componentEntities.compactMap { entities[$0] }
    }

    // Additional utility methods...
    
        // Method to remove all entities and components
        func removeAllEntities() {
            entities.removeAll()
            componentsByType.removeAll()
        }

}


extension EntityManager {
    func entitiesWithComponents(_ componentTypes: [Component.Type]) -> [Entity] {
        var matchedEntities = [Entity]()

        for entity in entities.values {
            let hasAllComponents = componentTypes.allSatisfy { componentType in
                let componentKey = String(describing: componentType)
                return componentsByType[componentKey]?[entity.id] != nil
            }

            if hasAllComponents {
                matchedEntities.append(entity)
            }
        }

        return matchedEntities
    }
    
   func entitiesWithAnyComponents(_ componentTypes: [Component.Type]) -> [Entity] {
            var matchedEntities = [Entity]()

            for entity in entities.values {
                let hasAnyComponent = componentTypes.contains { componentType in
                    let componentKey = String(describing: componentType)
                    return componentsByType[componentKey]?[entity.id] != nil
                }

                if hasAnyComponent {
                    matchedEntities.append(entity)
                }
            }

            return matchedEntities
        }
    
    func createCameraEntity(type: CameraType) -> Entity {
        let cameraEntity = Entity(name: "Camera")
        self.addEntity(entity: cameraEntity)
        
        // Common transform component for all cameras
        let transformComponent = TransformComponent(position: [0, 0, 15])
        self.addComponent(component: transformComponent, to: cameraEntity)
        
        let aspect = Float(16) / Float(9) // Example aspect ratio
        
        switch type {
        case .perspective:
            let perspectiveCameraComponent = PerspectiveCameraComponent(fieldOfView: Float(70).degreesToRadians, nearClippingPlane: 0.5, farClippingPlane: 100, aspectRatio: aspect)
            self.addComponent(component: perspectiveCameraComponent, to: cameraEntity)
            
        case .arcball:
            var arcballCameraComponent = ArcballCameraComponent(target: [0,0,0], distance: 15, minDistance: 1, maxDistance: 100, aspect: aspect, fov: Float(70).degreesToRadians, near: 0.1, far: 100)
            arcballCameraComponent.calculateViewMatrix(transform: transformComponent)
            self.addComponent(component: arcballCameraComponent, to: cameraEntity)
            
        case .orthographic:
            let orthographicCameraComponent = OrthographicCameraComponent(aspect: aspect, viewSize: 10, near: 0.1, far: 100)
            self.addComponent(component: orthographicCameraComponent, to: cameraEntity)
        }
        
        return cameraEntity
    }
    }


