Pod::Spec.new do |s|
  s.name             = 'LlamaCppEngine'
  s.version          = '1.0.0'
  s.summary          = 'Local llama.cpp inference engine for iOS with Metal GPU acceleration.'
  s.description      = 'Compiles llama.cpp and the FFI wrapper into the Runner binary for on-device AI inference.'
  s.homepage         = 'https://github.com/koutoukassalex/local_llama_mobile'
  s.license          = { :type => 'MIT' }
  s.author           = { 'koutoukassalex' => 'koutoukassalex@github.com' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '13.0'
  s.static_framework = false

  # Relative paths from this podspec location (native/ios/) to the C++ sources
  cpp_root = '../../android/app/src/main/cpp'
  llama_root = "#{cpp_root}/llama.cpp"

  # ---- Source files ----
  # 1. Our FFI wrapper
  s.source_files =
    "#{cpp_root}/llama_wrapper.cpp",
    "#{cpp_root}/llama_wrapper.h",

    # 2. llama.cpp core library sources
    "#{llama_root}/src/*.cpp",
    "#{llama_root}/src/*.h",

    # 3. ggml core sources
    "#{llama_root}/ggml/src/ggml.c",
    "#{llama_root}/ggml/src/ggml.cpp",
    "#{llama_root}/ggml/src/ggml-alloc.c",
    "#{llama_root}/ggml/src/ggml-backend.cpp",
    "#{llama_root}/ggml/src/ggml-backend-reg.cpp",
    "#{llama_root}/ggml/src/ggml-backend-meta.cpp",
    "#{llama_root}/ggml/src/ggml-opt.cpp",
    "#{llama_root}/ggml/src/ggml-quants.c",
    "#{llama_root}/ggml/src/ggml-threading.cpp",
    "#{llama_root}/ggml/src/gguf.cpp",
    "#{llama_root}/ggml/src/ggml-impl.h",
    "#{llama_root}/ggml/src/ggml-backend-impl.h",
    "#{llama_root}/ggml/src/ggml-common.h",

    # 4. ggml CPU backend
    "#{llama_root}/ggml/src/ggml-cpu/ggml-cpu.c",
    "#{llama_root}/ggml/src/ggml-cpu/ggml-cpu.cpp",
    "#{llama_root}/ggml/src/ggml-cpu/ggml-cpu-impl.h",
    "#{llama_root}/ggml/src/ggml-cpu/common.h",
    "#{llama_root}/ggml/src/ggml-cpu/ops.cpp",
    "#{llama_root}/ggml/src/ggml-cpu/ops.h",
    "#{llama_root}/ggml/src/ggml-cpu/binary-ops.cpp",
    "#{llama_root}/ggml/src/ggml-cpu/binary-ops.h",
    "#{llama_root}/ggml/src/ggml-cpu/unary-ops.cpp",
    "#{llama_root}/ggml/src/ggml-cpu/unary-ops.h",
    "#{llama_root}/ggml/src/ggml-cpu/vec.cpp",
    "#{llama_root}/ggml/src/ggml-cpu/vec.h",
    "#{llama_root}/ggml/src/ggml-cpu/traits.cpp",
    "#{llama_root}/ggml/src/ggml-cpu/traits.h",
    "#{llama_root}/ggml/src/ggml-cpu/repack.cpp",
    "#{llama_root}/ggml/src/ggml-cpu/repack.h",
    "#{llama_root}/ggml/src/ggml-cpu/quants.c",
    "#{llama_root}/ggml/src/ggml-cpu/quants.h",
    "#{llama_root}/ggml/src/ggml-cpu/simd-mappings.h",
    "#{llama_root}/ggml/src/ggml-cpu/hbm.cpp",
    "#{llama_root}/ggml/src/ggml-cpu/hbm.h",
    "#{llama_root}/ggml/src/ggml-cpu/arch-fallback.h",

    # 5. ggml Metal GPU backend (iOS GPU acceleration!)
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal.cpp",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-common.cpp",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-common.h",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-context.h",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-context.m",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-device.cpp",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-device.h",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-device.m",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-impl.h",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-ops.cpp",
    "#{llama_root}/ggml/src/ggml-metal/ggml-metal-ops.h"

  # ---- Metal shader file ----
  s.resources = "#{llama_root}/ggml/src/ggml-metal/ggml-metal.metal"

  # ---- Header search paths ----
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => [
      "\"$(PODS_TARGET_SRCROOT)/#{cpp_root}\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/include\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/src\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/ggml/include\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/ggml/src\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/ggml/src/ggml-cpu\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/ggml/src/ggml-metal\"",
      "\"$(PODS_TARGET_SRCROOT)/#{llama_root}/ggml/src/ggml-common.h\"",
    ].join(' '),
    'GCC_PREPROCESSOR_DEFINITIONS' => 'GGML_USE_METAL=1 GGML_METAL_EMBED_LIBRARY=0 NDEBUG=1 ACCELERATE_NEW_LAPACK=1 ACCELERATE_LAPACK_ILP64=1',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'OTHER_CFLAGS' => '-fno-objc-arc -w',
    'OTHER_CPLUSPLUSFLAGS' => '-fno-objc-arc -w -std=c++17',
  }

  # ---- System frameworks ----
  s.frameworks = 'Metal', 'MetalKit', 'Accelerate', 'Foundation', 'MetalPerformanceShaders'

  # ---- Libraries ----
  s.libraries = 'c++'
end
