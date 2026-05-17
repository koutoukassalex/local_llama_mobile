#ifndef LLAMA_METAL_BRIDGE_H
#define LLAMA_METAL_BRIDGE_H

// Include the base C FFI declarations directly.
// In iOS Xcode, we compile llama_wrapper.cpp directly with the Runner app, 
// linking Metal and Foundation frameworks.
#include "../../android/app/src/main/cpp/llama_wrapper.h"

#endif // LLAMA_METAL_BRIDGE_H
