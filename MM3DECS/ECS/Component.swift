//
//  Protocol.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
import MetalKit
protocol Component { }

// Example components
struct TransformComponent: Component {
    var position: float3
    var rotation: float3
    var scale: float3
}

struct RenderableComponent: Component {
    var mesh: MTKMesh
    var texture: MTLTexture?
    // Other rendering-related properties such as materials, shaders, etc.
}
