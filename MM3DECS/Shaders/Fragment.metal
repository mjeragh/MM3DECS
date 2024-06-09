#include <metal_stdlib>
using namespace metal;
#import "Vertex.h"

constant bool hasColorTexture [[function_constant(0)]];



struct Arguments {
    constant float4 &baseColor;
    texture2d<float> baseColorTexture;
    bool hasTexture;
};


fragment float4 fragment_main(
    constant Params &params [[buffer(ParamsBuffer)]],
    VertexOut in [[stage_in]],
    constant Arguments &args [[buffer(ArgumentsBuffer)]])
{
    constexpr sampler textureSampler(
        filter::linear,
        mip_filter::linear,
        max_anisotropy(8),
        address::repeat);

    float3 color;
    if (args.hasTexture) {
        color = args.baseColorTexture.sample(textureSampler, in.uv * params.tiling).rgb;
    } else {
        color = args.baseColor.rgb;
    }

    return float4(color, 1);
}

fragment float4 fragment_normals(
    VertexOut in [[stage_in]])
{
    return float4(in.worldNormal, 1);
}
