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
    float x;
    float y;
} twoDPoint;

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
    float width;
    float height;
    matrix_float4x4 shadowProjectionMatrix;
    matrix_float4x4 shadowViewMatrix;
    twoDPoint point;
//    vector_float4 clipPlane;
} Uniforms;


typedef enum {
    BaseColor = 0,
    NormalTexture = 1,
    RoughnessTexture = 2,
    MetallicTexture = 3,
    AOTexture = 4,
    OpacityTexture = 5,
    ShadowTexture = 10,
    SkyboxTexture = 11,
    SkyboxDiffuseTexture = 12,
    BRDFLutTexture = 13,
    PositionTexture = 14,
    MiscTexture = 31
} TexturesIndices;

typedef struct{
    vector_float3 localOrigin;
    vector_float3 localDirection;
} LocalRay;

typedef struct {
  uint width;
  uint height;
  uint tiling;
  uint lightCount;
  vector_float3 cameraPosition;
  bool alphaBlending;
  bool transparency;
} Params;

typedef enum {
  unused = 0,
  Sun = 1,
  Spot = 2,
  Dot = 3, //Point in the book
  Ambient = 4
} LightType;

typedef struct {
    vector_float3 position;
    vector_float3 color;
    vector_float3 specularColor;
    float intensity;
    vector_float3 attenuation;
    LightType type;
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

typedef enum {
    VertexBuffer = 0,
    UVBuffer = 1,
    ColorBuffer = 2,
    TangentBuffer = 3,
    BitangentBuffer = 4,
    UniformsBuffer = 11,
    ParamsBuffer = 12,
    LightBuffer = 13,
    MaterialBuffer = 14
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

typedef struct {
    vector_float3 minBounds;
    vector_float3 maxBounds;
} BoundingBox;

typedef struct{
    LocalRay localRay;
    BoundingBox boundingBox;
    float parameter;
    matrix_float4x4 modelMatrix;
    int debug;
} NodeGPU;

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
    vector_float3 origin;
    vector_float3 direction;
    NodeGPU nodeGPU;
} Instances;

typedef enum {
   RenderTargetAlbedo = 1,
   RenderTargetNormal = 2,
   RenderTargetPosition = 3
} RenderTargetIndecies;

#endif /* Common_h */
