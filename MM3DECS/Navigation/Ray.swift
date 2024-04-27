//
//  Ray.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 27/04/2024.
//

import Foundation
import simd

struct Ray {
    var origin: float3
    var direction: float3
    
    init(origin: float3, direction: float3) {
        self.origin = origin
        self.direction = direction.normalized //Ensure the direction is normalized
    }
}

import ModelIO

extension Ray {
    /// Check if the ray intersects with an axis-aligned bounding box.
    func intersects(with box: MDLAxisAlignedBoundingBox) -> Bool {
        let invDir = 1.0 / direction
        let t1 = (box.minBounds - origin) * invDir
        let t2 = (box.maxBounds - origin) * invDir
        
        let tmin = max(min(t1.x, t2.x), min(t1.y, t2.y), min(t1.z, t2.z))
        let tmax = min(max(t1.x, t2.x), max(t1.y, t2.y), max(t1.z, t2.z))
        
        // Check if tmax is greater than zero and tmax is greater than or equal to tmin
        return tmax >= max(0.0, tmin)
    }
}
