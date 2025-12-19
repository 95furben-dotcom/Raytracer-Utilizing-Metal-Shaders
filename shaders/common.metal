#ifndef COMMON_METAL_INCLUDED
#define COMMON_METAL_INCLUDED

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
};

struct Sphere {
    bool inited;
    float3 center;
    float radius;

    // material properties
    float lightEmission;
    float textureRoughness;
    float4 baseColor;
};

struct World {
    bool inited;
    uint sphereCount;
    uint frameIndex;
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