#pragma once
#include <simd/simd.h>
#include <cstdint>

struct Params {
    uint32_t drawableWidth;
    uint32_t drawableHeight;
    uint32_t inscribedWidth;
    uint32_t inscribedHeight;
    uint32_t offsetX;
    uint32_t offsetY;

    uint32_t frameIndex;
};
