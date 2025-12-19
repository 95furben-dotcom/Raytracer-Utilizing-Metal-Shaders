#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <simd/simd.h>
#include "Renderer.hpp"
#include "RendererStructs.hpp"
#include "../worldstructs.hpp"


// Use SIMD types for vectors (compatible with Metal shader types)
// simd_float3 / simd_uint2 are provided by <simd/simd.h>

Params params;


@interface RendererObjC : NSObject <MTKViewDelegate>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) id<MTLRenderPipelineState> pipelineState;

// buffers 
// vertex parameters buffer
@property(nonatomic, strong) id<MTLBuffer> paramsBuffer;

// fragment buffers
@property(nonatomic, strong) id<MTLBuffer> cameraBuffer;
@property(nonatomic, strong) id<MTLBuffer> worldBuffer;
@property(nonatomic, strong) id<MTLBuffer> sphereBuffer;


@end

@implementation RendererObjC

- (instancetype)initWithView:(MTKView*)view {
    if (self = [super init]) {
        [self setupDevice:view];
        [self setupPipeline:view];
        view.delegate = self;
    }
    return self;
}

- (void)setupDevice:(MTKView*)view {
    self.device = MTLCreateSystemDefaultDevice();
    view.device = self.device;
    self.commandQueue = [self.device newCommandQueue];
    
    // ✅ Initialize params with drawable size
    CGSize dsize = view.drawableSize;
    [self mtkView:view drawableSizeWillChange:dsize];
}

- (void)updateBuffersWorld:(World)world
                        camera:(Camera)camera
                      spheres:(Sphere *)spheres
{
    params.frameIndex += 1;
    // Update Params struct and recreate buffer
    // compute an inscribed 16:9 region centered in the drawable

    // vertex params buffer
    self.paramsBuffer = [self.device newBufferWithBytes:&params
                                                 length:sizeof(Params)
                                                options:MTLResourceStorageModeShared];
    // fragment buffers
    self.cameraBuffer = [self.device newBufferWithBytes:&camera
                                                 length:sizeof(Camera)
                                                options:MTLResourceStorageModeShared];
    self.worldBuffer = [self.device newBufferWithBytes:&world
                                                length:sizeof(World)
                                               options:MTLResourceStorageModeShared];
    self.sphereBuffer = [self.device newBufferWithBytes:spheres
                                                 length:sizeof(Sphere) * world.sphereCount
                                                options:MTLResourceStorageModeShared];

}

- (void)setupPipeline:(MTKView*)view {
    NSError* error = nil;

    // Try a `shaders` subfolder inside Resources
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *libPath = [bundlePath stringByAppendingPathComponent:@"shaders/compiles/compiledShader.metallib"];
    

    if (!libPath || ![[NSFileManager defaultManager] fileExistsAtPath:libPath]) {
        NSLog(@"Failed to find compiled metallib at expected paths (tried compiledShader.metallib and shaders/compiledShader.metallib)");
        return;
    }

    // `newLibraryWithURL:` expects an NSURL; convert the NSString path to an NSURL
    NSURL *libURL = [NSURL fileURLWithPath:libPath];
    id<MTLLibrary> library = [self.device newLibraryWithURL:libURL error:&error];
    if (!library) { NSLog(@"Failed to load shader library from URL '%@': %@", libURL, error); return; }

    MTLRenderPipelineDescriptor* descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    descriptor.vertexFunction = [library newFunctionWithName:@"vertex_main"];
    descriptor.fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;

    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:descriptor error:&error];
    if (!self.pipelineState) { NSLog(@"Pipeline creation failed: %@", error); }
}

- (void)mtkView:(MTKView *)view 
        drawableSizeWillChange:(CGSize)size 
{
    uint32_t width = (uint32_t)size.width;
    uint32_t height = (uint32_t)size.height;
    // Update params to match the new drawable size so shaders render at full resolution
    float targetRatio = 16.0f / 10.0f;
    float currentRatio = (float)width / (float)height;

    uint32_t insW = width;
    uint32_t insH = height;

    if (currentRatio > targetRatio) {
        // drawable is wider than 16:9 -> inscribed width limited by height
        insH = height;
        insW = (uint32_t)(insH * targetRatio);
    } else {
        // drawable is taller than 16:9 -> inscribed height limited by width
        insW = width;
        insH = (uint32_t)(insW / targetRatio);
    }

    params.drawableWidth = width;
    params.drawableHeight = height;
    params.inscribedWidth = insW;
    params.inscribedHeight = insH;
    params.offsetX = (width - insW) / 2;
    params.offsetY = (height - insH) / 2;
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> buffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor* passDesc = view.currentRenderPassDescriptor;
    if (!passDesc) return;

    id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:passDesc];
    [self encodeDrawCalls:encoder];
    [encoder endEncoding];

    [buffer presentDrawable:view.currentDrawable];
    [buffer commit];
}

- (void)encodeDrawCalls:(id<MTLRenderCommandEncoder>)encoder {
    [encoder setRenderPipelineState:self.pipelineState];
    
    // Bind Params buffer to buffer index 0
    [encoder setVertexBuffer:self.paramsBuffer offset:0 atIndex:0];
    // Also bind for fragment stage so fragments can read the same params (no interpolation)
    // set fragment buffers


    [encoder setFragmentBuffer:self.cameraBuffer offset:0 atIndex:0];
    [encoder setFragmentBuffer:self.worldBuffer offset:0 atIndex:1];
    [encoder setFragmentBuffer:self.sphereBuffer offset:0 atIndex:2];

    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

@end

Renderer::Renderer(void* view) {
    RendererObjC* r = [[RendererObjC alloc] initWithView:(MTKView*)view];
    objcRenderer = (__bridge_retained void*)r;
}
void Renderer::updateBuffersWorld(
    const World& world,
    const Camera& camera,
    const Sphere* spheres)
{
    RendererObjC* r = (__bridge RendererObjC*)objcRenderer;
    [r updateBuffersWorld:world
                   camera:camera
                  spheres:(Sphere*)spheres];
}
