# Local AI Chatbot - Developer Notes & Implementation Record

This document is a permanent, high-fidelity archive of the entire pairing session, architectural decisions, and custom code specifications implemented for your offline-first Local Llama Mobile App!

---

## 🎨 Premium Core Features

### 1. 12 Curated Aesthetic Themes
The workspace includes a vibrant, full-bleed gradient backdrop system that dynamically swaps backgrounds and pulsing mesh circles overlay:
* **Midnight Indigo:** Elegant deep indigo to cosmic space purple (Default).
* **Cosmic Aurora:** Electric neon cyan to royal magenta auroras.
* **OLED Cosmic:** Pitch black background with glowing scarlet nebula highlights.
* **Sunset Horizon:** Royal plum fading to a warm sunset orange sky.
* **Forest Jade:** Velvet dark jungle green with neon emerald highlights.
* **Vaporwave Dream:** Cyberpunk magenta, violet, and bright cyan.
* **Ice Glacier:** Deep glacial blue with ice-cyan and frost elements.
* **Royal Amber:** Warm gold to copper amber.
* **Sweet Lavender:** Lilac dark purple with soft lavender-orchid gradients.
* **Electric Crimson:** Pitch black with racing red and hot orange accents.
* **Minimalist Light:** A premium, frosted white-slate light-mode layout.
* **Steel Monochrome:** Professional, muted slate grey and dark steel workspace.

### 2. Enterprise Chat Capabilities
* **Multi-Thread Chat Sessions:** Build independent chat sessions dynamically tracked and updated.
* **Auto-Summarize Thread Titles:** Automatically summarizes user prompts to instantly rename `New Conversation` threads.
* **Inference Variable Tuning Panel:** real-time frosted slider overlay sheets mapping strict vs. creative Temperature, Top P, and Top K values straight to the isolate loop.
* **Simulated Text-To-Speech (TTS):** Speak out replies with real-time scaling and waving custom audio waves!
* **Quick Actions Bar:** Copy transcripts, share files, and toggle search-RAG filters instantly.

---

## 🛠️ Deep Codebase Directory Map

Click any file path to inspect the production source code:
* [main.dart](file:///C:/Users/Kouto/.gemini/antigravity/scratch/local_llama_mobile/lib/main.dart) - Beautiful responsive UI, themes list, sliders, and audio visualizer.
* [chat_service.dart](file:///C:/Users/Kouto/.gemini/antigravity/scratch/local_llama_mobile/lib/core/services/chat_service.dart) - Multi-thread session database, auto-summarizer engine, and FFI wrapper bridge.
* [model_manager.dart](file:///C:/Users/Kouto/.gemini/antigravity/scratch/local_llama_mobile/lib/core/services/model_manager.dart) - Native Dart zero-dependency streaming cloud downloader.
* [native_llama.dart](file:///C:/Users/Kouto/.gemini/antigravity/scratch/local_llama_mobile/lib/core/ffi/native_llama.dart) - Low-level FFI mappings for Android & iOS.
* [llama_isolate.dart](file:///C:/Users/Kouto/.gemini/antigravity/scratch/local_llama_mobile/lib/core/ffi/llama_isolate.dart) - High-performance concurrent isolate thread worker.
* [AndroidManifest.xml](file:///C:/Users/Kouto/.gemini/antigravity/scratch/local_llama_mobile/android/app/src/main/AndroidManifest.xml) - Patched to allow unrestricted release-mode internet and CDN permissions.
* [build_pipeline.yml](file:///C:/Users/Kouto/.gemini/antigravity/scratch/local_llama_mobile/.github/workflows/build_pipeline.yml) - Cloud iOS macOS compile script.

---

## 🚀 Execution & Command Reference

### Local Compilation (Windows Host):
```powershell
# Navigate to the workspace folder
cd "C:\Users\Kouto\.gemini\antigravity\scratch\local_llama_mobile"

# Clear build caches
flutter clean

# Get dependencies
flutter pub get

# Run on your emulator/device in high-performance Release Mode!
flutter run --release
```

### Git & GitHub Actions push sequence:
```powershell
# 1. Add final workflow pipelines
git add .

# 2. Commit files
git commit -m "chore: save developer notes and optimize iOS workflow"

# 3. Push up to GitHub
git push
```
