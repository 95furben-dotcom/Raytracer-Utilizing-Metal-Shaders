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

    float ndcX = (px / float(params.inscribedWidth)) * 2.0 - 1.0;
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
    constant Chunk *chunks [[buffer(2)]]
    ) 
{


    float3 direction = camera.GetDirection(in.uv);

    // Fix: use &camera to get pointer, and use inWorld not world
    World world;
    world.chunks = chunks;           // just assign the pointer
    world.chunkCount = inWorld.chunkCount;

    Ray ray = RayTracer::createRay(camera.position, direction);

    uint tempseed = in.position.x + in.position.y * 6578;

    uint randomSeed = uint(Random::RandomFloat(tempseed) * 1000);
    // Chunk chunk;
    // chunk.position = int3(0,0,0); // origin
    // // Blocks are irrelevant for bounding box visualization
    // for(int x=0; x<CHUNK_SIZE.x; x++)
    //     for(int y=0; y<CHUNK_SIZE.y; y++)
    //         for(int z=0; z<CHUNK_SIZE.z; z++){
    //         int index = x + y*CHUNK_SIZE.x + z * CHUNK_SIZE.x* CHUNK_SIZE.y;
    //         chunk.blocks[index] = 0; 
    //     }


    // RayHit hit = RayTracer::raycastChunkBounds(ray, chunk);

    // if(hit.hit){
    //     float ligth = -0.02*(hit.distance-45);
    //     int sum = (int)hit.position.x + (int)hit.position.y + (int)hit.position.z;
    //     float3 color = (sum % 2 == 0) ? float3(1,0,0) : float3(0,0,1);
    //     return  float4(ligth*color,0);
    // }
    // else return 0.1;

    RayHit hit = RayTracer::raycastChunk(ray, chunks[0]);

    if(hit.hit){
        float ligth = -0.02*(hit.distance-45);
        return  ligth;
    }
    else return 0.1;
}   