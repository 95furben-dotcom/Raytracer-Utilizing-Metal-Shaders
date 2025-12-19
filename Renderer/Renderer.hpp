#ifndef RENDERER_HPP
#define RENDERER_HPP

#include "../worldstructs.hpp"

class Renderer {
public:
    Renderer(void* view);
    void updateBuffersWorld(
                    const World& world,
                    const Camera& camera,
                    const Sphere* spheres);

private:
    void* objcRenderer; // RendererObjC*
};

#endif
