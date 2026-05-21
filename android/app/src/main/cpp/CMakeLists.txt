cmake_minimum_required(VERSION 3.18.1)

project(llama_wrapper_project LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Configure official llama.cpp build options before importing
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Disable official examples compiling to save build time" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Disable test suite compiling" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Disable local web server daemon compiling" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "Enable Vulkan GPU acceleration" FORCE)

# Define llama.cpp path
set(LLAMA_DIR "${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp")

# Import the official CMake build configs of the submodule
add_subdirectory(${LLAMA_DIR})

# Find dynamic Android libraries from NDK
find_library(LOG_LIB log)
find_library(ANDROID_LIB android)

# Include paths for headers
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${LLAMA_DIR}/include
    ${LLAMA_DIR}/ggml/include
)

# Compile our FFI C++ wrapper into a single self-contained shared library
add_library(llama_wrapper SHARED
    llama_wrapper.cpp
)

# Statically bake llama and ggml targets directly into libllama_wrapper.so
target_link_libraries(llama_wrapper
    llama
    ggml
    ${LOG_LIB}
    ${ANDROID_LIB}
)

# Export only FFI designated symbols (hidden compiler strategy)
set_target_properties(llama_wrapper PROPERTIES
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)
