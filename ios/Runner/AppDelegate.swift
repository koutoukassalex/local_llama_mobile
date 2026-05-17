import Flutter
import UIKit

@_silgen_name("llama_backend_init_mobile")
func llama_backend_init_mobile()

@_silgen_name("llama_model_load_from_file_mobile")
func llama_model_load_from_file_mobile(_ path: UnsafePointer<CChar>?, _ params: Any) -> UnsafeMutableRawPointer?

@_silgen_name("llama_context_create_mobile")
func llama_context_create_mobile(_ model: UnsafeMutableRawPointer?, _ params: Any) -> UnsafeMutableRawPointer?

@_silgen_name("llama_inference_stream_mobile")
func llama_inference_stream_mobile(_ model: UnsafeMutableRawPointer?, _ ctx: UnsafeMutableRawPointer?, _ prompt: UnsafePointer<CChar>?, _ params: Any, _ callback: UnsafeMutableRawPointer?) -> Int32

@_silgen_name("llama_context_free_mobile")
func llama_context_free_mobile(_ ctx: UnsafeMutableRawPointer?)

@_silgen_name("llama_model_free_mobile")
func llama_model_free_mobile(_ model: UnsafeMutableRawPointer?)

@_silgen_name("llama_kv_cache_clear_mobile")
func llama_kv_cache_clear_mobile(_ ctx: UnsafeMutableRawPointer?)


@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // FORCE the linker to keep and export all FFI symbols by actually calling them with nil
    llama_backend_init_mobile()
    
    // We pass nil for pointers. For structs, we can just pass a dummy Int since Swift doesn't know the C struct size here,
    // but to be perfectly safe, we can just let it crash if it accesses it. Wait, the C++ code checks if pointer is null FIRST before accessing the struct!
    // In llama_wrapper.cpp: `if (!model_path) return nullptr;`
    let _ = llama_model_load_from_file_mobile(nil, 0)
    let _ = llama_context_create_mobile(nil, 0)
    let _ = llama_inference_stream_mobile(nil, nil, nil, 0, nil)
    llama_context_free_mobile(nil)
    llama_model_free_mobile(nil)
    llama_kv_cache_clear_mobile(nil)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
