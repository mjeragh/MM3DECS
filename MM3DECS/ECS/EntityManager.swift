//
//  EntityManager.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
import os.log

class EntityManager {
    private var entities: [UUID: Entity] = [:]
    private var componentsByType: [String: [UUID: Component]] = [:]
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "EntityManager")

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
    
    
    }


