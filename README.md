# locallAI — Offline Local LLM Mobile App

[![Build Pipeline](https://github.com/koutoukassalex/local_llama_mobile/actions/workflows/build_pipeline.yml/badge.svg)](https://github.com/koutoukassalex/local_llama_mobile/actions/workflows/build_pipeline.yml)

**locallAI** is a private, offline-first mobile AI chatbot built with **Flutter** and powered by **`llama.cpp`** via Dart FFI. It enables on-device execution of large language models (LLMs) and vision models on iOS and Android without any cloud dependencies.

---

## 🌟 Highlights
- 🧠 **100% Offline AI:** Runs quantized GGUF models directly on device hardware (ARM NEON on Android, Apple Metal on iOS).
- 💾 **Persistent Multi-Thread Sessions:** Saves all conversation threads and message histories to local storage.
- 🌐 **Live Internet Search:** Optional hybrid web search feature querying DuckDuckGo and Wikipedia APIs in real-time.
- 📦 **Model Vault & Browser:** Curated catalog with RAM tier recommendations (Budget, Balanced, Flagship), direct Hugging Face explorer, and custom `.gguf` file importer.
- 🎨 **12 Aesthetic Themes:** Full-bleed gradient backdrops with sleek dark/light mode designs.
- 🔒 **Privacy First:** Offline-first architecture with optional passcode lock and emergency killswitch.

---

## 📖 Developer Documentation
For comprehensive technical documentation, architecture details, native FFI mechanics, and developer onboarding, see:
👉 **[DEVELOPER_HANDOFF.md](file:///C:/Users/Kouto/.gemini/antigravity-ide/scratch/local_llama_mobile/DEVELOPER_HANDOFF.md)**

---

## 🚀 Quick Start

```powershell
# 1. Clone repository with submodules
git clone --recurse-submodules https://github.com/koutoukassalex/local_llama_mobile.git
cd local_llama_mobile

# 2. Install dependencies
flutter pub get

# 3. Run in release mode for native performance
flutter run --release
```
