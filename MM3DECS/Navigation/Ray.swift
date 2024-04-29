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
    var maxDistance = Float.infinity
    
    init(origin: float3, direction: float3) {
        self.origin = origin
        self.direction = direction.normalized //Ensure the direction is normalized
    }
}

import ModelIO

extension Ray {
    /// Check if the ray intersects with an axis-aligned bounding box.
    func intersects(with bounds: [float3], with selection: inout SelectionComponent) {
        assert(bounds.count == 2, "Bounds array must have two elements.")
                
       let inverseDirection = 1/direction
        var tmin = bounds[0]
        var tmax = bounds[1]
        let sign = [(inverseDirection.x < 0) ? 1 : 0, (inverseDirection.y < 0) ? 1 : 0, (inverseDirection.z < 0) ? 1 : 0]
        tmin.x = (bounds[sign[0]].x - origin.x) * inverseDirection.x
        tmax.x = (bounds[1 - sign[0]].x - origin.x) * inverseDirection.x
        
        tmin.y = (bounds[sign[1]].y - origin.y) * inverseDirection.y;
        tmax.y = (bounds[1 - sign[1]].y - origin.y) * inverseDirection.y;
            
        var t0 = Float(tmax.z);
            
        if ((tmin.x > tmax.y) || (tmin.y > tmax.x)){
             return;
        }
        
        
        if (tmin.y > tmin.x){
            tmin.x = tmin.y;
        }
        
        
        if (tmax.y < tmax.x){
            tmax.x = tmax.y;
        }
        
        tmin.z = (bounds[sign[2]].z - origin.z) * inverseDirection.z;
        tmax.z = (bounds[1-sign[2]].z - origin.z) * inverseDirection.z;
        
        
        if ((tmin.x > tmax.z) || (tmin.z > tmax.x)){
            
            return
        }
        
        if (tmin.z > tmin.x){
            tmin.x = tmin.z;
            t0 = tmin.x
        }
        
        if (tmax.z < tmax.x){
            tmax.x = tmax.z;
            t0 = tmax.x
        }
        selection.isSelected = true;
        selection.distance = float3(origin + direction * t0)
        return
    }
}
