import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Opaque context and model pointers
typedef LlamaModelPtr = Pointer<Void>;
typedef LlamaContextPtr = Pointer<Void>;

// Representing llama_params_t struct in Dart
final class LlamaParams extends Struct {
  @Int32()
  external int nPredict;
  @Int32()
  external int nCtx;
  @Int32()
  external int nBatch;
  @Int32()
  external int nUbatch;
  @Int32()
  external int nThreads;
  @Int32()
  external int nGpuLayers;
  @Float()
  external double temp;
  @Float()
  external double topP;
  @Int32()
  external int topK;
  @Bool()
  external bool useMmap;
  @Bool()
  external bool useMlock;
  @Bool()
  external bool flashAttn;
}

// Low-level C++ Signature for Callback
// typedef void (*token_callback_t)(const char* token, bool is_end);
typedef TokenCallbackNative = Void Function(Pointer<Utf8> token, Bool isEnd);
typedef TokenCallbackDart = void Function(Pointer<Utf8> token, bool isEnd);

// Bindings to dynamic library
class NativeLlama {
  late final DynamicLibrary _lib;

  // Native Functions declarations
  late final void Function() backendInit;
  late final LlamaModelPtr Function(Pointer<Utf8> modelPath, LlamaParams params) modelLoad;
  late final LlamaContextPtr Function(LlamaModelPtr model, LlamaParams params) contextCreate;
  late final int Function(
    LlamaModelPtr model,
    LlamaContextPtr ctx,
    Pointer<Utf8> prompt,
    LlamaParams params,
    Pointer<NativeFunction<TokenCallbackNative>> callback,
  ) inferenceStream;
  late final void Function(LlamaContextPtr ctx) contextFree;
  late final void Function(LlamaModelPtr model) modelFree;
  late final void Function(LlamaContextPtr ctx) kvCacheClear;

  static final NativeLlama instance = NativeLlama._internal();

  NativeLlama._internal() {
    _lib = _loadLibrary();
    _bindSymbols();
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      try {
        return DynamicLibrary.open('libllama_wrapper.so');
      } catch (e) {
        stderr.writeln("Failed to load libllama_wrapper.so from standard path, trying alternative: $e");
        rethrow;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      // In iOS and MacOS, libraries are linked statically or embedded inside the Frameworks bundle.
      // DynamicLibrary.process() opens the main executable process image which contains the symbols.
      return DynamicLibrary.process();
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  void _bindSymbols() {
    backendInit = _lib
        .lookup<NativeFunction<Void Function()>>('llama_backend_init_mobile')
        .asFunction();

    modelLoad = _lib
        .lookup<NativeFunction<LlamaModelPtr Function(Pointer<Utf8>, LlamaParams)>>('llama_model_load_from_file_mobile')
        .asFunction();

    contextCreate = _lib
        .lookup<NativeFunction<LlamaContextPtr Function(LlamaModelPtr, LlamaParams)>>('llama_context_create_mobile')
        .asFunction();

    inferenceStream = _lib
        .lookup<NativeFunction<Int32 Function(
          LlamaModelPtr,
          LlamaContextPtr,
          Pointer<Utf8>,
          LlamaParams,
          Pointer<NativeFunction<TokenCallbackNative>>,
        )>>('llama_inference_stream_mobile')
        .asFunction();

    contextFree = _lib
        .lookup<NativeFunction<Void Function(LlamaContextPtr)>>('llama_context_free_mobile')
        .asFunction();

    modelFree = _lib
        .lookup<NativeFunction<Void Function(LlamaModelPtr)>>('llama_model_free_mobile')
        .asFunction();

    kvCacheClear = _lib
        .lookup<NativeFunction<Void Function(LlamaContextPtr)>>('llama_kv_cache_clear_mobile')
        .asFunction();
  }

  /// Utility to build a default parameters struct.
  /// Caller MUST free the returned pointer using calloc.free when done!
  Pointer<LlamaParams> createDefaultParams() {
    final pointer = calloc<LlamaParams>();
    final struct = pointer.ref;
    struct.nPredict = 512;
    struct.nCtx = 2048;
    struct.nBatch = 512;
    struct.nUbatch = 512;
    struct.nThreads = 4; // Will auto-select hardware concurrency if passed to C++
    struct.nGpuLayers = 99; // -1 or 99 to offload all layers to GPU (Metal/Vulkan)
    struct.temp = 0.7;
    struct.topP = 0.9;
    struct.topK = 40;
    struct.useMmap = true; // High importance: reduces RAM consumption dramatically
    struct.useMlock = false;
    struct.flashAttn = true; // Reduces memory attention quadratic bounds
    return pointer;
  }
}
