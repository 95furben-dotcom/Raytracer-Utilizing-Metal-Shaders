#ifndef COMMON_METAL_INCLUDED
#define COMMON_METAL_INCLUDED

#ifdef __INTELLISENSE__
#include "metal_shim.h"
#pragma clang diagnostic ignored "-Wunknown-attributes"
#else
#include <metal_stdlib>
using namespace metal;
#endif


struct Ray {
    float3 origin;
    float3 direction;
};

struct RayHit {
    bool hit;
    float distance;
    float3 position;
    float3 normal;
};


struct Camera {
    float NearClipPlane;
    float Aspect;
    float fovRad; // in radians

    float3 position;
    float3 target;
    float3 forward;
    float3 up;
    float3 right;

    float planeHeight;
    float planeWidth;

    // For constant memory, explicitly add 'constant' for 'this'
    float3 GetDirection(float2 uv) constant
    {
        float2 posOnPlane = float2(
            planeWidth * (0.5f - uv.x),
            planeHeight * (uv.y - 0.5f)
        );

        float3 localDirection = normalize(
            float3(posOnPlane.x, posOnPlane.y, NearClipPlane)
        );

        return normalize(
            localDirection.x * right +
            localDirection.y * up +
            localDirection.z * forward
        );
    }

    float3 GetDirectionNonConst(float2 uv)
    {
        float2 posOnPlane = float2(
            planeWidth * (0.5f - uv.x),
            planeHeight * (uv.y - 0.5f)
        );

        float3 localDirection = normalize(
            float3(posOnPlane.x, posOnPlane.y, NearClipPlane)
        );

        return normalize(
            localDirection.x * right +
            localDirection.y * up +
            localDirection.z * forward
        );
    }
};



struct WorldInfo {
    uint chunkCount;
    uint frameIndex;
};  

constant int3 CHUNK_SIZE = int3(16);

struct Chunk{
    // static dimentions
    
    // chunk data
    int3 position;
    uint8_t blocks[16*16*16];
};

struct World {
    constant Chunk* chunks;
    uint chunkCount;
};


// Must match CPU Params layout in Renderer.mm
struct Params {
    uint drawableWidth;
    uint drawableHeight;
    uint inscribedWidth;
    uint inscribedHeight;
    uint offsetX;
    uint offsetY;
};

struct VertexOut {
    // global outputs
    float4 position [[position]]; 
    float2 uv;
};

#endif // COMMON_METAL_INCLUDED