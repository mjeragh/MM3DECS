//
//  SelectionSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 21/04/2024.
//

import Metal

class SelectionSystem: SystemProtocol {
    func update(deltaTime: Float, renderEncoder: any MTLRenderCommandEncoder) {
        // This system would go through entities with renderable components
        // and check if they have been touched by using picking logic.
        // If touched, the SelectionComponent's isSelected is set to true.
    }
    
}
