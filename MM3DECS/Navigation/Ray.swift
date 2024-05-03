//
//  Ray.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 27/04/2024.
//

import Foundation
import simd
import OSLog

struct Ray {
    var origin: float3
    var direction: float3
    var maxDistance = Float.infinity
    var INVdirection: float3 = float3(0,0,0)
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "Ray")
    var length: Float = 20.0  // Default length for rendering

    //RayDebug
    func vertexData() -> [float3] {
        let endPoint = origin + 1/direction * length
        return [origin, endPoint]
    }
    
    init(origin: float3, direction: float3) {
        self.origin = origin
        self.direction = direction.normalized //Ensure the direction is normalized
        
    }
}

import ModelIO

extension Ray {
    /// Check if the ray intersects with an axis-aligned bounding box.
    func intersects(with boundingBox: MDLAxisAlignedBoundingBox) -> Bool {
         let tmin = boundingBox.minBounds
         let tmax = boundingBox.maxBounds
        logger.debug("tmin: \(tmin), tmax: \(tmax)")
         
         let inverseDirection = float3(1.0 / direction.x, 1.0 / direction.y, 1.0 / direction.z)
         
         let sign: [Int] = [
             (inverseDirection.x < 0) ? 1 : 0,
             (inverseDirection.y < 0) ? 1 : 0,
             (inverseDirection.z < 0) ? 1 : 0
         ]
         
        var tmin_x = (tmin[sign[0]] - origin.x) * inverseDirection.x
         var tmax_x = (tmax[1 - sign[0]] - origin.x) * inverseDirection.x
         
         var tmin_y = (tmin[sign[1]] - origin.y) * inverseDirection.y
         var tmax_y = (tmax[1 - sign[1]] - origin.y) * inverseDirection.y
         
         if (tmin_x > tmax_y) || (tmin_y > tmax_x) {
             return false
         }
         
         if tmin_y > tmin_x {
             tmin_x = tmin_y
         }
         
         if tmax_y < tmax_x {
             tmax_x = tmax_y
         }
         
         var tmin_z = (tmin[sign[2]] - origin.z) * inverseDirection.z
         var tmax_z = (tmax[1 - sign[2]] - origin.z) * inverseDirection.z
         
         if (tmin_x > tmax_z) || (tmin_z > tmax_x) {
             return false
         }
         
         if tmin_z > tmin_x {
             tmin_x = tmin_z
         }
         
         if tmax_z < tmax_x {
             tmax_x = tmax_z
         }
         
         return true
     }
 }

