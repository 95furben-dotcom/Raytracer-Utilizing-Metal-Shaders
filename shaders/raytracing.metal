#include <metal_stdlib>
#include "common.metal"
#include "random.metal"
using namespace metal;

namespace RayTracer {
    // Return an empty RayHit (no hit). Use a function because program-scope
    // non-pointer aggregates in MSL must not be mutable storage; returning
    // a value is safe and portable.
    inline RayHit createNoHit() {
        RayHit h;
        h.hit = false;
        return h;
    }
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

    inline RayHit intersectSphere(Ray ray, float3 center, float radius) {
        float3 oc = ray.origin - center;
        float a = dot(ray.direction, ray.direction);
        float b = 2.0 * dot(oc, ray.direction);
        float c = dot(oc, oc) - radius * radius;
        float discriminant = b * b - 4.0 * a * c;
        if (discriminant < 0.0) return createNoHit();
        float sqrtD = sqrt(discriminant);
        float t0 = (-b - sqrtD) / (2.0 * a);
        float t1 = (-b + sqrtD) / (2.0 * a);
        const float EPS = 1e-4;

        if (t0 > EPS) {
            float3 hitPos = ray.origin + t0 * ray.direction;
            float3 normal = normalize(hitPos - center);
            return createRayHit(t0, hitPos, normal);
        }
        if (t1 > EPS) {
            float3 hitPos = ray.origin + t1 * ray.direction;
            float3 normal = normalize(hitPos - center);
            return createRayHit(t1, hitPos, normal);
        }
        
        return createNoHit();
    }
    // Simple hash-based RNG to generate a random float in [0,1)
    

    // Create a reflected (bounced) ray from an incoming ray and a hit record.
    // The returned ray origin is nudged along the normal by a small epsilon to avoid self-intersection.
    inline Ray createBounceRay(Ray incoming, RayHit hit, float textureRoughness, thread uint &randomSeed) {
        float3 normal = hit.normal;
        float3 randomDir = Random::RandomDirection(randomSeed);

        if (dot(randomDir, normal) < 0.0) {
            randomDir = -randomDir;
        }
        // float3 bounceDir = reflect(incoming.direction, normal);
        // float3 finalDir = normalize((bounceDir + randomDir) * 0.5f);
        float3 finalDir = randomDir;

        Ray bounce;
        bounce.origin = hit.position+ normal * 1e-4;
        bounce.direction = finalDir;
        return bounce;
    }

    inline RayHit raycastWorld(Ray ray, constant World &world, constant Sphere* spheres, thread int& closestSphereOut) {
        RayHit closestHit = createNoHit();
        uint closestSphereInt = -1;
        float closestDistance = 1e20;

        for (uint i = 0; i < world.sphereCount; i++) {
            RayHit hit = intersectSphere(ray, spheres[i].center, spheres[i].radius);
            if (hit.hit && hit.distance < closestDistance) {
                closestDistance = hit.distance;
                closestHit = hit;
                closestSphereInt = i;
            }
        }
        closestSphereOut = closestSphereInt;
        return closestHit;
    }

    inline float3 Trace(Ray ray, uint maxBounceCount, thread uint &seed){
        for(uint i = 0; i<maxBounceCount; i++){
            
        }
    }
}