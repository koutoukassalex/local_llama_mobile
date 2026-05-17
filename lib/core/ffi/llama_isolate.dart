import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'native_llama.dart';

// Top-level or static global variable within the Background Isolate space.
// Since each Isolate possesses its own distinct memory heap, this is perfectly isolated.
SendPort? _currentIsolateSendPort;

// Native callback that llama.cpp invokes. Must be a top-level or static function.
void _onNativeTokenCallback(Pointer<Utf8> tokenPtr, bool isEnd) {
  if (_currentIsolateSendPort != null) {
    final token = tokenPtr.toDartString();
    _currentIsolateSendPort!.send(LlamaStreamEvent(
      token: token,
      isFinished: isEnd,
    ));
  }
}

/// Commands passed from UI Main Isolate to Background Inference Isolate
abstract class LlamaCommand {}

class LoadModelCommand extends LlamaCommand {
  final String modelPath;
  final int nCtx;
  final int nGpuLayers;
  final int nThreads;

  LoadModelCommand({
    required this.modelPath,
    this.nCtx = 2048,
    this.nGpuLayers = 99, // -1 or 99 maps to all layers to GPU
    this.nThreads = 4,
  });
}

class GenerateCommand extends LlamaCommand {
  final String prompt;
  final double temperature;
  final double topP;
  final int topK;

  GenerateCommand({
    required this.prompt,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
  });
}

class UnloadModelCommand extends LlamaCommand {}

/// Events passed from Background Isolate to UI Main Isolate
class LlamaStreamEvent {
  final String token;
  final bool isFinished;
  final String? error;

  LlamaStreamEvent({
    required this.token,
    required this.isFinished,
    this.error,
  });
}

class LlamaStatusEvent {
  final String status;
  final bool isReady;

  LlamaStatusEvent({
    required this.status,
    required this.isReady,
  });
}

/// Orchestrator of the Background Inference Isolate
class LlamaIsolateManager {
  Isolate? _isolate;
  final ReceivePort _receivePort = ReceivePort();
  SendPort? _toIsolateSendPort;

  // Stream controllers to publish events to the UI
  final _eventController = StreamController<LlamaStreamEvent>.broadcast();
  final _statusController = StreamController<LlamaStatusEvent>.broadcast();

  Stream<LlamaStreamEvent> get tokenStream => _eventController.stream;
  Stream<LlamaStatusEvent> get statusStream => _statusController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Spawns the background isolate and registers communication channels
  Future<void> start() async {
    if (_isolate != null) return;

    _statusController.add(LlamaStatusEvent(status: "Starting native engine isolate...", isReady: false));

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort.sendPort,
      debugName: 'LlamaInferenceIsolate',
    );

    // Listen to messages returning from the isolate
    _receivePort.listen((message) {
      if (message is SendPort) {
        _toIsolateSendPort = message;
        _isInitialized = true;
        _statusController.add(LlamaStatusEvent(status: "Native isolate ready", isReady: false));
      } else if (message is LlamaStreamEvent) {
        _eventController.add(message);
      } else if (message is LlamaStatusEvent) {
        _statusController.add(message);
      }
    });
  }

  /// Sends a load model command to the background thread
  void loadModel(String path, {int nCtx = 2048, int nGpuLayers = 99, int nThreads = 4}) {
    _toIsolateSendPort?.send(LoadModelCommand(
      modelPath: path,
      nCtx: nCtx,
      nGpuLayers: nGpuLayers,
      nThreads: nThreads,
    ));
  }

  /// Initiates generation sequence. UI should listen to tokenStream.
  void generate(String prompt, {double temp = 0.7, double topP = 0.9, int topK = 40}) {
    _toIsolateSendPort?.send(GenerateCommand(
      prompt: prompt,
      temperature: temp,
      topP: topP,
      topK: topK,
    ));
  }

  /// Unloads the model, releasing all allocated RAM instantly
  void unloadModel() {
    _toIsolateSendPort?.send(UnloadModelCommand());
  }

  /// Terminates the background isolate and frees the ports
  void dispose() {
    unloadModel();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _receivePort.close();
    _eventController.close();
    _statusController.close();
  }

  // --- Background Isolate Entry Point ---
  static void _isolateEntryPoint(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    // Instantiate native binding within the isolate scope
    final nativeLlama = NativeLlama.instance;
    nativeLlama.backendInit();

    LlamaModelPtr modelPtr = nullptr;
    LlamaContextPtr ctxPtr = nullptr;

    _currentIsolateSendPort = mainSendPort;

    isolateReceivePort.listen((message) {
      if (message is LoadModelCommand) {
        try {
          mainSendPort.send(LlamaStatusEvent(status: "Loading GGUF model binary...", isReady: false));

          // Free previous model allocations if existing
          if (ctxPtr != nullptr) {
            nativeLlama.contextFree(ctxPtr);
            ctxPtr = nullptr;
          }
          if (modelPtr != nullptr) {
            nativeLlama.modelFree(modelPtr);
            modelPtr = nullptr;
          }

          final paramsPtr = nativeLlama.createDefaultParams();
          final params = paramsPtr.ref;
          params.nCtx = message.nCtx;
          params.nGpuLayers = message.nGpuLayers;
          params.nThreads = message.nThreads;

          final modelPathPtr = message.modelPath.toNativeUtf8();
          modelPtr = nativeLlama.modelLoad(modelPathPtr, params);
          calloc.free(modelPathPtr);

          if (modelPtr == nullptr) {
            calloc.free(paramsPtr);
            mainSendPort.send(LlamaStatusEvent(status: "Error: Model loading failed. RAM exceeded or invalid GGUF format.", isReady: false));
            return;
          }

          ctxPtr = nativeLlama.contextCreate(modelPtr, params);
          calloc.free(paramsPtr);
          if (ctxPtr == nullptr) {
            nativeLlama.modelFree(modelPtr);
            modelPtr = nullptr;
            mainSendPort.send(LlamaStatusEvent(status: "Error: Context allocation failed.", isReady: false));
            return;
          }

          mainSendPort.send(LlamaStatusEvent(status: "Model loaded successfully", isReady: true));
        } catch (e) {
          mainSendPort.send(LlamaStatusEvent(status: "Panic: Model Load Error: $e", isReady: false));
        }
      } 
      
      else if (message is GenerateCommand) {
        if (modelPtr == nullptr || ctxPtr == nullptr) {
          mainSendPort.send(LlamaStreamEvent(
            token: "",
            isFinished: true,
            error: "Error: Generation failed. No model is currently loaded.",
          ));
          return;
        }

        try {
          final paramsPtr = nativeLlama.createDefaultParams();
          final params = paramsPtr.ref;
          params.temp = message.temperature;
          params.topP = message.topP;
          params.topK = message.topK;

          final promptPtr = message.prompt.toNativeUtf8();
          
          // Obtain C++ callback function pointer
          final callbackPointer = Pointer.fromFunction<TokenCallbackNative>(_onNativeTokenCallback);

          // Invoke the streaming loop (synchronous on this background isolate thread, async to UI)
          nativeLlama.inferenceStream(
            modelPtr,
            ctxPtr,
            promptPtr,
            params,
            callbackPointer,
          );

          calloc.free(promptPtr);
          calloc.free(paramsPtr);
        } catch (e) {
          mainSendPort.send(LlamaStreamEvent(
            token: "",
            isFinished: true,
            error: "Inference exception: $e",
          ));
        }
      } 
      
      else if (message is UnloadModelCommand) {
        mainSendPort.send(LlamaStatusEvent(status: "Unloading model...", isReady: false));
        if (ctxPtr != nullptr) {
          nativeLlama.contextFree(ctxPtr);
          ctxPtr = nullptr;
        }
        if (modelPtr != nullptr) {
          nativeLlama.modelFree(modelPtr);
          modelPtr = nullptr;
        }
        mainSendPort.send(LlamaStatusEvent(status: "Model unloaded. Standby mode.", isReady: false));
      }
    });
  }
}
