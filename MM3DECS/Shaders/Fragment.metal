#include <metal_stdlib>
using namespace metal;
#import "Vertex.h"

constant bool hasColorTexture [[function_constant(0)]];

fragment float4 fragment_main(
    constant Params &params [[buffer(ParamsBuffer)]],
    VertexOut in [[stage_in]],
    texture2d<float> baseColorTexture [[texture(BaseColor), function_constant(hasColorTexture)]],
    constant float4 &baseColor [[buffer(BaseColor)]])
{
    constexpr sampler textureSampler(
        filter::linear,
        mip_filter::linear,
        max_anisotropy(8),
        address::repeat);

    float3 color;
    if (hasColorTexture) {
        color = float3(0.4,0.1,0.1);//baseColorTexture.sample(textureSampler, in.uv * params.tiling).rgb;
    } else {
        color = baseColor.rgb;
    }

    return float4(color, 1);
}

fragment float4 fragment_normals(
    VertexOut in [[stage_in]])
{
    return float4(in.worldNormal, 1);
}
