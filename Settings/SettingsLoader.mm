#include "../worldstructs.h"
#import <Foundation/Foundation.h>
#include <simd/vector_types.h>

// helpers 
    static NSArray* float3ToArray(simd_float3 v) {
        return @[@(v.x), @(v.y), @(v.z)];
    }
    static NSArray* int3ToArray(simd_int3 v) {
        return @[@(v.x), @(v.y), @(v.z)];
    }

    // Helper to convert NSArray to simd_float3
    static simd_float3 arrayToFloat3(NSArray* arr) {
        return simd_make_float3([arr[0] floatValue], [arr[1] floatValue], [arr[2] floatValue]);
    }
    static simd_int3 arrayToInt3(NSArray* arr) {
        return simd_make_int3([arr[0] intValue], [arr[1] intValue], [arr[2] intValue]);
    }

    NSDictionary* loadJSONDictionary(NSString* filePath, NSError** outError) {
        NSData* data = [NSData dataWithContentsOfFile:filePath options:0 error:outError];
        if (!data) {
            NSLog(@"Failed to read file: %@, error: %@", filePath, *outError);
            return nil;
        }

        id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                        options:NSJSONReadingMutableContainers
                                                        error:outError];
        if (!jsonObject) {
            NSLog(@"Failed to parse JSON: %@, error: %@", filePath, *outError);
            return nil;
        }

        if (![jsonObject isKindOfClass:[NSDictionary class]]) {
            NSLog(@"Expected a JSON dictionary at path: %@", filePath);
            return nil;
        }

        return (NSDictionary*)jsonObject;
    }

    bool saveJSONDictionary(NSString* filePath, id jsonObject, NSError** outError) {
        // Ensure it's a dictionary or array
        if (![jsonObject isKindOfClass:[NSDictionary class]] &&
            ![jsonObject isKindOfClass:[NSArray class]]) {
            NSLog(@"saveJSONDictionary: Root object must be NSDictionary or NSArray");
            return NO;
        }

        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                        options:NSJSONWritingPrettyPrinted
                                                            error:outError];
        if (!jsonData) {
            NSLog(@"Failed to serialize JSON: %@", *outError);
            return NO;
        }

        BOOL success = [jsonData writeToFile:filePath options:NSDataWritingAtomic error:outError];
        if (!success) {
            NSLog(@"Failed to write JSON file %@: %@", filePath, *outError);
            return NO;
        }

        return YES;
    }
    NSString* getFullPath(const char* filepath) {
        NSString* path = [NSString stringWithUTF8String:filepath];

        if ([path isAbsolutePath]) {
            return path;
        }

        NSURL* baseURL = [[[NSBundle mainBundle] executableURL]
                        URLByDeletingLastPathComponent];

        NSURL* fullURL = [NSURL URLWithString:path relativeToURL:baseURL];
        return fullURL.path;
    }



// For saving
namespace Macros {


#define TO_JSON_FIELD_FLOAT(obj, field) \
    dict[@#field] = @(obj.field);

#define TO_JSON_FIELD_FLOAT3(obj, field) \
    dict[@#field] = float3ToArray(obj.field);
    
#define TO_JSON_FIELD_INT3(obj, field) \
    dict[@#field] = int3ToArray(obj.field);
    

// fields 
#define CAMERA_FIELDS(X) \
    X(NearClipPlane, float) \
    X(Aspect, float) \
    X(FieldOfView, float) \
    X(position, simd_float3) \
    X(target, simd_float3) \
    X(up, simd_float3)

#define CHUNK_FIELDS(X) \
    X(position, simd_int3) \
    X(blocks, uint32_t[16][20][16]) // You’d still need special handling for arrays


// For saving to JSON
#define TO_JSON_FIELD(obj, field, type) \
    dict[@#field] = (type == simd_float3 ? float3ToArray(obj.field) : @(obj.field));

// For loading from JSON
#define FROM_JSON_FIELD(dict, obj, field, type) \
    if (type == simd_float3) { obj.field = arrayToFloat3(dict[@#field]); } \
    else { obj.field = [dict[@#field] floatValue]; }

#define TO_JSON_FIELD_3DARRAY(obj, field, width, height, depth) \
    { \
        NSMutableArray* arrX = [NSMutableArray arrayWithCapacity:width]; \
        for (int x = 0; x < width; x++) { \
            NSMutableArray* arrY = [NSMutableArray arrayWithCapacity:height]; \
            for (int y = 0; y < height; y++) { \
                NSMutableArray* arrZ = [NSMutableArray arrayWithCapacity:depth]; \
                for (int z = 0; z < depth; z++) { \
                    [arrZ addObject:@(obj.field[x][y][z])]; \
                } \
                [arrY addObject:arrZ]; \
            } \
            [arrX addObject:arrY]; \
        } \
        dict[@#field] = arrX; \
    }
    // Load simd_int3
    #define FROM_JSON_FIELD_INT3(dict, obj, field) \
    { \
        NSArray* arr = dict[@#field]; \
        if (arr && arr.count == 3) { \
            obj.field = simd_make_int3([arr[0] intValue], [arr[1] intValue], [arr[2] intValue]); \
        } \
    }

// Load 3D uint32_t array
    #define FROM_JSON_FIELD_3DARRAY(dict, obj, field, width, height, depth) \
    { \
        NSArray* arrX = dict[@#field]; \
        if (!arrX || arrX.count != width) return false; \
        for (NSUInteger x = 0; x < width; x++) { \
            NSArray* arrY = arrX[x]; \
            if (!arrY || arrY.count != height) continue; \
            for (NSUInteger y = 0; y < height; y++) { \
                NSArray* arrZ = arrY[y]; \
                if (!arrZ || arrZ.count != depth) continue; \
                for (NSUInteger z = 0; z < depth; z++) { \
                    obj.field[x][y][z] = [arrZ[z] unsignedIntValue]; \
                } \
            } \
        } \
    }


}

// actual functions 
NSDictionary* cameraToJSON(const Camera& cam) {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    TO_JSON_FIELD_FLOAT(cam, NearClipPlane)
    TO_JSON_FIELD_FLOAT(cam, Aspect)
    TO_JSON_FIELD_FLOAT(cam, fovRad)
    TO_JSON_FIELD_FLOAT3(cam, position)
    TO_JSON_FIELD_FLOAT3(cam, target)
    TO_JSON_FIELD_FLOAT3(cam, up)

    return dict;
}

bool cameraFromJSON(NSDictionary* dict, Camera& cam) {
    cam.NearClipPlane = [dict[@"NearClipPlane"] floatValue];
    cam.Aspect        = [dict[@"Aspect"] floatValue];
    cam.fovRad   = [dict[@"fovRad"] floatValue];

    cam.position = arrayToFloat3(dict[@"position"]);
    cam.target   = arrayToFloat3(dict[@"target"]);
    cam.up       = arrayToFloat3(dict[@"up"]);

    return true;
}

// Save chunk in binary format
void saveChunkBinary(NSString* worldFolder, Chunk chunk) {
    NSString* fileName = [NSString stringWithFormat:@"chunks/%d_%d_%d.chunk", 
                          chunk.position.x, chunk.position.y, chunk.position.z];
    NSString* chunkPath = [worldFolder stringByAppendingPathComponent:fileName];

    NSMutableData* data = [NSMutableData dataWithCapacity:sizeof(Chunk)];
    
    // Write position (12 bytes: 3 × int32)
    [data appendBytes:&chunk.position length:sizeof(simd_int3)];
    
    // Write blocks (4096 bytes: 16×16×16 × uint8)
    [data appendBytes:chunk.blocks length:Chunk::width * Chunk::height * Chunk::depth];
    
    NSError* error = nil;
    BOOL success = [data writeToFile:chunkPath options:NSDataWritingAtomic error:&error];
    if (!success) {
        NSLog(@"Failed to save chunk: %@", error);
    }
}

// Load chunk from binary format
bool loadChunkBinary(NSString* chunkPath, Chunk& chunk) {
    NSError* error = nil;
    NSData* data = [NSData dataWithContentsOfFile:chunkPath options:0 error:&error];
    
    if (!data) {
        return false;
    }
    
    // Verify size
    NSUInteger expectedSize = sizeof(simd_int3) + (Chunk::width * Chunk::height * Chunk::depth);
    if (data.length != expectedSize) {
        NSLog(@"Chunk file corrupted: expected %lu bytes, got %lu", expectedSize, data.length);
        return false;
    }
    
    const uint8_t* bytes = (const uint8_t*)[data bytes];
    
    // Read position
    memcpy(&chunk.position, bytes, sizeof(simd_int3));
    bytes += sizeof(simd_int3);
    
    // Read blocks
    memcpy(chunk.blocks, bytes, Chunk::width * Chunk::height * Chunk::depth);
    
    return true;
}

// Updated loadAndAddChunk
void loadAndAddChunk(NSString* worldFolder, simd_int3 pos, World& world) {
    NSString* fileName = [NSString stringWithFormat:@"chunks/%d_%d_%d.chunk", pos.x, pos.y, pos.z];
    NSString* chunkPath = [worldFolder stringByAppendingPathComponent:fileName];

    Chunk loadedChunk;
    
    if (!loadChunkBinary(chunkPath, loadedChunk)) {
        NSLog(@"Could not find chunk; generating new (%d,%d,%d)", pos.x, pos.y, pos.z);
        loadedChunk = Chunk(pos);
    }

    int i = world.worldinfo.chunkCount;
    world.chunks[i] = loadedChunk;
    world.worldinfo.chunkCount += 1;
}

// Updated saveWorld
bool saveWorld(World world, const char* worldPath) {
    NSString* worldFolder = getFullPath(worldPath);

    // Still save camera as JSON (it's small and useful to edit)
    NSError* error = nil;
    NSString* cameraPath = [worldFolder stringByAppendingPathComponent:@"camera.json"];
    NSDictionary* dict = cameraToJSON(world.camera);
    saveJSONDictionary(cameraPath, dict, &error);

    // Save chunks in binary format
    for (int i = 0; i < world.worldinfo.chunkCount; i++) {
        saveChunkBinary(worldFolder, world.chunks[i]);
    }
    
    return true;
}





