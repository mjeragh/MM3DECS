#include <metal_stdlib>
using namespace metal;
#import "Vertex.h"

struct ModelVertex {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
    float3 color [[attribute(Color)]];
    float3 tangent [[attribute(Tangent)]];
    float3 bitangent [[attribute(Bitangent)]];
    ushort4 joints [[attribute(Joints)]];
    float4 weights [[attribute(Weights)]];
};

struct DebugInfo {
    float4 inputPosition;
    float4 outputPosition;
    float4 transformRow0;
    float4 transformRow1;
    float4 transformRow2;
    float4 transformRow3;
};

kernel void transformVertices(device ModelVertex *vertices [[buffer(0)]],
                              constant float4x4 &transform [[buffer(1)]],
                              device DebugInfo *debugBuffer [[buffer(2)]],
                              uint id [[thread_position_in_grid]]) {
    // Store debug info
    debugBuffer[id].inputPosition = vertices[id].position;
    debugBuffer[id].transformRow0 = transform[0];
    debugBuffer[id].transformRow1 = transform[1];
    debugBuffer[id].transformRow2 = transform[2];
    debugBuffer[id].transformRow3 = transform[3];

    // Apply matrix transformation directly to the vertex buffer
    float4 position = vertices[id].position;
    vertices[id].position = transform * position;

    // Store output position
    debugBuffer[id].outputPosition = vertices[id].position;
}
