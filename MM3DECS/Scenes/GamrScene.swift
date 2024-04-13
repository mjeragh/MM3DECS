//
//  GamrScene.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 13/04/2024.
//

import MetalKit

class GameScene: Scene {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func setUp() {
        // Set up entities specific to this scene
    }

    func update(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder) {
        // Update the scene and entities
    }

    func tearDown() {
        // Clean up the scene before transition
    }
}

