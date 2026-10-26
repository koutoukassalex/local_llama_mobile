# locallAI (local_llama_mobile) — Developer Handoff & Architecture Guide

Welcome to **locallAI**! This document provides a complete technical handover of the project: what it is, how it works, how the native C++ engine and Dart layer interact, what was recently fixed, and what is next on the roadmap so any developer can immediately step in and continue development.

---

## 📱 1. Project Overview

**locallAI** is a production-grade, offline-first mobile AI chatbot built with **Flutter** (iOS & Android). It enables mobile users to run large language models (LLMs) and multimodal vision models locally on their phones without requiring internet access, subscriptions, or external cloud APIs.

### Core Capabilities:
- **On-Device Inference:** Direct C/C++ FFI bindings to `llama.cpp` with ARM NEON (Android) and Apple Metal GPU (iOS) hardware acceleration.
- **Model Vault & Downloader:** Built-in streaming downloader for curated GGUF models from Hugging Face, plus custom `.gguf` file import.
- **Curated Model Catalog:** Recommends models based on detected phone hardware (RAM tiers: Budget `<4GB`, Balanced `4-6GB`, Flagship `8GB+`).
- **Live Internet Access (Optional RAG):** Hybrid web search feature using live DuckDuckGo and Wikipedia APIs to augment the local model with real-time web facts.
- **Multi-Thread Chats & Persistence:** Multi-session chat system with auto-summarized thread titles and instant JSON disk persistence.
- **12 Curated Aesthetic Themes:** Custom dynamic full-bleed gradient skins, responsive frosted glass UI, and simulated Text-to-Speech (TTS) audio visualizer.
- **Security & Privacy:** Offline-first with optional passcode lock and emergency killswitch.

---

## 🏗️ 2. Architectural Structure

The codebase is organized into a clean layer separation:

```
lib/
├── main.dart                          # Root app, theme management, chat UI, model drawer
├── core/
│   ├── ffi/
│   │   ├── native_llama.dart          # Low-level Dart FFI bindings to native C++ symbols
│   │   └── llama_isolate.dart         # Background Dart Isolate worker managing inference loop
│   ├── models/
│   │   ├── chat_message.dart          # Message model with text, role, timestamp, isWebSearch
│   │   ├── chat_session.dart          # Conversation thread entity with JSON serialization
│   │   ├── gguf_model.dart            # GGUF model metadata (quantization, family, vision flag)
│   │   └── gguf_catalog_item.dart     # Curated model catalog with RAM tier compatibility
│   ├── services/
│   │   ├── chat_service.dart          # High-level engine coordinator, sessions DB, prompt templates
│   │   ├── model_manager.dart         # GGUF files manager, file-picker importer, background downloader
│   │   ├── internet_search_service.dart # Real-time web search (DuckDuckGo + Wikipedia API)
│   │   ├── security_service.dart      # Passcode lock and killswitch state
│   │   └── setup_screen.dart          # Initial hardware audit & benchmark wizard
│   └── ui/
│       ├── gguf_library_screen.dart   # Model Library screen with RAM tier filters and download triggers
│       ├── huggingface_search_screen.dart # Interactive Hugging Face repository explorer
│       └── settings_sheet.dart        # Hyperparameters (Temp, Top P, Top K), Engine parameters, Themes
```

---

## ⚡ 3. Native Engine & FFI Bridge

### How Inference Works:
1. **Separation of Concerns:** The Flutter UI thread must stay responsive at 60–120 FPS. LLM token generation is computationally heavy, so all llama.cpp calls run in a **background Dart Isolate** (`llama_isolate.dart`).
2. **Streaming Tokens:** The isolate streams individual tokens over a `ReceivePort` to the UI isolate. The UI throttles rendering every ~35ms to avoid frame drops on high token/second generation.
3. **C++ Native Libraries:**
   - **Android:** `android/app/src/main/cpp/CMakeLists.txt` builds `libllama_native.so` targeting `arm64-v8a` with OpenMP and ARM NEON flags.
   - **iOS:** Compiled via `LlamaCppEngine.podspec` with Metal GPU acceleration (`GGML_USE_METAL=1`).

---

## 💾 4. Local Storage & Data Schema

All persistent data is stored in the app's sandboxed document directory (`path_provider`):

| File / Folder | Purpose |
|---|---|
| `chat_sessions.json` | Stores all conversation threads, message histories, and active thread ID. |
| `models_database.json` | Registry of all installed, downloaded, and imported GGUF models. |
| `gguf_models/` | Dedicated subdirectory containing raw `.gguf` model binary weights. |
| `security_config.json` | Passcode hashes and onboarding security flags. |
| `setup_completed.txt` | Marker file confirming whether the user completed initial hardware setup. |

---

## 🌐 5. Live Internet Search Feature

The app operates offline by default. When the user taps the **Globe Icon** in the chat bar:
1. `_webSearchEnabled` is toggled ON, displaying a green active badge.
2. When the user submits a message, `InternetSearchService.search(query)` queries:
   - **DuckDuckGo Instant Answer API:** For direct answers, definitions, and abstracts.
   - **Wikipedia Search & REST Summary API:** For encyclopedic articles and extracts.
3. The retrieved facts are prepended to the prompt as structured search findings.
4. The user's bubble displays their clean prompt with a `🌐 Live Web Search` badge, while the local LLM generates its response grounded in the live web data.
5. If offline or timed out (5s), it safely falls back to offline weights without throwing.

---

## 🛠️ 6. Recent Fixes & Improvements

1. **Chat Conversation Persistence:**
   - Previously, conversations were kept only in RAM and wiped on app restart.
   - Implemented `chat_sessions.json` disk persistence in `ChatService` with auto-save and restore.
2. **Fixed "Browse Models" Screen Crash (Gray Screen):**
   - Provided `ModelManager` alongside `ChatService` in root `MultiProvider` (`main.dart`).
   - Wrapped `MaterialApp` with `ThemeProviderBridge` via `builder:` so pushed routes (`GgufLibraryScreen`) inherit themes safely without null check exceptions.
3. **Real Internet Search Integration:**
   - Replaced old placeholder mock tag with real `InternetSearchService` using DuckDuckGo and Wikipedia APIs.
   - Added interactive globe toggle button, live search spinner, and search pills.

---

## 🚀 7. How to Build & Run

### Prerequisites:
- **Flutter SDK:** `>= 3.0.0 < 4.0.0`
- **Android:** Android Studio with NDK `25.x`+ and CMake `3.22.1`+
- **iOS:** macOS with Xcode 15+ and CocoaPods

### Commands:
```powershell
# 1. Fetch dependencies
flutter pub get

# 2. Synchronize native C++ git submodules
git submodule sync --recursive
git submodule update --init --recursive --depth=1

# 3. Run on connected device in Release mode (required for native LLM performance)
flutter run --release
```

### GitHub Actions CI:
The repository includes `.github/workflows/build_pipeline.yml` which automatically:
- Builds unsigned Android Release APKs (`build/app/outputs/flutter-apk/app-release.apk`).
- Builds and packages unsigned iOS `.ipa` archives on `macos-latest`.

---

## 🗺️ 8. Roadmap & Next Steps for the Next Developer

If you are continuing work on this project, here are the highest-value features to implement next:

1. **Multimodal Vision Integration:**
   - `GgufModel.isVision` and image attachment UI (`_selectedImagePath`) are in place.
   - Next step: Bind `llava-cli` / `clip_model` in `native_llama.dart` to feed images alongside prompts.
2. **Local Document RAG (PDF / Text Ingestion):**
   - Allow users to import PDF, TXT, or Markdown documents into `Model Vault` and query them locally using small quantized embedding models (e.g., `bge-micro-v2.gguf`).
3. **Voice Input (STT):**
   - Bind `whisper.cpp` or use native device speech recognition to enable voice-to-text chat.
4. **Dynamic Context Size Slider:**
   - Hyperparameter sliders exist in `SettingsSheet`; connect KV-cache quantization (`Q8_0` or `Q4_0`) to optimize RAM usage on budget devices.
