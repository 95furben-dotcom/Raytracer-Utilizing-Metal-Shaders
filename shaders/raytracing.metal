#ifdef __INTELLISENSE__
#include "metal_shim.h"
#else
#include <metal_stdlib>
using namespace metal;
#endif


#include "common.metal"
#include "random.metal"


namespace RayTracer {
    constant int MAX_BOUNCES = 5;
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

    inline RayHit intersectSphere(Ray ray, constant Sphere& sphere) {
        float radius = sphere.radius;
        float3 center = sphere.center;
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

        // set constant info
        RayHit hit;
        hit.hit = true;
        hit.lightEmission = sphere.lightEmission;
        hit.textureRoughness = sphere.textureRoughness;
        hit.baseColor = sphere.baseColor;

        if (t0 > EPS) {
            hit.distance = t0;
            hit.position = ray.origin + t0 * ray.direction;
            hit.normal = normalize(hit.position - center);
            return hit;
        }
        if (t1 > EPS) {
            hit.distance = t1;
            hit.position = ray.origin + t1 * ray.direction;
            hit.normal = normalize(hit.position - center);
            return hit;
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

    inline RayHit raycastWorld(Ray ray, World world) {
        RayHit closestHit = createNoHit();
        float closestDistance = 1e20;

        for (uint i = 0; i < world.sphereCount; i++) {
            constant Sphere& sphere = world.spheres[i];
            RayHit hit = intersectSphere(ray, sphere);
            if (hit.hit && hit.distance < closestDistance) {
                closestDistance = hit.distance;
                closestHit = hit;
            }
        }
        return closestHit;
    }

    inline float3 Trace(Ray ray, World world, thread uint &seed){
        float3 incomingLight = float3(0.0);
        float3 rayColor = float3(1); // white

        for(uint i = 0; i<MAX_BOUNCES; i++){
            RayHit hit = raycastWorld(ray, world);
            
            if(hit.hit){
                ray.origin = hit.position + hit.normal * 1e-4;
                ray.direction = Random::RandomHemesphereDirection(hit.normal, seed);
                float3 emittedLight = hit.baseColor * hit.lightEmission;
                incomingLight += emittedLight * rayColor;
                rayColor *= hit.baseColor;

            }
            else{
                break;
            }
        }
        return incomingLight;
    }

    inline float3 DisplayBounceDirection(Ray ray, World world, thread uint &seed){
        float3 incomingLight = float3(0);
        float3 rayColor = float3(1); // white

        RayHit hit = raycastWorld(ray, world);
        
        if(hit.hit){
            ray.origin = hit.position + hit.normal * 1e-4;
            ray.direction = Random::RandomHemesphereDirection(hit.normal, seed);
            float3 emittedLight = hit.baseColor * hit.lightEmission;
            incomingLight += emittedLight * rayColor;
            rayColor *= hit.baseColor;

            // Test if RandomHemesphereDirection returns valid data
                float3 randomDir = Random::RandomHemesphereDirection(hit.normal, seed);

                // Check 1: Is it normalized? (length should be ~1.0)
                float len = length(randomDir);
                if (len < 0.9 || len > 1.1) {
                    return float3(1, 0, 0);  // RED = not normalized
                }

                // Check 2: Is it in the correct hemisphere? (should face same side as normal)
                float alignment = dot(randomDir, hit.normal);
                if (alignment < 0.0) {
                    return float3(1, 1, 0);  // YELLOW = wrong hemisphere
                }

                // Check 3: Visualize the direction
                return (randomDir + 1.0) * 0.5;  // Should be colorful like your normal test
        } 

        return 0.1;
    }
}