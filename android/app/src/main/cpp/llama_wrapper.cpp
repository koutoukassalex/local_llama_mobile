#include "llama_wrapper.h"
#include "llama.h"
#include <vector>
#include <string>
#include <iostream>
#include <cstring>
#include <mutex>
#include <thread>
#include <algorithm>

// Thread-safety mutex
static std::mutex g_llama_mutex;

// Custom token to UTF-8 buffer helper to resolve half-character streaming bugs (e.g. emojis)
struct utf8_decoder {
    std::string buffer;
    
    std::string consume(const std::string& raw_piece) {
        buffer += raw_piece;
        size_t len = buffer.length();
        if (len == 0) return "";
        
        size_t valid_len = 0;
        for (size_t i = 0; i < len; ) {
            unsigned char c = buffer[i];
            size_t char_len = 0;
            
            if ((c & 0x80) == 0x00) char_len = 1;      // 0xxxxxxx (ASCII)
            else if ((c & 0xE0) == 0xC0) char_len = 2; // 110xxxxx
            else if ((c & 0xF0) == 0xE0) char_len = 3; // 1110xxxx
            else if ((c & 0xF8) == 0xF0) char_len = 4; // 11110xxx
            else {
                // Invalid start byte, skip
                i++;
                continue;
            }
            
            if (i + char_len <= len) {
                valid_len = i + char_len;
                i += char_len;
            } else {
                // Incomplete multi-byte UTF-8 character, wait for more tokens
                break;
            }
        }
        
        if (valid_len > 0) {
            std::string result = buffer.substr(0, valid_len);
            buffer = buffer.substr(valid_len);
            return result;
        }
        return "";
    }
    
    std::string flush() {
        std::string result = buffer;
        buffer.clear();
        return result;
    }
};

extern "C" {

void llama_backend_init_mobile(void) {
    std::lock_guard<std::mutex> lock(g_llama_mutex);
    static bool initialized = false;
    if (!initialized) {
        // Initialize llama.cpp backend, supporting NUMA and platform specifics
        llama_backend_init();
        initialized = true;
    }
}

llama_model_ptr llama_model_load_from_file_mobile(const char* model_path, llama_params_t params) {
    std::lock_guard<std::mutex> lock(g_llama_mutex);
    if (!model_path) return nullptr;

    llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers = params.n_gpu_layers;
    mparams.use_mmap = params.use_mmap;
    mparams.use_mlock = params.use_mlock;

    llama_model* model = llama_model_load_from_file(model_path, mparams);
    return reinterpret_cast<llama_model_ptr>(model);
}

llama_context_ptr llama_context_create_mobile(llama_model_ptr model_ptr, llama_params_t params) {
    std::lock_guard<std::mutex> lock(g_llama_mutex);
    if (!model_ptr) return nullptr;

    llama_model* model = reinterpret_cast<llama_model*>(model_ptr);
    llama_context_params cparams = llama_context_default_params();
    
    cparams.n_ctx = params.n_ctx;
    cparams.n_batch = params.n_batch;
    cparams.n_ubatch = params.n_ubatch > 0 ? params.n_ubatch : params.n_batch;
    
    // Core CPU threading configuration
    int max_threads = std::thread::hardware_concurrency();
    cparams.n_threads = params.n_threads > 0 ? std::min(params.n_threads, max_threads) : std::max(1, max_threads - 1);
    cparams.n_threads_batch = cparams.n_threads;

    // cparams.flash_attn is deprecated & removed in modern llama_context_params.
    // Modern llama.cpp manages attention structures internally or dynamically.

    llama_context* ctx = llama_init_from_model(model, cparams);
    return reinterpret_cast<llama_context_ptr>(ctx);
}

bool llama_inference_stream_mobile(
    llama_model_ptr model_ptr,
    llama_context_ptr ctx_ptr,
    const char* prompt,
    llama_params_t params,
    token_callback_t callback
) {
    if (!model_ptr || !ctx_ptr || !prompt || !callback) return false;

    llama_model* model = reinterpret_cast<llama_model*>(model_ptr);
    llama_context* ctx = reinterpret_cast<llama_context*>(ctx_ptr);

    // Retrieve vocabulary structure from model for modern API compliance
    const struct llama_vocab* vocab = llama_model_get_vocab(model);
    if (!vocab) return false;

    // 1. Tokenize prompt using the vocab API
    std::vector<llama_token> tokens;
    int n_prompt_tokens = -llama_tokenize(vocab, prompt, strlen(prompt), NULL, 0, true, true);
    tokens.resize(n_prompt_tokens);
    if (llama_tokenize(vocab, prompt, strlen(prompt), tokens.data(), tokens.size(), true, true) < 0) {
        return false;
    }

    // 2. Validate context space
    const int n_ctx = llama_n_ctx(ctx);
    if (tokens.size() >= (size_t)n_ctx) {
        callback("Error: Context size exceeded by the prompt.", true);
        return false;
    }

    // 3. Clear KV cache prior to processing if context size demands it
    llama_kv_cache_clear_mobile(ctx_ptr);

    // 4. Initialize llama_batch
    llama_batch batch = llama_batch_init(params.n_batch, 0, 1);

    // 5. Evaluate the prompt tokens in batches
    size_t processed_tokens = 0;
    while (processed_tokens < tokens.size()) {
        size_t batch_size = std::min((size_t)params.n_batch, tokens.size() - processed_tokens);
        
        batch.n_tokens = batch_size;
        for (size_t i = 0; i < batch_size; ++i) {
            batch.token[i] = tokens[processed_tokens + i];
            batch.pos[i] = processed_tokens + i;
            batch.n_seq_id[i] = 1;
            batch.seq_id[i][0] = 0;
            // Only output logits for the last token in the prompt batch
            batch.logits[i] = (i == batch_size - 1);
        }

        if (llama_decode(ctx, batch) != 0) {
            llama_batch_free(batch);
            return false;
        }
        processed_tokens += batch_size;
    }

    // 6. Modern llama_sampler initialization
    struct llama_sampler* smpl = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(params.top_k));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(params.top_p, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(params.temp));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(42)); // Seeded

    // 7. Auto-regressive generation loop
    int n_curr = tokens.size();
    int n_predict = params.n_predict > 0 ? params.n_predict : (n_ctx - n_curr);
    int n_generated = 0;

    utf8_decoder decoder;

    while (n_generated < n_predict && n_curr < n_ctx) {
        // Sample the next token
        const llama_token id = llama_sampler_sample(smpl, ctx, -1);
        
        // Check for end of stream tokens using modern vocab methods
        if (id == llama_vocab_eos(vocab) || llama_vocab_is_eog(vocab, id)) {
            break;
        }

        // Convert token ID to string piece via 6-argument llama_token_to_piece
        char piece_buf[128];
        int piece_len = llama_token_to_piece(vocab, id, piece_buf, sizeof(piece_buf), 0, true);
        if (piece_len > 0) {
            std::string piece_str(piece_buf, piece_len);
            
            // Consume piece inside the UTF-8 parser to avoid emoji/multi-byte truncation
            std::string complete_chars = decoder.consume(piece_str);
            if (!complete_chars.empty()) {
                callback(complete_chars.c_str(), false);
            }
        }

        // Push new token into the batch for decoding the next step
        batch.n_tokens = 1;
        batch.token[0] = id;
        batch.pos[0] = n_curr;
        batch.n_seq_id[0] = 1;
        batch.seq_id[0][0] = 0;
        batch.logits[0] = true;

        n_curr++;
        n_generated++;

        if (llama_decode(ctx, batch) != 0) {
            break;
        }
    }

    // Flush remaining characters inside the decoder buffer
    std::string last_chars = decoder.flush();
    if (!last_chars.empty()) {
        callback(last_chars.c_str(), false);
    }

    // Indicate completion
    callback("", true);

    // Free resources
    llama_sampler_free(smpl);
    llama_batch_free(batch);

    return true;
}

void llama_context_free_mobile(llama_context_ptr ctx_ptr) {
    std::lock_guard<std::mutex> lock(g_llama_mutex);
    if (ctx_ptr) {
        llama_free(reinterpret_cast<llama_context*>(ctx_ptr));
    }
}

void llama_model_free_mobile(llama_model_ptr model_ptr) {
    std::lock_guard<std::mutex> lock(g_llama_mutex);
    if (model_ptr) {
        llama_model_free(reinterpret_cast<llama_model*>(model_ptr));
    }
}

void llama_kv_cache_clear_mobile(llama_context_ptr ctx_ptr) {
    std::lock_guard<std::mutex> lock(g_llama_mutex);
    if (ctx_ptr) {
        llama_context* ctx = reinterpret_cast<llama_context*>(ctx_ptr);
        llama_memory_clear(llama_get_memory(ctx), true);
    }
}

} // extern "C"
