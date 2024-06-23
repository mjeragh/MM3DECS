//
//  modelVerticesTransform.metal
//  MM3DECS
//
//  Created by Mohammad Jeragh on 22/06/2024.
//
#include <metal_stdlib>
using namespace metal;

struct ModelVertex {
    float4 position;
    // other attributes if necessary
};

struct DebugInfo {
    float4 inputPosition;
    float4 outputPosition;
    float4 transformRow0;
    float4 transformRow1;
    float4 transformRow2;
    float4 transformRow3;
};

kernel void transformVertices(device const ModelVertex *inputVertices [[buffer(0)]],
                              device ModelVertex *outputVertices [[buffer(1)]],
                              constant float4x4 &transform [[buffer(2)]],
                              device DebugInfo *debugBuffer [[buffer(3)]],
                              uint id [[thread_position_in_grid]]) {
    // Store debug info
    debugBuffer[id].inputPosition = inputVertices[id].position;
    debugBuffer[id].transformRow0 = transform[0];
    debugBuffer[id].transformRow1 = transform[1];
    debugBuffer[id].transformRow2 = transform[2];
    debugBuffer[id].transformRow3 = transform[3];

    // Apply transformation
    outputVertices[id].position = transform * inputVertices[id].position;

    // Store output position
    debugBuffer[id].outputPosition = outputVertices[id].position;
}
