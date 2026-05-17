import Flutter
import UIKit

@_silgen_name("llama_backend_init_mobile")
func dummy_init()

@_silgen_name("llama_model_load_from_file_mobile")
func dummy_load()

@_silgen_name("llama_context_create_mobile")
func dummy_ctx_create()

@_silgen_name("llama_inference_stream_mobile")
func dummy_stream()

@_silgen_name("llama_context_free_mobile")
func dummy_ctx_free()

@_silgen_name("llama_model_free_mobile")
func dummy_model_free()

@_silgen_name("llama_kv_cache_clear_mobile")
func dummy_kv_clear()

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Force the linker to include our FFI symbols and prevent dead-code stripping
    let _ = dummy_init
    let _ = dummy_load
    let _ = dummy_ctx_create
    let _ = dummy_stream
    let _ = dummy_ctx_free
    let _ = dummy_model_free
    let _ = dummy_kv_clear

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
