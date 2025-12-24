#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#include "Renderer/Renderer.hpp"
#include "GameLogic/Timing.hpp"
#include "worldstructs.hpp"
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

WorldInfo worldInfo; // global instance


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
    metalView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    metalView.drawableSize = metalView.frame.size;
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

        worldInfo.camera.UpdateData();

        renderer.updateBuffersWorld(
            worldInfo.world,
            worldInfo.camera,
            worldInfo.spheres
        );

        [metalView draw];
        
        // ✅ ADD THIS: Limit frame rate to ~60 FPS
        [NSThread sleepForTimeInterval:1.0/60.0];
    }
}

bool initWorldInfo() {
    const char* path = "Settings/scene.json";
    // load settings
    if (!loadSceneText(path, worldInfo)) {
        NSLog(@"No scene file found, using default");
        bool defaultSceneLoadSucsess = loadSceneText("Settings/default_scene.json", worldInfo);
        if(!defaultSceneLoadSucsess){
            NSLog(@"failed to load default scene");
            return NO;
        }
        // Optionally save the default scene
        saveSceneText(path, worldInfo);
    }
    return YES;
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
        worldInfo.camera.UpdateData();

        NSWindow* window = createWindow(NSMakeRect(0, 0, 800, 600), &metalView, &delegate);

        Renderer renderer((void*)metalView);
       
        
        
        renderer.updateBuffersWorld(
            worldInfo.world,
            worldInfo.camera,
            worldInfo.spheres
        );



        // init GameLogic::Timing
        GameLogic::Timing::Init();
        runEventLoop(app, metalView, delegate, renderer);
    }
    return 0;
}
