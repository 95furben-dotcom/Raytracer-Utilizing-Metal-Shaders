#import <Cocoa/Cocoa.h>
#include <MacTypes.h>
#include <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#include "Renderer/Renderer.hpp"
#include "GameLogic/Timing.hpp"
#include "worldstructs.h"
#include "Settings/SettingsLoader.hpp" // for WorldInfo

// ---------------- WindowDelegate ----------------
@interface WindowDelegate : NSObject <NSWindowDelegate>
@property(nonatomic, assign) BOOL isClosed;
@end

@implementation WindowDelegate
- (void)windowWillClose:(NSNotification *)notification {
    self.isClosed = YES;
}
@end
// ------------------------------------------------

World world; // global instance
const char* worldPath = "Settings/World";
// Global scale factor



NSWindow* createWindow(CGRect frame, MTKView** outMetalView, WindowDelegate** outDelegate) {
    NSWindow* window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:(NSWindowStyleMaskTitled |
                                                              NSWindowStyleMaskClosable |
                                                              NSWindowStyleMaskResizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window makeKeyAndOrderFront:nil];

    // Metal view that fills the window content
    MTKView* metalView = [[MTKView alloc] initWithFrame:[window.contentView bounds]];

    // metalView.enableSetNeedsDisplay = NO; // automatic redraw
    // metalView.preferredFramesPerSecond = 0; // max FPS
    //metalView.paused = NO; // continuous rendering
    // res scale 

    metalView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    metalView.drawableSize = CGSizeMake(metalView.frame.size.width,
                                    metalView.frame.size.height);

    [window.contentView addSubview:metalView];

    // Window delegate
    WindowDelegate* delegate = [WindowDelegate new];
    window.delegate = delegate;

    *outMetalView = metalView;
    *outDelegate = delegate;

    // Keep the metal view filling the content and update drawableSize on resize
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResizeNotification
                                                      object:window
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSRect content = [window.contentView frame];
        [metalView setFrame:content];
        metalView.drawableSize = CGSizeMake(content.size.width, content.size.height);
    }];

    return window;
}
void runEventLoop(NSApplication* app, MTKView* metalView, WindowDelegate* delegate, Renderer& renderer) {
    while (!delegate.isClosed) {
        NSEvent* event;
        while ((event = [app nextEventMatchingMask:NSEventMaskAny
                                        untilDate:[NSDate distantPast]
                                           inMode:NSDefaultRunLoopMode
                                          dequeue:YES])) {
            [app sendEvent:event];
        }

        // ✅ Timing
        GameLogic::Timing::Tick();
        float fps = GameLogic::Timing::FPS();
        uint32_t _frameForPrint = GameLogic::Timing::FrameIndex();
        if ((_frameForPrint % 60) == 0) {
            NSLog(@"FPS: %.2f", fps);
        }

        // world.worldinfo.frameIndex += 1;
        // renderer.updateBuffersWorld(world);

        [metalView draw];
    }
    
}

bool initWorldInfo() {
    NSString* worldFolder = getFullPath(worldPath);
    NSString* cameraPath = [worldFolder stringByAppendingPathComponent:@"camera.json"];

    NSError* error = nil;
    NSDictionary* dict = loadJSONDictionary(cameraPath, &error);
    
    // Check if dict exists BEFORE using it
    if (!dict) {
        NSLog(@"Camera file not found, initializing default camera");
        world.camera = Camera();
    } else {
        bool success = cameraFromJSON(dict, world.camera);
        if(!success){
            NSLog(@"Failed to parse camera, using default");
            world.camera = Camera();
        }
    }

    // Ensure camera is behind the chunk and looking at it


// Compute derived camera data
world.camera.UpdateData();

    
    simd_int3 pos = {0,0,0};
    loadAndAddChunk(worldFolder, pos, world);
    return true;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication* app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app activateIgnoringOtherApps:YES];

        MTKView* metalView = nil;
        WindowDelegate* delegate = nil;

        bool succes = initWorldInfo();
        if(!succes)
        {
            return 1;
        }

        NSWindow* window = createWindow(NSMakeRect(0, 0, 800, 600), &metalView, &delegate);

        Renderer renderer((void*)metalView);
    
        renderer.updateBuffersWorld(world);


        // init GameLogic::Timing
        GameLogic::Timing::Init();
        runEventLoop(app, metalView, delegate, renderer);
    }
    saveWorld(world, worldPath);
    return 0;
}
