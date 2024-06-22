//
//  modelVerticesTransform.metal
//  MM3DECS
//
//  Created by Mohammad Jeragh on 22/06/2024.
//
#include <metal_stdlib>
using namespace metal;

struct ModelVertex {
    float4 position [[attribute(0)]];
    // other attributes if necessary
};

kernel void transformVertices(device ModelVertex *vertices [[buffer(0)]],
                              constant float4x4 &transform [[buffer(1)]],
                              uint id [[thread_position_in_grid]]) {
    vertices[id].position = transform * vertices[id].position;
}
