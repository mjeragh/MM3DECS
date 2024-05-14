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
    let epsilon: Float = 0.0001
    func nearlyEqual(a: Float, b: Float, epsilon: Float) -> Bool {
        return abs(a - b) < epsilon
    }

    //RayDebug
    func vertexData() -> [float3] {
        let endPoint = origin + 1/direction * length
        return [origin, endPoint]
    }
    
    init(origin: float3, direction: float3) {
        self.origin = origin
        self.direction = direction.normalized //Ensure the direction is normalized
        
    }
    
    
    static func *(transform: float4x4, ray: Ray) -> Ray {
        let originT = (transform * SIMD4<Float>(ray.origin, 1)).xyz
        let directionT = (transform * SIMD4<Float>(ray.direction, 0)).xyz
        return Ray(origin: originT, direction: directionT)
    }
    
    /// Determine the point along this ray at the given parameter
    func extrapolate(_ parameter: Float) -> SIMD4<Float> {
        return SIMD4<Float>(origin + parameter * direction, 1)
    }
    
    /// Determine the parameter corresponding to the point,
    /// assuming it lies on this ray
    func interpolate(_ point: float4) -> Float {
        return simd.length(point.xyz - origin) / simd.length(direction)
    }
}

import ModelIO

extension Ray {
    /// Check if the ray intersects with an axis-aligned bounding box.
    func intersects(with bounds: [float3]) -> Bool {
        assert(bounds.count == 2, "Bounds array must have two elements.")
       // logger.debug("\nray: origin\(origin), direction:\(direction)")
       // Compute inverse direction safely
        let inverseDirection = float3(
            x: direction.x == 0 ? Float.greatestFiniteMagnitude : 1 / direction.x,
            y: direction.y == 0 ? Float.greatestFiniteMagnitude : 1 / direction.y,
            z: direction.z == 0 ? Float.greatestFiniteMagnitude : 1 / direction.z
        )
       // let inverseDirection = INVdirection
      //  logger.debug("inveseDirection: \(inverseDirection)")
        
        var tmin = bounds[0]
        var tmax = bounds[1]
      //  logger.debug("tmin(min Bound):\(tmin), tmax(maxBound):\(tmax)\n")
        let sign = [(inverseDirection.x < 0) ? 1 : 0, (inverseDirection.y < 0) ? 1 : 0, (inverseDirection.z < 0) ? 1 : 0]
     //   logger.debug("sign: \(sign)")
        tmin.x = (bounds[sign[0]].x - origin.x) * inverseDirection.x
        tmax.x = (bounds[1 - sign[0]].x - origin.x) * inverseDirection.x
        
        tmin.y = (bounds[sign[1]].y - origin.y) * inverseDirection.y;
        tmax.y = (bounds[1 - sign[1]].y - origin.y) * inverseDirection.y;
        
       // logger.debug("tmin:\(tmin), tmax:\(tmax) after updating with sign and inverseDirection\n")
        
        var t0 = Float(tmax.z);
//        logger.debug("t0: \(t0)")
            
//        if !nearlyEqual(a: tmin.x, b: tmax.y, epsilon: epsilon) &&
//            !nearlyEqual(a: tmin.y, b: tmax.x, epsilon: epsilon) &&
//            (tmin.x > tmax.y || tmin.y > tmax.x) {
//            logger.debug("first fail")
//            return false
//        }
        
        if ((tmin.x > tmax.y) || (tmin.y > tmax.x)){
//            logger.debug("first fail")
             return false;
        }
        //logger.debug("tmin.x: \(tmin.x), tmax.y: \(tmax.y), after passing the first failure test\n")
        
        if (tmin.y > tmin.x){
            tmin.x = tmin.y;
        }
        
        
        if (tmax.y < tmax.x){
            tmax.x = tmax.y;
        }
        
        tmin.z = (bounds[sign[2]].z - origin.z) * inverseDirection.z;
        tmax.z = (bounds[1-sign[2]].z - origin.z) * inverseDirection.z;
        
       // logger.debug("tmin:\(tmin), tmax:\(tmax) before checking for the second failur test and after updating the z-axis of tmin and tmax sign and inverseDirection\n")
        if ((tmin.x > tmax.z) || (tmin.z > tmax.x)){
//            logger.debug("Second fail")
            return false;
        }
       // logger.debug("tmin.x: \(tmin.x), tmax.z: \(tmax.z), after passing the second failure test, this means success!\n")
        if (tmin.z > tmin.x){
            tmin.x = tmin.z;
            t0 = tmin.x
        }
        
        if (tmax.z < tmax.x){
            tmax.x = tmax.z;
            t0 = tmax.x
        }
//        selection.isSelected = true;
//        selection.distance = float3(origin + direction * t0)
        return true;
    }
    
    
}//extention
 

