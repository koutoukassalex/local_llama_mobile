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
  s.static_framework = true

  cpp_root = 'android/app/src/main/cpp'
  llama_root = "#{cpp_root}/llama_cpp"

  # ---- Source files ----
  # 1. Our FFI wrapper
  s.source_files = [
    "#{cpp_root}/llama_wrapper.cpp",
    "#{cpp_root}/llama_wrapper.h",

    # 2. llama.cpp core library sources
    "#{llama_root}/src/*.cpp",
    "#{llama_root}/src/*.h",

    # 2b. llama.cpp model implementations
    "#{llama_root}/src/models/*.cpp",
    "#{llama_root}/src/models/*.h",

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

    # 3b. ggml dynamic loading support
    "#{llama_root}/ggml/src/ggml-backend-dl.cpp",
    "#{llama_root}/ggml/src/ggml-backend-dl.h",

    # 4. ggml CPU backend
    "#{llama_root}/ggml/src/ggml-cpu/*.{c,cpp,h}",
    "#{llama_root}/ggml/src/ggml-cpu/llamafile/*.{c,cpp,h}",

    # 5. ggml Metal GPU backend (iOS GPU acceleration!)
    "#{llama_root}/ggml/src/ggml-metal/*.{c,cpp,m,h}"
  ]

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
    'GCC_PREPROCESSOR_DEFINITIONS' => 'LLAMA_BUILD=1 GGML_USE_METAL=1 GGML_METAL_EMBED_LIBRARY=0 NDEBUG=1 ACCELERATE_NEW_LAPACK=1 ACCELERATE_LAPACK_ILP64=1 GGML_VERSION=\"0.12.0\" GGML_COMMIT=\"unknown\"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'OTHER_CFLAGS' => '-fno-objc-arc -w',
    'OTHER_CPLUSPLUSFLAGS' => '-fno-objc-arc -w -std=c++17',
  }

  # Force the application (Runner) to link our FFI symbols, preventing dead-code stripping
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-Wl,-u,_llama_backend_init_mobile -Wl,-u,_llama_model_load_from_file_mobile -Wl,-u,_llama_context_create_mobile -Wl,-u,_llama_inference_stream_mobile -Wl,-u,_llama_context_free_mobile -Wl,-u,_llama_model_free_mobile -Wl,-u,_llama_kv_cache_clear_mobile'
  }

  # ---- System frameworks ----
  s.frameworks = 'Metal', 'MetalKit', 'Accelerate', 'Foundation', 'MetalPerformanceShaders'

  # ---- Libraries ----
  s.libraries = 'c++'
end
