#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

// Handle definitions for opaque C++ structures
typedef void* llama_model_ptr;
typedef void* llama_context_ptr;

// Generation parameters
typedef struct {
    int32_t n_predict;      // Max tokens to predict
    int32_t n_ctx;          // Context size (e.g., 2048)
    int32_t n_batch;        // Batch size (e.g., 512)
    int32_t n_ubatch;       // Physical batch size
    int32_t n_threads;      // CPU threads to allocate
    int32_t n_gpu_layers;   // GPU layers to offload (-1 = all, 0 = CPU only)
    float temp;             // Temperature (e.g., 0.7)
    float top_p;            // Top-p sampling (e.g., 0.9)
    int32_t top_k;          // Top-k sampling (e.g., 40)
    bool use_mmap;          // Memory-map the model file
    bool use_mlock;         // Lock memory to prevent swapping
    bool flash_attn;        // Use Flash Attention
} llama_params_t;

// Callback function signature for streaming tokens back to Dart
typedef void (*token_callback_t)(const char* token, bool is_end);

/**
 * Initialize the llama.cpp backend. Must be called once before any other function.
 */
__attribute__((visibility("default")))
void llama_backend_init_mobile(void);

/**
 * Stop any ongoing inference stream immediately.
 */
__attribute__((visibility("default")))
void llama_interrupt_inference_mobile(void);

/**
 * Get the last detailed error message from the engine.
 * Useful for diagnosing why llama_model_load_from_file returned NULL.
 */
__attribute__((visibility("default")))
const char* llama_get_last_error_mobile(void);

/**
 * Load a GGUF model from the specified absolute file path.
 * Returns a pointer to the loaded model, or NULL on failure.
 */
__attribute__((visibility("default")))
llama_model_ptr llama_model_load_from_file_mobile(const char* model_path, llama_params_t params);

/**
 * Create an execution context for the loaded model.
 * Returns a pointer to the context, or NULL on failure.
 */
__attribute__((visibility("default")))
llama_context_ptr llama_context_create_mobile(llama_model_ptr model, llama_params_t params);

/**
 * Run autoregressive text inference on the given prompt and stream results in real time.
 * This runs synchronously on the calling thread and invokes the callback for each generated token.
 */
__attribute__((visibility("default")))
bool llama_inference_stream_mobile(
    llama_model_ptr model,
    llama_context_ptr ctx,
    const char* prompt,
    llama_params_t params,
    token_callback_t callback
);

/**
 * Free the context memory.
 */
__attribute__((visibility("default")))
void llama_context_free_mobile(llama_context_ptr ctx);

/**
 * Free the model memory.
 */
__attribute__((visibility("default")))
void llama_model_free_mobile(llama_model_ptr model);

/**
 * Clear the KV cache to start a fresh conversation conversation context.
 */
__attribute__((visibility("default")))
void llama_kv_cache_clear_mobile(llama_context_ptr ctx);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_WRAPPER_H
