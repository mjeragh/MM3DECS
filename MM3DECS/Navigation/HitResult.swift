//
//  HitResult.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 04/05/2024.
//

import Foundation
import simd
struct HitResult {
    
    let ray: Ray
    let parameter: Float
    
    var intersectionPoint: SIMD4<Float> {
        return SIMD4<Float>(ray.origin + parameter * ray.direction, 1)
    }
    
    static func < (_ lhs: HitResult, _ rhs: HitResult) -> Bool {
        return lhs.parameter < rhs.parameter
    }
}
