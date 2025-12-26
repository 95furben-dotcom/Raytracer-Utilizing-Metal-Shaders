#pragma once

#include <simd/vector_types.h>
#ifdef __METAL_VERSION__
    #include <metal_stdlib>
    using namespace metal;
    #define METAL_CONST constant
#else
    #define METAL_CONST
#endif
    
#include "simd/simd.h"

struct Camera {
    float NearClipPlane;
    float Aspect;
    float fovRad;        // replace FieldOfView
    simd_float3 position;
    simd_float3 target;
    simd_float3 forward;
    simd_float3 up;
    simd_float3 right;
    float planeHeight;
    float planeWidth;

    void UpdateData()
    {
        forward = simd_normalize(target - position);
        right = simd_normalize(simd_cross(forward, up));
        up = simd_normalize(simd_cross(right, forward));
        planeHeight = 2 * NearClipPlane * tan(fovRad / 2);
        planeWidth = planeHeight * Aspect;

    }

    Camera(simd_float3 pos = {8.0f, 8.0f, -32.0f},
           simd_float3 tgt = {8.0f, 8.0f, 8.0f},
           simd_float3 upVec = {0.0f, 1.0f, 0.0f},
           float fov = 1.0f,
           float aspect = 16.0f/10.0f,
           float nearClip = 0.1f)
    {
        position = pos;
        target = tgt;
        up = upVec;
        fovRad = fov;
        Aspect = aspect;
        NearClipPlane = nearClip;

        UpdateData();
    }
};

namespace Block{
    static const uint32_t Air = 0;
    static const uint32_t Stone = 1;
}

using namespace Block;
struct Chunk{
    // static dimentions
    enum Constants {
        width  = 16,
        height = 16,
        depth  = 16
    };
    
    // chunk data
    simd_int3 position;
    uint8_t blocks[depth * height * width];

    Chunk() = default;
    
    Chunk(simd_int3 pos){
        position = pos;
        
        // Initialize ALL blocks first (important!)
        for(int x = 0; x < width; x++){
            for(int y = 0; y < height; y++){
                for(int z = 0; z < depth; z++){
                    int index = x + y*width + z*height*width;
                    blocks[index] = Block::Air;  // or 0
                }
            }
        }
        
        // Then set the bottom 3 layers to stone
        for(int x = 0; x < width; x++){
            for(int y = 0; y < 3; y++){
                for(int z = 0; z < depth; z++){
                    int index = x + y*width + z*height*width;

                    blocks[index] = Block::Stone;
                }
            }
        }
    }
};

struct WorldInfo {
    unsigned int chunkCount;
    unsigned int frameIndex;
};  

struct World{
    static const int MAX_CHUNKS = 100;
    Chunk* chunks = new Chunk[MAX_CHUNKS];
    Camera camera;
    WorldInfo worldinfo;
};



