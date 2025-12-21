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

    // material info
    float lightEmission;
    float textureRoughness;
    float3 baseColor;
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
    float3 center;
    float radius;

    // material properties
    float lightEmission;
    float textureRoughness;
    float3 baseColor;
};

struct WorldInfo {
    uint sphereCount;
    uint frameIndex;
};  

struct World{
    uint sphereCount;
    uint frameIndex;

    // set in fragmentshader
    constant Sphere* spheres;
    constant Camera* camera;

    World(constant Sphere* s, 
              constant Camera* c,
              uint sc,
              uint fi) {
        spheres = s;
        camera = c;
        sphereCount = sc;
        frameIndex = fi;
    }
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