//
//  Common.h
//  MM3DUI
//
//  Created by Mohammad Jeragh on 26/06/2022.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>
#import "stdbool.h"


typedef struct {
  matrix_float4x4 viewMatrix;
  matrix_float4x4 projectionMatrix;
  matrix_float4x4 shadowProjectionMatrix;
  matrix_float4x4 shadowViewMatrix;
//the following was in a modeltransform struct
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
} Uniforms;

typedef enum {
  VertexBuffer = 0,
  UVBuffer = 1,
  TangentBuffer = 2,
  BitangentBuffer = 3,
  UniformsBuffer = 11,
  ParamsBuffer = 12,
  LightBuffer = 13,
  MaterialBuffer = 14,
  JointBuffer = 15,
  ModelTransformBuffer = 16,
  InstancesBuffer = 17,
    ArgumentsBuffer = 18
} BufferIndices;

typedef enum {
  Position = 0,
  Normal = 1,
  UV = 2,
  Tangent = 3,
  Bitangent = 4,
    Color = 5,
  Joints = 6,
  Weights = 7
} Attributes;

typedef enum {
  BaseColor = 0,
  NormalTexture = 1,
  RoughnessTexture = 2,
  MetallicTexture = 3,
  AOTexture = 4,
  OpacityTexture = 5,
  ShadowTexture = 15,
  SkyboxTexture = 16,
  SkyboxDiffuseTexture = 17,
  BRDFLutTexture = 18,
  MiscTexture = 31
} TextureIndices;

typedef enum {
  unused = 0,
  Sun = 1,
  Spot = 2,
  Point = 3,
  Ambient = 4
} LightType;

typedef struct {
  LightType type;
  vector_float3 position;
  vector_float3 color;
  vector_float3 specularColor;
  float radius;
  vector_float3 attenuation;
  float coneAngle;
  vector_float3 coneDirection;
  float coneAttenuation;
} Light;

typedef enum {
    none = 0,
    linear = 1,
    radial = 2
} Gradient;

typedef struct {
    vector_float3 baseColor;
    vector_float3 secondColor;
    vector_float3 specularColor;
    float roughness;
    float metallic;
    float ambientOcclusion;
    float shininess;
    float opacity;
    vector_float4 irradiatedColor;
    Gradient gradient;
} Material;

typedef struct {
  uint width;
  uint height;
  uint tiling;
  uint lightCount;
  vector_float3 cameraPosition;
  float scaleFactor;
  bool alphaTesting;
  bool alphaBlending;
  bool transparency;
} Params;

typedef enum {
   RenderTargetAlbedo = 1,
   RenderTargetNormal = 2,
   RenderTargetPosition = 3
} RenderTargetIndecies;

#endif /* Common_h */
