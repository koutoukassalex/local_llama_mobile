Pod::Spec.new do |s|
  s.name             = 'LlamaCppEngine'
  s.version          = '1.0.0'
  s.summary          = 'Local llama.cpp inference engine for iOS with Metal GPU acceleration.'
  s.description      = 'Builds llama.cpp via CMake and compiles the FFI wrapper for on-device AI inference.'
  s.homepage         = 'https://github.com/koutoukassalex/local_llama_mobile'
  s.license          = { :type => 'MIT' }
  s.author           = { 'koutoukassalex' => 'koutoukassalex@github.com' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '13.0'
  s.static_framework = true

  cpp_root   = 'android/app/src/main/cpp'
  llama_root = "#{cpp_root}/llama_cpp"

  # -----------------------------------------------------------------------
  # Build llama.cpp + ggml as a combined static library using CMake.
  # This runs once during `pod install` and produces prebuilt/ios/libllama_ios.a
  # -----------------------------------------------------------------------
  s.prepare_command = <<-CMD
    set -e
    echo "=== [LlamaCppEngine] Starting CMake build of llama.cpp for iOS ==="
    echo "Working directory: $(pwd)"
    echo "Checking submodule..."
    ls -la #{llama_root}/CMakeLists.txt || { echo "ERROR: llama_cpp submodule is empty!"; exit 1; }

    echo "=== Running CMake configure ==="
    cmake -B build-ios \
      -S #{llama_root} \
      -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLAMA_BUILD_TESTS=OFF \
      -DLLAMA_BUILD_EXAMPLES=OFF \
      -DLLAMA_BUILD_SERVER=OFF \
      -DLLAMA_CURL=OFF \
      -DGGML_METAL=ON \
      -DGGML_METAL_EMBED_LIBRARY=ON

    echo "=== Running CMake build ==="
    cmake --build build-ios --config Release -j$(sysctl -n hw.logicalcpu)

    echo "=== Combining all static libraries ==="
    mkdir -p prebuilt/ios
    LIBS=$(find build-ios -name "*.a" | grep -v "libgtest" | grep -v "libgmock" | tr '\n' ' ')
    echo "Libraries found: $LIBS"
    libtool -static -o prebuilt/ios/libllama_ios.a $LIBS

    echo "=== Done! Combined library: ==="
    ls -lh prebuilt/ios/libllama_ios.a
  CMD

  # ---- Only compile our thin FFI wrapper; llama.cpp is pre-built above ----
  s.source_files = [
    "#{cpp_root}/llama_wrapper.cpp",
    "#{cpp_root}/llama_wrapper.h",
  ]

  # ---- Pre-built llama.cpp + ggml static library ----
  s.vendored_libraries = 'prebuilt/ios/libllama_ios.a'

  # ---- Metal shader bundle (embedded into the library via GGML_METAL_EMBED_LIBRARY=ON) ----
  # No separate .metal file needed when GGML_METAL_EMBED_LIBRARY=ON

  # ---- Header search paths for llama_wrapper.cpp compilation ----
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => [
      "\"$(PODS_TARGET_SRCROOT)/#{cpp_root}\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/include\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/src\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/ggml/include\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/ggml/src\"",
    ].join(' '),
    'GCC_PREPROCESSOR_DEFINITIONS' => 'GGML_USE_METAL=1 NDEBUG=1',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'OTHER_CFLAGS' => '-fno-objc-arc -w',
    'OTHER_CPLUSPLUSFLAGS' => '-fno-objc-arc -w -std=c++17',
  }

  # Force Runner to link our FFI symbols, preventing dead-code stripping
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-Wl,-u,_llama_backend_init_mobile -Wl,-u,_llama_model_load_from_file_mobile -Wl,-u,_llama_context_create_mobile -Wl,-u,_llama_inference_stream_mobile -Wl,-u,_llama_context_free_mobile -Wl,-u,_llama_model_free_mobile -Wl,-u,_llama_kv_cache_clear_mobile'
  }

  # ---- System frameworks needed for Metal ----
  s.frameworks = 'Metal', 'MetalKit', 'Accelerate', 'Foundation', 'MetalPerformanceShaders'
  s.libraries  = 'c++'
end
