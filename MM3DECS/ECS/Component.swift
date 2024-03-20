//
//  Protocol.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

import Foundation
protocol Component { }

// Example components
struct TransformComponent: Component {
    var position: SIMD3<Float>
    var rotation: SIMD3<Float>
    var scale: SIMD3<Float>
}

struct RenderableComponent: Component {
    var meshName: String
}
