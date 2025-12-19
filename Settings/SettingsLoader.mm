#import <Foundation/Foundation.h>
#include "../worldstructs.hpp"

// Helper to convert simd_float3 to NSArray
static NSArray* float3ToArray(simd_float3 v) {
    return @[@(v.x), @(v.y), @(v.z)];
}

// Helper to convert NSArray to simd_float3
static simd_float3 arrayToFloat3(NSArray* arr) {
    return simd_make_float3([arr[0] floatValue], [arr[1] floatValue], [arr[2] floatValue]);
}

// Helper to get full path in the app's directory
static NSString* getFullPath(const char* filepath) {
    NSString* filename = [NSString stringWithUTF8String:filepath];
    
    // If it's already an absolute path, use it
    if ([filename hasPrefix:@"/"]) {
        return filename;
    }
    
    // Otherwise, put it in the executable's directory
    NSString* execPath = [[NSBundle mainBundle] executablePath];
    NSString* execDir = [execPath stringByDeletingLastPathComponent];
    return [execDir stringByAppendingPathComponent:filename];
}

// Save scene to JSON file
bool saveSceneText(const char* filepath, const WorldInfo& worldInfo) {
    NSMutableDictionary* scene = [NSMutableDictionary dictionary];
    
    // Camera
    scene[@"camera"] = @{
        @"position": float3ToArray(worldInfo.camera.position),
        @"target": float3ToArray(worldInfo.camera.target),
        @"up": float3ToArray(worldInfo.camera.up),
        @"fov": @(worldInfo.camera.FieldOfView),
        @"aspect": @(worldInfo.camera.Aspect),
        @"nearclip": @(worldInfo.camera.NearClipPlane)
    };
    
    // World
    scene[@"world"] = @{
        @"sphereCount": @(worldInfo.world.sphereCount),
        @"frameIndex": @(worldInfo.world.frameIndex)
    };
    
    // Spheres
    NSMutableArray* spheres = [NSMutableArray array];
    for (uint32_t i = 0; i < worldInfo.world.sphereCount; i++) {
        const Sphere& s = worldInfo.spheres[i];
        [spheres addObject:@{
            @"center": float3ToArray(s.center),
            @"radius": @(s.radius),
            @"color": float3ToArray(s.baseColor),
            @"roughness": @(s.textureRoughness),
            @"emission": @(s.lightEmission)
        }];
    }
    scene[@"spheres"] = spheres;
    
    // Serialize to JSON
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:scene
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error) {
        NSLog(@"Failed to serialize JSON: %@", error);
        return false;
    }
    
    // Write to file
    NSString* path = getFullPath(filepath);
    BOOL success = [jsonData writeToFile:path atomically:YES];
    
    if (success) {
        NSLog(@"Scene saved to %@", path);
    } else {
        NSLog(@"Failed to write JSON file: %@", path);
    }
    
    return success;
}

// Load scene from JSON file
bool loadSceneText(const char* filepath, WorldInfo& worldInfo) {
    NSString* path = getFullPath(filepath);
    
    // Read file
    NSError* error = nil;
    NSData* jsonData = [NSData dataWithContentsOfFile:path];
    if (!jsonData) {
        NSLog(@"Failed to read file: %@", path);
        return false;
    }
    
    // Parse JSON
    NSDictionary* scene = [NSJSONSerialization JSONObjectWithData:jsonData
                                                          options:0
                                                            error:&error];
    if (error) {
        NSLog(@"Failed to parse JSON: %@", error);
        return false;
    }
    
    // Load camera
    NSDictionary* camDict = scene[@"camera"];
    simd_float3 position = arrayToFloat3(camDict[@"position"]);
    simd_float3 target = arrayToFloat3(camDict[@"target"]);
    simd_float3 up = arrayToFloat3(camDict[@"up"]);
    float fov = [camDict[@"fov"] floatValue];
    float aspect = [camDict[@"aspect"] floatValue];
    float nearclip = [camDict[@"nearclip"] floatValue];
    
    worldInfo.camera = Camera(position, target, up, fov, aspect, nearclip);
    
    // Load world
    NSDictionary* worldDict = scene[@"world"];
    uint32_t sphereCount = [worldDict[@"sphereCount"] unsignedIntValue];
    uint32_t frameIndex = [worldDict[@"frameIndex"] unsignedIntValue];
    worldInfo.world = World(sphereCount, frameIndex);
    
    // Load spheres
    NSArray* spheresArray = scene[@"spheres"];
    for (uint32_t i = 0; i < spheresArray.count && i < 100; i++) {
        NSDictionary* sphereDict = spheresArray[i];
        
        simd_float3 center = arrayToFloat3(sphereDict[@"center"]);
        float radius = [sphereDict[@"radius"] floatValue];
        simd_float3 color = arrayToFloat3(sphereDict[@"color"]);
        float roughness = [sphereDict[@"roughness"] floatValue];
        float emission = [sphereDict[@"emission"] floatValue];
        
        worldInfo.spheres[i] = Sphere(center, radius, color, roughness, emission);
    }
    
    NSLog(@"Scene loaded from %@ (%u spheres)", path, worldInfo.world.sphereCount);
    return true;
}

// Binary format - simple and fast (kept for compatibility)
struct SceneFile {
    Camera camera;
    World world;
    Sphere spheres[100];
};

bool saveSceneBinary(const char* filepath, const WorldInfo& worldInfo) {
    SceneFile scene;
    scene.camera = worldInfo.camera;
    scene.world = worldInfo.world;
    
    for (uint32_t i = 0; i < worldInfo.world.sphereCount && i < 100; i++) {
        scene.spheres[i] = worldInfo.spheres[i];
    }
    
    FILE* f = fopen(filepath, "wb");
    if (!f) {
        NSLog(@"Failed to open file for writing: %s", filepath);
        return false;
    }
    
    size_t written = fwrite(&scene, sizeof(SceneFile), 1, f);
    fclose(f);
    
    if (written != 1) {
        NSLog(@"Failed to write scene file");
        return false;
    }
    
    NSLog(@"Scene saved to %s", filepath);
    return true;
}

bool loadSceneBinary(const char* filepath, WorldInfo& worldInfo) {
    FILE* f = fopen(filepath, "rb");
    if (!f) {
        NSLog(@"Failed to open file for reading: %s", filepath);
        return false;
    }
    
    SceneFile scene;
    size_t read = fread(&scene, sizeof(SceneFile), 1, f);
    fclose(f);
    
    if (read != 1) {
        NSLog(@"Failed to read scene file");
        return false;
    }
    
    worldInfo.camera = scene.camera;
    worldInfo.world = scene.world;
    
    for (uint32_t i = 0; i < scene.world.sphereCount && i < 100; i++) {
        worldInfo.spheres[i] = scene.spheres[i];
    }
    
    NSLog(@"Scene loaded from %s (%u spheres)", filepath, scene.world.sphereCount);
    return true;
}