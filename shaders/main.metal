#ifdef __INTELLISENSE__
#include "metal_shim.h"
#else
#include <metal_stdlib>
using namespace metal;
#endif

#include "common.metal"
#include "raytracing.metal"


vertex VertexOut vertex_main(
    uint vertexID [[vertex_id]],
    constant Params& params [[buffer(0)]]
)
{
    VertexOut out;

    float u;
    float v;
    switch (vertexID) {
        case 0: u = 0.0; v = 1.0; break; // TL
        case 1: u = 0.0; v = 0.0; break; // BL
        case 2: u = 1.0; v = 0.0; break; // BR
        case 3: u = 0.0; v = 1.0; break; // TL
        case 4: u = 1.0; v = 0.0; break; // BR
        default: u = 1.0; v = 1.0; break; // TR
    }

    float px = float(params.offsetX) + u * float(params.inscribedWidth);
    float py = float(params.offsetY) + v * float(params.inscribedHeight);

    float ndcX = (px / float(params.drawableWidth)) * 2.0 - 1.0;
    float ndcY = (py / float(params.drawableHeight)) * 2.0 - 1.0;

    out.position = float4(ndcX, ndcY, 0.0, 1.0);
    // out.pixelCoord = float2(px, py);
    out.uv = float2(u, v);
    return out;
}

fragment float4 fragment_main(
    VertexOut in [[stage_in]],
    constant Camera& camera [[buffer(0)]],
    constant WorldInfo &inWorld [[buffer(1)]],
    constant Sphere *spheres [[buffer(2)]]
    ) {

    return float4(1);
    // Build a simple camera ray from UV and camera params
    float3 forward = (camera.forward);
    float3 right = (camera.right);
    float3 up = (camera.up);


    float2 posOnPlane = float2(
        camera.planeWidth * (in.uv.x - 0.5),
        camera.planeHeight * (0.5 - in.uv.y)
    );

    float3 localDirection = normalize(
        float3(
            posOnPlane.x,
            posOnPlane.y,
            camera.NearClipPlane
        )
    );

    float3 direction = normalize(
        localDirection.x * right +
        localDirection.y * up +
        localDirection.z * forward
    );

    // Fix: use &camera to get pointer, and use inWorld not world
    World world = World(spheres, &camera, inWorld.sphereCount, inWorld.frameIndex);

    Ray ray = RayTracer::createRay(camera.position, direction);

    uint randomSeed = uint(in.position.x) + uint(in.position.y) * 8192u + inWorld.frameIndex * 1729u;


    // works 
    // RayHit hit = RayTracer::raycastWorld(ray, world);
    // if (hit.hit) return float4(hit.baseColor,1);
    // else return 0.1;

    float3 hitColor = RayTracer::DisplayBounceDirection(ray, world,randomSeed);
    return float4(hitColor,0);

    }


//     int originSphereInt = -1;
//     // RayHit raycastWorld(Ray ray, constant World &world, constant Sphere* spheres)
//     RayHit hit = RayTracer::raycastWorld(ray, world, spheres, originSphereInt);
    
//     float4 originalColor = spheres[originSphereInt].baseColor;

//     if (!hit.hit) {
//         return float4(0.1); // close to black
//     }

//     // do one more bounce for some simple diffuse lighting
//     constant float& texRough = spheres[originSphereInt].textureRoughness;
//     Ray bounceRay = RayTracer::createBounceRay(ray, hit, 0 , randomSeed);

//     int closestSphereInt;
//     RayHit hit2 = RayTracer::raycastWorld(bounceRay, world, spheres, closestSphereInt);
//     if(!hit2.hit){
//         return originalColor * 0.1;
//     }

//     float lightEmission = spheres[closestSphereInt].lightEmission;


//     return originalColor*lightEmission;
// }