#ifdef __INTELLISENSE__
#include "metal_shim.h"
#else
#include <metal_stdlib>
using namespace metal;
#endif


namespace Random{
    inline uint hash(uint x) {
        x ^= x >> 16;
        x *= 0x7feb352d;
        x ^= x >> 15;
        x *= 0x846ca68b;
        x ^= x >> 16;
        return x;
    }

    inline float RandomFloat(thread uint &seed) {
        seed = hash(seed);
        return float(seed) / 4294967295.0;
    }

    // Returns a random value in [0,1) based on the input seed
    inline float RandomNormalDist(thread uint &seed) {
        float theta = (2 *  M_PI_F  * RandomFloat(seed));
        float rho = sqrt(-2.0 * log(RandomFloat(seed)));
        return rho * cos(theta);
    }
    inline float3 RandomDirection(thread uint &seed){
        float x = RandomNormalDist(seed);
        float y = RandomNormalDist(seed);
        float z = RandomNormalDist(seed);
        return normalize(float3(x,y,z));
    }
    inline float3 RandomHemesphereDirection(float3 normal, thread uint &seed){
        float3 dir = RandomDirection(seed);
        if(dot(normal, dir) < 0.0) {
            return -dir;
        }
        
        return dir;

    }
}