#include <metal_stdlib>
using namespace metal;
#import "Vertex.h"

constant bool hasColorTexture [[function_constant(0)]];

struct Arguments {
    float4 baseColor;
    uint hasTexture;
    // No texture reference here
};

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Params &params [[buffer(ParamsBuffer)]],
                              constant Arguments &args [[buffer(ArgumentsBuffer)]],
                              texture2d<float> colorTexture [[texture(0)]]) {
    constexpr sampler textureSampler(
        filter::linear,
        mip_filter::linear,
        max_anisotropy(8),
        address::repeat
    );

    float3 color;
    if (args.hasTexture == 1) {
        color = colorTexture.sample(textureSampler, in.uv * params.tiling).rgb;
    } else {
        color = args.baseColor.rgb;
    }

    return float4(color, 1);
}

fragment float4 fragment_normals(VertexOut in [[stage_in]]) {
    return float4(in.worldNormal, 1);
}
