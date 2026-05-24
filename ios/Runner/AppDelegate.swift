import Flutter
import UIKit

// Forward declaration for the C++ backend init function (no struct parameters — safe to call from Swift).
// All other FFI symbols (_llama_model_load_from_file_mobile, etc.) are retained by the
// -Wl,-u linker flags in LlamaCppEngine.podspec user_target_xcconfig, which is the correct
// mechanism for preserving C symbols without needing incorrect Swift type-mappings.
@_silgen_name("llama_backend_init_mobile")
func llama_backend_init_mobile_swift()

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Pre-warm the llama.cpp backend on the main thread before the Flutter isolate starts.
    // This is thread-safe (guarded by a static bool inside the C++ function) and
    // avoids a cold-start delay the first time the user loads a model.
    llama_backend_init_mobile_swift()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
