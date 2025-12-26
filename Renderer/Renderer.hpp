#ifndef RENDERER_HPP
#define RENDERER_HPP

#include "../worldstructs.h"

class Renderer {
public:
    Renderer(void* view);
    void updateBuffersWorld(const World& world);

private:
    void* objcRenderer; // RendererObjC*
};

#endif
