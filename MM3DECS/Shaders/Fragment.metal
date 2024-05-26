#include <metal_stdlib>
using namespace metal;
#import "Vertex.h"

fragment float4 fragment_main(
    constant Params &params [[buffer(ParamsBuffer)]],
    VertexOut in [[stage_in]],
    texture2d<float> baseColorTexture [[texture(BaseColor)]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 color = baseColorTexture.sample(textureSampler, in.uv);
    return color;
}

fragment float4 fragment_normals(
    VertexOut in [[stage_in]])
{
    return float4(in.worldNormal, 1);
}
