//
//  Vertex.h
//  MM3DUI
//
//  Created by Mohammad Jeragh on 04/10/2022.
//

#ifndef Vertex_h
#define Vertex_h
#import "Common.h"

struct VertexIn {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
    float3 color [[attribute(Color)]];
    float3 tangent [[attribute(Tangent)]];
    float3 bitangent [[attribute(Bitangent)]];
    ushort4 joints [[attribute(Joints)]];
    float4 weights [[attribute(Weights)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float3 worldTangent;
    float3 worldBitangent;
    float2 uv;
    float3 color;
    float4 shadowPosition;
//    float clip_distance [[ clip_distance ]] [1];
};

#endif /* Vertex_h */
