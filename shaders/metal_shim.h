#ifndef METAL_SHIM_H
#define METAL_SHIM_H

#include <simd/common.h>
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
inline float2 _metal_make_float2(int2 x) {
    return simd_make_float2(x.x, x.y);
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
inline float3 _metal_make_float3(int3 x) {
    return simd_make_float3(x.x, x.y, x.z);
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

inline float4 _metal_make_float4(int4 x) {
    return simd_make_float4(x.x, x.y, x.z, x.w);
}

// ---------- int2 ----------
inline int2 _metal_make_int2(int x) {
    return simd_make_int2(x, x);
}
inline int2 _metal_make_int2(int x, int y) {
    return simd_make_int2(x, y);
}
inline int2 _metal_make_int2(float2 v) {
    return simd_make_int2(int(v.x), int(v.y));
}

// ---------- int3 ----------
inline int3 _metal_make_int3(int x) {
    return simd_make_int3(x, x, x);
}
inline int3 _metal_make_int3(int x, int y, int z) {
    return simd_make_int3(x, y, z);
}
inline int3 _metal_make_int3(int2 v, int z) {
    return simd_make_int3(v.x, v.y, z);
}
inline int3 _metal_make_int3(int x, int2 v) {
    return simd_make_int3(x, v.x, v.y);
}
inline int3 _metal_make_int3(float3 v) {
    return simd_make_int3(int(v.x), int(v.y), int(v.z));
}

// ---------- int4 ----------
inline int4 _metal_make_int4(int x) {
    return simd_make_int4(x, x, x, x);
}
inline int4 _metal_make_int4(int x, int y, int z, int w) {
    return simd_make_int4(x, y, z, w);
}
inline int4 _metal_make_int4(int3 v, int w) {
    return simd_make_int4(v.x, v.y, v.z, w);
}
inline int4 _metal_make_int4(int x, int3 v) {
    return simd_make_int4(x, v.x, v.y, v.z);
}
inline int4 _metal_make_int4(int2 a, int2 b) {
    return simd_make_int4(a.x, a.y, b.x, b.y);
}
inline int4 _metal_make_int4(float4 v) {
    return simd_make_int4(int(v.x), int(v.y), int(v.z), int(v.w));
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

#define int2(...) _metal_make_int2(__VA_ARGS__)
#define int3(...) _metal_make_int3(__VA_ARGS__)
#define int4(...) _metal_make_int4(__VA_ARGS__)



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

inline float3 max(float3 a, float3 b) {return simd_max(a,b);}
inline float3 min(float3 a, float3 b) {return simd_min(a,b);}

// =======================================================
// Constants
// =======================================================
#define M_PI_F 3.14159265358979323846f
inline float max(float a, float b) {return simd_max(a,b);}
inline float min(float a, float b) {return simd_min(a,b);}
inline float3 abs(float3 a) {return simd_abs(a);}
inline float3 step(float3 a, float3 v){return simd_step(a,v);}

#endif // __INTELLISENSE__
#endif // METAL_SHIM_H
