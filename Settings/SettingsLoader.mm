#import <Foundation/Foundation.h>
#include "../worldstructs.hpp"
#include <stdio.h>

// Binary format - simple and fast
struct SceneFile {
    Camera camera;
    World world;
    Sphere spheres[100];
};

// Save scene to binary file
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

// Load scene from binary file
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

// Text format - human readable and editable
bool saveSceneText(const char* filepath, const WorldInfo& worldInfo) {
    FILE* f = fopen(filepath, "w");
    if (!f) {
        NSLog(@"Failed to open file for writing: %s", filepath);
        return false;
    }
    
    // Write camera
    fprintf(f, "CAMERA\n");
    fprintf(f, "position %.6f %.6f %.6f\n", 
            worldInfo.camera.position.x, 
            worldInfo.camera.position.y, 
            worldInfo.camera.position.z);
    fprintf(f, "target %.6f %.6f %.6f\n",
            worldInfo.camera.target.x,
            worldInfo.camera.target.y,
            worldInfo.camera.target.z);
    fprintf(f, "up %.6f %.6f %.6f\n",
            worldInfo.camera.up.x,
            worldInfo.camera.up.y,
            worldInfo.camera.up.z);
    fprintf(f, "fov %.6f\n", worldInfo.camera.FieldOfView);
    fprintf(f, "aspect %.6f\n", worldInfo.camera.Aspect);
    fprintf(f, "nearclip %.6f\n", worldInfo.camera.NearClipPlane);
    fprintf(f, "\n");
    
    // Write world
    fprintf(f, "WORLD\n");
    fprintf(f, "spherecount %u\n", worldInfo.world.sphereCount);
    fprintf(f, "frameindex %u\n", worldInfo.world.frameIndex);
    fprintf(f, "\n");
    
    // Write spheres
    for (uint32_t i = 0; i < worldInfo.world.sphereCount; i++) {
        const Sphere& s = worldInfo.spheres[i];
        fprintf(f, "SPHERE\n");
        fprintf(f, "center %.6f %.6f %.6f\n", s.center.x, s.center.y, s.center.z);
        fprintf(f, "radius %.6f\n", s.radius);
        fprintf(f, "color %.6f %.6f %.6f\n", s.baseColor.x, s.baseColor.y, s.baseColor.z);
        fprintf(f, "roughness %.6f\n", s.textureRoughness);
        fprintf(f, "emission %.6f\n", s.lightEmission);
        fprintf(f, "\n");
    }
    
    fclose(f);
    NSLog(@"Scene saved to %s", filepath);
    return true;
}

// Load scene from text file
bool loadSceneText(const char* filepath, WorldInfo& worldInfo) {
    FILE* f = fopen(filepath, "r");
    if (!f) {
        NSLog(@"Failed to open file for reading: %s", filepath);
        return false;
    }
    
    char line[256];
    uint32_t sphereIndex = 0;
    
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "CAMERA", 6) == 0) {
            // Read camera properties
            fscanf(f, "position %f %f %f\n", 
                   &worldInfo.camera.position.x,
                   &worldInfo.camera.position.y,
                   &worldInfo.camera.position.z);
            
            simd_float3 target, up;
            float fov, aspect, nearclip;
            
            fscanf(f, "target %f %f %f\n", &target.x, &target.y, &target.z);
            fscanf(f, "up %f %f %f\n", &up.x, &up.y, &up.z);
            fscanf(f, "fov %f\n", &fov);
            fscanf(f, "aspect %f\n", &aspect);
            fscanf(f, "nearclip %f\n", &nearclip);
            
            // Reconstruct camera with proper initialization
            worldInfo.camera = Camera(worldInfo.camera.position, target, up, fov, aspect, nearclip);
        }
        else if (strncmp(line, "WORLD", 5) == 0) {
            uint32_t sphereCount, frameIndex;
            fscanf(f, "spherecount %u\n", &sphereCount);
            fscanf(f, "frameindex %u\n", &frameIndex);
            worldInfo.world = World(sphereCount, frameIndex);
        }
        else if (strncmp(line, "SPHERE", 6) == 0) {
            simd_float3 center, color;
            float radius, roughness, emission;
            
            fscanf(f, "center %f %f %f\n", &center.x, &center.y, &center.z);
            fscanf(f, "radius %f\n", &radius);
            fscanf(f, "color %f %f %f\n", &color.x, &color.y, &color.z);
            fscanf(f, "roughness %f\n", &roughness);
            fscanf(f, "emission %f\n", &emission);
            
            worldInfo.spheres[sphereIndex++] = Sphere(center, radius, color, roughness, emission);
        }
    }
    
    fclose(f);
    NSLog(@"Scene loaded from %s (%u spheres)", filepath, worldInfo.world.sphereCount);
    return true;
}

// Usage in main.mm:
/*
// Save current scene
saveSceneBinary("scene.bin", worldInfo);
// or
saveSceneText("scene.txt", worldInfo);

// Load scene instead of initWorldInfo()
if (!loadSceneBinary("scene.bin", worldInfo)) {
    // Fallback to default
    initWorldInfo();
}
// or
if (!loadSceneText("scene.txt", worldInfo)) {
    initWorldInfo();
}
*/