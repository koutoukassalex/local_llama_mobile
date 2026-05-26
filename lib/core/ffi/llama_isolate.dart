import 'dart:async';
import 'dart:ffi';
import 'dart:io';
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
    int? nCtx,
    this.nGpuLayers = 99, // -1 or 99 maps to all layers to GPU; C++ retries with 0 on OOM
    this.nThreads = 4,
  }) : nCtx = nCtx ?? (Platform.isIOS ? 1024 : 2048);
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

class StopInferenceCommand extends LlamaCommand {}

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

    final errorPort = ReceivePort();
    final exitPort = ReceivePort();

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort.sendPort,
      debugName: 'LlamaInferenceIsolate',
      errorsAreFatal: true,
      onExit: exitPort.sendPort,
      onError: errorPort.sendPort,
    );

    // Listen to exit port
    exitPort.listen((message) {
      _statusController.add(LlamaStatusEvent(
        status: "Fatal Error: Background engine exited unexpectedly or crashed.",
        isReady: false,
      ));
      _isInitialized = false;
    });

    // Listen to error port
    errorPort.listen((message) {
      final error = message as List;
      final errorMsg = error[0] as String;
      _statusController.add(LlamaStatusEvent(
        status: "Fatal Error: Background engine crashed: $errorMsg",
        isReady: false,
      ));
      _isInitialized = false;
    });

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

  /// Interrupts ongoing inference loop in C++
  void stopInference() {
    _toIsolateSendPort?.send(StopInferenceCommand());
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

    LlamaModelPtr modelPtr = nullptr;
    LlamaContextPtr ctxPtr = nullptr;
    NativeLlama? nativeLlama;

    String? initError;
    try {
      // Instantiate native binding within the isolate scope
      nativeLlama = NativeLlama.instance;
      nativeLlama.backendInit();
    } catch (e) {
      initError = e.toString();
      mainSendPort.send(LlamaStatusEvent(
        status: "Fatal Error: Native engine failed to initialize: $initError",
        isReady: false,
      ));
    }

    _currentIsolateSendPort = mainSendPort;

    isolateReceivePort.listen((message) {
      if (nativeLlama == null) {
        if (message is LoadModelCommand) {
          mainSendPort.send(LlamaStatusEvent(
            status: "Error: Cannot load model. Native engine uninitialized: $initError",
            isReady: false,
          ));
        } else if (message is GenerateCommand) {
          mainSendPort.send(LlamaStreamEvent(
            token: "",
            isFinished: true,
            error: "Error: Generation failed. Native engine uninitialized: $initError",
          ));
        }
        return;
      }

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
            
            // Fetch internal error message from C++
            final errorPtr = nativeLlama.getLastError();
            final cppError = errorPtr != nullptr ? errorPtr.toDartString() : "Unknown error";
            
            // Check file size to diagnose truncated downloads
            final file = File(message.modelPath);
            final sizeStr = file.existsSync() ? "${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB" : "File not found";

            mainSendPort.send(LlamaStatusEvent(
              status: "Error: Model load failed for '${message.modelPath.split('/').last}' ($sizeStr).\n"
                      "Engine details: $cppError\n"
                      "If the size is smaller than expected, the download was likely interrupted.",
              isReady: false,
            ));
            return;
          }

          ctxPtr = nativeLlama.contextCreate(modelPtr, params);
          calloc.free(paramsPtr);
          if (ctxPtr == nullptr) {
            final errorPtr = nativeLlama.getLastError();
            final cppError = errorPtr != nullptr ? errorPtr.toDartString() : "Unknown error";
            nativeLlama.modelFree(modelPtr);
            modelPtr = nullptr;
            mainSendPort.send(LlamaStatusEvent(
              status: "Error: Context allocation failed.\nEngine details: $cppError", 
              isReady: false
            ));
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
      
      else if (message is StopInferenceCommand) {
        nativeLlama.interruptInference();
      }
    });
  }
}
