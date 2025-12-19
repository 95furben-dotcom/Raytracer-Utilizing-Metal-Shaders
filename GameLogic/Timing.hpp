#pragma once

#include <chrono>
#include <cstdint>
#include <algorithm>

// Lightweight header-only timing and game-loop helpers usable from Objective-C++ (.mm)
// Usage:
//   GameLogic::Timing::Init();
//   while(rendering) {
//     GameLogic::Timing::Tick();
//     float dt = GameLogic::Timing::Delta();
//     uint32_t frame = GameLogic::Timing::FrameIndex();
//     // update game, render, etc.
//   }

namespace GameLogic {
namespace Timing {

using Clock = std::chrono::steady_clock;
using TimePoint = std::chrono::time_point<Clock>;

// Internal state (inline static variables for header-only safety)
inline TimePoint last;
inline float deltaSeconds = 1.0f / 60.0f;
inline float smoothDelta = 1.0f / 60.0f;
inline float fps = 60.0f;
inline uint32_t frameIndex = 0;
inline float accumulator = 0.0f;

inline void Init() {
    static bool inited = false;
    if (inited) return;
    inited = true;
    last = Clock::now();
    deltaSeconds = 1.0f / 60.0f;
    smoothDelta = deltaSeconds;
    frameIndex = 0;
    accumulator = 0.0f;
}

inline void Tick() {
    TimePoint now = Clock::now();
    std::chrono::duration<float> diff = now - last;
    float dt = diff.count();
    // clamp very large dt (e.g. after pause or debugger stop)
    if (dt > 0.5f) dt = 0.5f;
    last = now;

    deltaSeconds = dt;
    // exponential smoothing (alpha controls responsiveness)
    const float alpha = 0.08f; // smaller = smoother
    smoothDelta = smoothDelta * (1.0f - alpha) + deltaSeconds * alpha;

    fps = (deltaSeconds > 0.0f) ? (1.0f / deltaSeconds) : 0.0f;

    // increment frame index (one per Tick call)
    ++frameIndex;

    // accumulate for fixed timestep logic
    accumulator += deltaSeconds;
}

// Returns raw per-frame delta in seconds
inline float Delta() { return deltaSeconds; }
// Returns smoothed delta useful for UI display or non-critical animation
inline float SmoothedDelta() { return smoothDelta; }
// Returns FPS computed from the last frame
inline float FPS() { return fps; }
// Returns a steadily increasing frame counter (starts at 1 after first Tick)
inline uint32_t FrameIndex() { return frameIndex; }

// Fixed timestep helper: returns how many fixed updates should run now
// and reduces the internal accumulator accordingly (up to maxSteps).
inline int ConsumeFixedSteps(float fixedDt, int maxSteps = 5) {
    int steps = 0;
    while (accumulator >= fixedDt && steps < maxSteps) {
        accumulator -= fixedDt;
        ++steps;
    }
    return steps;
}

// Peek how much time remains in accumulator (for interpolation)
inline float Accumulator() { return accumulator; }

// Reset frame index and accumulator (useful on scene load)
inline void Reset(uint32_t startFrame = 0) {
    frameIndex = startFrame;
    accumulator = 0.0f;
}

} // namespace Timing
} // namespace GameLogic
