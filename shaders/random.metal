#include <metal_stdlib>
using namespace metal;

namespace Random{
    inline float RandomFloat(thread uint &seed) {
    seed ^= seed << 13;
    seed ^= seed >> 17;
    seed ^= seed << 5;
    return float(seed) * (1.0 / 4294967296.0);
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
}