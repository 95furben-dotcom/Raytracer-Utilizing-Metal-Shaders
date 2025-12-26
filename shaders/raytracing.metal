#ifdef __INTELLISENSE__
#include "metal_shim.h"
#else
#include <metal_stdlib>
using namespace metal;
#endif


#include "common.metal"
#include "random.metal"


namespace RayTracer {
    // Return an empty RayHit (no hit). Use a function because program-scope
    // non-pointer aggregates in MSL must not be mutable storage; returning
    // a value is safe and portable.
    constexpr constant RayHit NOHIT = {
        false,
        0.0f
    };


    inline Ray createRay(float3 origin, float3 dir) {
        Ray r; r.origin = origin; r.direction = dir; return r;
    }

    // Helper to create a RayHit value
    inline RayHit createRayHit(float distance, float3 position, float3 normal) {
        RayHit hit;
        hit.hit = true;
        hit.distance = distance;
        hit.position = position;
        hit.normal = normalize(normal);
        return hit;
    }

    inline RayHit boxRayIntersection(Ray ray, float3 cubeMin, float3 cubeMax) {
    // Inverse direction for safe division
    float3 invDir = 1.0 / ray.direction;
    
    // Compute intersection distances along each axis
    float3 t0 = (cubeMin - ray.origin) * invDir;
    float3 t1 = (cubeMax - ray.origin) * invDir;
    
    // Get min/max for each axis
    float3 tmin3 = min(t0, t1);
    float3 tmax3 = max(t0, t1);
    
    // Get entry and exit distances
    float tmin = max(max(tmin3.x, tmin3.y), tmin3.z);
    float tmax = min(min(tmax3.x, tmax3.y), tmax3.z);
    
    // No intersection if tmax < tmin or tmax < 0
    if (tmax < max(tmin, 0.0)) {
        return RayTracer::NOHIT;
    }
    
    // Use tmin if positive, otherwise tmax
    float t = (tmin > 0.0) ? tmin : tmax;
    
    // Compute hit position
    float3 pos = ray.origin + t * ray.direction;
    
    // Compute hit normal
    float3 normal = float3(0.0);
    if (t == tmin3.x) normal.x = (invDir.x < 0.0) ? 1.0 : -1.0;
    else if (t == tmin3.y) normal.y = (invDir.y < 0.0) ? 1.0 : -1.0;
    else if (t == tmin3.z) normal.z = (invDir.z < 0.0) ? 1.0 : -1.0;
    
    return RayTracer::createRayHit(t, pos, normal);
}


    inline RayHit raycastChunkBounds(Ray ray, Chunk chunk) {
        // Chunk AABB in world space
        float3 cubeMin = float3(chunk.position);
        float3 cubeMax = float3(chunk.position) + float3(CHUNK_SIZE);

        RayHit hit = boxRayIntersection(ray, cubeMin, cubeMax);

        return hit; // returns NOHIT if no intersection
    }
    
    inline RayHit raycastChunk(Ray ray, Chunk chunk) {
    RayHit chunkEntry = raycastChunkBounds(ray, chunk);
    if(!chunkEntry.hit) return NOHIT;

    ray.origin = chunkEntry.position;

    int3 uniDir = int3(
        ray.direction.x < 0 ? -1 : 1,
        ray.direction.y < 0 ? -1 : 1,
        ray.direction.z < 0 ? -1 : 1
    );

    int3 voxel = int3(ray.origin);
    float3 tDelta = 1.0 / abs(ray.direction);

    float3 tMax = (float3(voxel) + simd::select(float3(0.0), float3(1.0), uniDir > 0) - ray.origin) / ray.direction;

    // Limit iterations for GPU
    for(int i = 0; i < 16*16*16; i++) {
        if(voxel.x < 0 || voxel.x >= 16 || voxel.y < 0 || voxel.y >= 16 || voxel.z < 0 || voxel.z >= 16)
            break;

        uint index = voxel.x + voxel.y*16 + voxel.z*256; // 16*16 = 256
        uint8_t block = chunk.blocks[index];

        if(block != 0) {
            float tHit = min(tMax.x, min(tMax.y, tMax.z));
            float3 hitPos = ray.origin + ray.direction * tHit;
            return createRayHit(tHit, hitPos, float3(0));
        }

        // Step to next voxel
        int axis = tMax.x < tMax.y ? (tMax.x < tMax.z ? 0 : 2) : (tMax.y < tMax.z ? 1 : 2);
        if(axis == 0) { voxel.x += uniDir.x; tMax.x += tDelta.x; }
        else if(axis == 1) { voxel.y += uniDir.y; tMax.y += tDelta.y; }
        else { voxel.z += uniDir.z; tMax.z += tDelta.z; }
    }

    return NOHIT;
}


    


}