#pragma once

#include <simd/simd.h> // simd_float3/int3

// Forward declarations only for C++ structs
struct Camera;
struct Chunk;

#ifdef __OBJC__   // Only for Obj-C translation units
#import <Foundation/Foundation.h>

// JSON conversions
NSDictionary* cameraToJSON(const Camera& cam);
bool cameraFromJSON(NSDictionary* dict, Camera& cam);

bool saveWorld(World world, const char* worldPath);
void loadAndAddChunk(NSString* worldFolder, simd_int3 pos, World& world);

// File utilities
NSString* getFullPath(const char* filepath);
NSDictionary* loadJSONDictionary(NSString* filePath, NSError** outError);
bool saveJSONDictionary(NSString* filePath, id jsonObject, NSError** outError);

#endif
