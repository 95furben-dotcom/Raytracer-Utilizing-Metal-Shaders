#pragma once
#include "../worldstructs.hpp"

bool saveSceneBinary(const char* filepath, const WorldInfo& worldInfo);
bool loadSceneBinary(const char* filepath, WorldInfo& worldInfo);
bool saveSceneText(const char* filepath, const WorldInfo& worldInfo);
bool loadSceneText(const char* filepath, WorldInfo& worldInfo);