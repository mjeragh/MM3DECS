//
//  RayDebug.metal
//  MM3DECS
//
//  Created by Mohammad Jeragh on 30/04/2024.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut line_vertex(VertexIn in [[stage_in]],
                             constant float4x4 &projectionMatrix [[buffer(1)]]) {
    VertexOut out;
    out.position = projectionMatrix * float4(in.position, 1.0);
    return out;
}

fragment float4 line_fragment() {
    return float4(1.0, 0.0, 0.0, 0.3);  // Red color for visibility
}
