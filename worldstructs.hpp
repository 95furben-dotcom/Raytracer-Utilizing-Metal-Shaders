#pragma once
#include <simd/simd.h>
#include <cstdint>

struct Camera {
    float NearClipPlane;
    float Aspect;
    float FieldOfView;

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
        planeHeight = 2 * NearClipPlane * tan(FieldOfView * 3.14159265f / 360.0f);
        planeWidth = planeHeight * Aspect;
    }

    Camera(simd_float3 pos = {0.0f, 0.0f, -10.0f},
           simd_float3 tgt = {0.0f, 0.0f, 1.0f},
           simd_float3 upVec = {0.0f, 1.0f, 0.0f},
           float fov = 60.0f,
           float aspect = 16.0f/10.0f,
           float nearClip = 0.1f)
    {
        position = pos;
        target = tgt;
        up = upVec;
        FieldOfView = fov;
        Aspect = aspect;
        NearClipPlane = nearClip;

        forward = simd_normalize(target - position);
        right = simd_normalize(simd_cross(forward, up));
        up = simd_normalize(simd_cross(right, forward));

        planeHeight = 2 * NearClipPlane * tan(FieldOfView * 3.14159265f / 360.0f);
        planeWidth = planeHeight * Aspect;
    }
};

struct Sphere {
    bool inited=false;
    simd_float3 center;
    float radius;

    // material properties
    float lightEmission;
    float textureRoughness; // 0 (smooth) to 1 (rough)  
    simd_float3 baseColor; // base color

    Sphere()=default;

    Sphere(simd_float3 c,
           float r = 5.0f,
           simd_float3 color = {1.0f, 1.0f, 1.0f},
           float roughness = 0.5f,
           float emission = 0.0f)
    {
        inited=true;
        center = c;
        radius = r;
        baseColor = color;
        textureRoughness = roughness;
        lightEmission = emission;
    }

};

struct World {
    bool inited=false;
    uint32_t sphereCount;
    uint32_t frameIndex;

    World()=default;
    
    World(uint32_t sphereCount,
        uint32_t frameIndex){
            inited=true;
    this->sphereCount = sphereCount;
    this->frameIndex = frameIndex;
}
};  

struct WorldInfo {
    World world;
    Sphere spheres[100];
    Camera camera;

    WorldInfo()=default;

    WorldInfo(const World& world,
              const Sphere* spheres,
              const Camera& camera)
        : world(world), camera(camera)
    {
        for (uint32_t i = 0; i < world.sphereCount; ++i) {
            this->spheres[i] = spheres[i];
        }
    }
};