//
//  Lighting.h
//  MM3DUI
//
//  Created by Mohammad Jeragh on 28/09/2022.
//

#ifndef Lighting_h
#define Lighting_h

#import "Common.h"
#include <metal_stdlib>
using namespace metal;

float3 phongLighting(
  float3 normal,
  float3 position,
  constant Params &params,
  constant Light *lights,
  Material material);

float calculateShadow(
  float4 shadowPosition,
  depth2d<float> shadowTexture);

float3 calculateSun(
  Light light,
  float3 normal,
  Params params,
  Material material);

float3 calculatePoint(
  Light light,
  float3 position,
  float3 normal,
  Material material);

float3 calculateSpot(
  Light light,
  float3 position,
  float3 normal,
  Material material);

float calculateShadow(
  float4 shadowPosition,
  depth2d<float> shadowTexture);

#endif /* Lighting_h */
