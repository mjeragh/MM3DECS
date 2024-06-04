#include <metal_stdlib>
using namespace metal;
#import "Vertex.h"

fragment float4 fragment_main(
  constant Params &params [[buffer(ParamsBuffer)]],
  VertexOut in [[stage_in]],
  texture2d<float> baseColorTexture [[texture(BaseColor)]])
{
  constexpr sampler textureSampler(
    filter::linear,
    mip_filter::linear,
    max_anisotropy(8),
    address::repeat);
  float3 baseColor = baseColorTexture.sample(
    textureSampler,
    in.uv * params.tiling).rgb;
  return float4(baseColor, 1);
}

fragment float4 fragment_normals(
    VertexOut in [[stage_in]])
{
    return float4(in.worldNormal, 1);
}
