#ifndef METAL_SHIM_H
#define METAL_SHIM_H

#ifdef __INTELLISENSE__

// =======================================================
// Metal address space & attribute no-ops
// =======================================================
#define vertex
#define fragment
#define kernel
#define thread
#define device
#define constant
#define threadgroup

#define buffer(x)
#define texture2d(T, A)
#define sampler

#define stage_in
#define vertex_id
#define instance_id
#define position(...)
#define color(...)
#define depth(...)

// =======================================================
// SIMD types (REAL types, not wrappers)
// =======================================================
#include <simd/simd.h>
#include <simd/vector_make.h>

using float2 = simd::float2;
using float3 = simd::float3;
using float4 = simd::float4;

using half   = float;
using half2  = simd::float2;
using half3  = simd::float3;
using half4  = simd::float4;

using int2  = simd::int2;
using int3  = simd::int3;
using int4  = simd::int4;

using uint2 = simd::uint2;
using uint3 = simd::uint3;
using uint4 = simd::uint4;

using uchar  = unsigned char;
using ushort = unsigned short;
using uint   = unsigned int;
using int8   = signed char;
using int16  = short;
using int32  = int;
using int64  = long long;
using uint8  = unsigned char;
using uint16 = unsigned short;
using uint32 = unsigned int;
using uint64 = unsigned long long;

// =======================================================
// Constructor helpers (REAL overloads, not macros)
// =======================================================
// ---------- float2 ----------
inline float2 _metal_make_float2(float x) {
    return simd_make_float2(x, x);
}
inline float2 _metal_make_float2(float x, float y) {
    return simd_make_float2(x, y);
}

// ---------- float3 ----------
inline float3 _metal_make_float3(float x) {
    return simd_make_float3(x, x, x);
}
inline float3 _metal_make_float3(float x, float y, float z) {
    return simd_make_float3(x, y, z);
}
inline float3 _metal_make_float3(float2 v, float z) {
    return simd_make_float3(v.x, v.y, z);
}
inline float3 _metal_make_float3(float x, float2 v) {
    return simd_make_float3(x, v.x, v.y);
}

// ---------- float4 ----------
inline float4 _metal_make_float4(float x) {
    return simd_make_float4(x, x, x, x);
}
inline float4 _metal_make_float4(float x, float y, float z, float w) {
    return simd_make_float4(x, y, z, w);
}
inline float4 _metal_make_float4(float3 v, float w) {
    return simd_make_float4(v.x, v.y, v.z, w);
}
inline float4 _metal_make_float4(float w, float3 v) {
    return simd_make_float4(w, v.x, v.y, v.z);
}
inline float4 _metal_make_float4(float2 a, float2 b) {
    return simd_make_float4(a.x, a.y, b.x, b.y);
}
// =======================================================
// Single variadic macro per vector (NO type shadowing)
// =======================================================
#define float2(...) _metal_make_float2(__VA_ARGS__)
#define float3(...) _metal_make_float3(__VA_ARGS__)
#define float4(...) _metal_make_float4(__VA_ARGS__)

#define half2(...)  _metal_make_float2(__VA_ARGS__)
#define half3(...)  _metal_make_float3(__VA_ARGS__)
#define half4(...)  _metal_make_float4(__VA_ARGS__)


// =======================================================
// SIMD math passthroughs (no conflicts)
// =======================================================
inline float dot(float3 a, float3 b)    { return simd::dot(a, b); }
inline float3 cross(float3 a, float3 b) { return simd::cross(a, b); }

inline float length(float2 v) { return simd::length(v); }
inline float length(float3 v) { return simd::length(v); }
inline float length(float4 v) { return simd::length(v); }

inline float2 normalize(float2 v) { return simd::normalize(v); }
inline float3 normalize(float3 v) { return simd::normalize(v); }
inline float4 normalize(float4 v) { return simd::normalize(v); }

// =======================================================
// Constants
// =======================================================
#define M_PI_F 3.14159265358979323846f

#endif // __INTELLISENSE__
#endif // METAL_SHIM_H
