import 'gguf_model.dart';

enum DeviceRamTier {
  budget,    // < 4 GB RAM (Fits models < 1.0 GB)
  balanced,  // 4 - 6 GB RAM (Fits models < 2.5 GB)
  flagship,  // 8+ GB RAM (Fits models up to 7+ GB)
}

enum CompatibilityLevel {
  flawless,   // Runs at top speed with minimal memory
  good,       // Runs smoothly with adequate memory
  demanding,  // Runs, but requires clearing other apps
  unsupported // Likely to exceed phone RAM and cause OOM
}

class GgufCatalogItem {
  final String id;
  final String name;
  final String description;
  final String quant;
  final String url;
  final String filename;
  final double sizeGB;
  final ModelFamily family;
  final DeviceRamTier minRamTier;
  final bool isVision;
  final bool isReasoning;
  final bool isUncensored;
  final bool isUltraFast;
  final int defaultCtx;

  const GgufCatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quant,
    required this.url,
    required this.filename,
    required this.sizeGB,
    required this.family,
    required this.minRamTier,
    this.isVision = false,
    this.isReasoning = false,
    this.isUncensored = false,
    this.isUltraFast = false,
    this.defaultCtx = 2048,
  });

  /// Evaluates compatibility based on the user's phone tier
  CompatibilityLevel evaluateFor(DeviceRamTier phoneTier) {
    switch (phoneTier) {
      case DeviceRamTier.budget:
        if (sizeGB <= 0.6) return CompatibilityLevel.flawless;
        if (sizeGB <= 1.0) return CompatibilityLevel.good;
        if (sizeGB <= 1.6) return CompatibilityLevel.demanding;
        return CompatibilityLevel.unsupported;

      case DeviceRamTier.balanced:
        if (sizeGB <= 1.2) return CompatibilityLevel.flawless;
        if (sizeGB <= 2.5) return CompatibilityLevel.good;
        if (sizeGB <= 3.8) return CompatibilityLevel.demanding;
        return CompatibilityLevel.unsupported;

      case DeviceRamTier.flagship:
        if (sizeGB <= 2.5) return CompatibilityLevel.flawless;
        if (sizeGB <= 5.2) return CompatibilityLevel.good;
        return CompatibilityLevel.demanding;
    }
  }

  bool isCompatibleWith(DeviceRamTier phoneTier) {
    final level = evaluateFor(phoneTier);
    return level == CompatibilityLevel.flawless || level == CompatibilityLevel.good;
  }
}

/// Official, curated high-speed GGUF library for locallAI
const List<GgufCatalogItem> kGgufCatalog = [
  // --- TIER 0: ULTRA-FAST & BUDGET (<1 GB) ---
  GgufCatalogItem(
    id: "smollm2_360m",
    name: "SmolLM2 360M Instruct",
    description: "Ultra-compact lightning fast model. Answers in milliseconds with low battery usage.",
    quant: "Q4_K_M (~230 MB)",
    url: "https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct-q4_k_m.gguf",
    filename: "smollm2-360m-instruct-q4_k_m.gguf",
    sizeGB: 0.23,
    family: ModelFamily.smollm,
    minRamTier: DeviceRamTier.budget,
    isUltraFast: true,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "qwen25_05b",
    name: "Qwen 2.5 0.5B Instruct",
    description: "Alibaba's ultra-mini instruct model. Superior multilingual chat and basic coding.",
    quant: "Q4_K_M (~398 MB)",
    url: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
    filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
    sizeGB: 0.39,
    family: ModelFamily.qwen,
    minRamTier: DeviceRamTier.budget,
    isUltraFast: true,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "qwen25_05b_uncensored",
    name: "Qwen 2.5 0.5B Abliterated",
    description: "Pocket-sized uncensored model without artificial safety guardrails.",
    quant: "Q4_K_M (~398 MB)",
    url: "https://huggingface.co/mradermacher/Qwen2.5-0.5B-Instruct-abliterated-v3-GGUF/resolve/main/Qwen2.5-0.5B-Instruct-abliterated-v3.Q4_K_M.gguf",
    filename: "Qwen2.5-0.5B-Instruct-abliterated-v3.Q4_K_M.gguf",
    sizeGB: 0.39,
    family: ModelFamily.qwen,
    minRamTier: DeviceRamTier.budget,
    isUncensored: true,
    isUltraFast: true,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "llama32_1b",
    name: "Llama 3.2 1B Instruct",
    description: "Meta's flagship compact model. Highly capable dialogue, summarization and roleplay.",
    quant: "Q4_K_M (~810 MB)",
    url: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
    filename: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
    sizeGB: 0.81,
    family: ModelFamily.llama,
    minRamTier: DeviceRamTier.budget,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "llama32_1b_uncensored",
    name: "Llama 3.2 1B Abliterated",
    description: "Uncensored Llama 3.2 1B. Direct responses to any sensitive or unrestricted prompt.",
    quant: "Q4_K_M (~810 MB)",
    url: "https://huggingface.co/tensorblock/Llama-3.2-1B-Instruct-abliterated-GGUF/resolve/main/Llama-3.2-1B-Instruct-abliterated-Q4_K_M.gguf",
    filename: "Llama-3.2-1B-Instruct-abliterated-Q4_K_M.gguf",
    sizeGB: 0.81,
    family: ModelFamily.llama,
    minRamTier: DeviceRamTier.budget,
    isUncensored: true,
    defaultCtx: 2048,
  ),

  // --- TIER 1: BALANCED CAPABILITY (1.0 - 2.5 GB) ---
  GgufCatalogItem(
    id: "deepseek_r1_15b",
    name: "DeepSeek R1 Distill 1.5B",
    description: "World-class Chain-of-Thought reasoning. Shows step-by-step thinking for math and logic.",
    quant: "Q4_K_M (~1.1 GB)",
    url: "https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
    filename: "DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
    sizeGB: 1.12,
    family: ModelFamily.deepseek,
    minRamTier: DeviceRamTier.balanced,
    isReasoning: true,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "qwen25_15b",
    name: "Qwen 2.5 1.5B Instruct",
    description: "Highest benchmark scores in the 1.5B class. Excels in coding, syntax, and structured data.",
    quant: "Q4_K_M (~1.1 GB)",
    url: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
    filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
    sizeGB: 1.12,
    family: ModelFamily.qwen,
    minRamTier: DeviceRamTier.balanced,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "qwen25_15b_uncensored",
    name: "Qwen 2.5 1.5B Abliterated",
    description: "Reasoning and coding powerhouse without safety refusals or filter blocks.",
    quant: "Q4_K_M (~1.1 GB)",
    url: "https://huggingface.co/mradermacher/Qwen2.5-1.5B-Instruct-abliterated-i1-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-abliterated.i1-Q4_K_M.gguf",
    filename: "Qwen2.5-1.5B-Instruct-abliterated.i1-Q4_K_M.gguf",
    sizeGB: 1.12,
    family: ModelFamily.qwen,
    minRamTier: DeviceRamTier.balanced,
    isUncensored: true,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "gemma2_2b",
    name: "Gemma 2 2B IT",
    description: "Google's architectural marvel with sliding window attention. Clean, nuanced answers.",
    quant: "Q4_K_M (~1.6 GB)",
    url: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf",
    filename: "gemma-2-2b-it-Q4_K_M.gguf",
    sizeGB: 1.63,
    family: ModelFamily.gemma,
    minRamTier: DeviceRamTier.balanced,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "llama32_3b",
    name: "Llama 3.2 3B Instruct",
    description: "Sweet spot for mobile devices. Exceptional reasoning and creative writing fidelity.",
    quant: "Q4_K_M (~2.0 GB)",
    url: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf",
    filename: "Llama-3.2-3B-Instruct-Q4_K_M.gguf",
    sizeGB: 2.02,
    family: ModelFamily.llama,
    minRamTier: DeviceRamTier.balanced,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "phi35_mini",
    name: "Phi-3.5 Mini 3.8B Instruct",
    description: "Microsoft's state-of-the-art small language model. Outperforms many larger 7B models.",
    quant: "Q3_K_M (~2.1 GB)",
    url: "https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q3_K_M.gguf",
    filename: "Phi-3.5-mini-instruct-Q3_K_M.gguf",
    sizeGB: 2.15,
    family: ModelFamily.phi,
    minRamTier: DeviceRamTier.balanced,
    defaultCtx: 2048,
  ),

  // --- TIER 2: FLAGSHIP POWER (2.5+ GB) ---
  GgufCatalogItem(
    id: "deepseek_r1_8b",
    name: "DeepSeek R1 Distill 8B",
    description: "Maximum reasoning performance for 8GB+ phones. Deep analytical thought and STEM problem solving.",
    quant: "Q4_K_M (~4.9 GB)",
    url: "https://huggingface.co/bartowski/DeepSeek-R1-Distill-Llama-8B-GGUF/resolve/main/DeepSeek-R1-Distill-Llama-8B-Q4_K_M.gguf",
    filename: "DeepSeek-R1-Distill-Llama-8B-Q4_K_M.gguf",
    sizeGB: 4.92,
    family: ModelFamily.deepseek,
    minRamTier: DeviceRamTier.flagship,
    isReasoning: true,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "llama31_8b",
    name: "Llama 3.1 8B Instruct",
    description: "Full-scale flagship intelligence on mobile. Gold-standard knowledge base.",
    quant: "Q4_K_M (~4.9 GB)",
    url: "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
    filename: "Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
    sizeGB: 4.92,
    family: ModelFamily.llama,
    minRamTier: DeviceRamTier.flagship,
    defaultCtx: 2048,
  ),
  GgufCatalogItem(
    id: "llama32_11b_vision",
    name: "Llama 3.2 11B Vision Instruct",
    description: "Multimodal visual reasoning. Analyze images, diagrams, receipts, and photos on-device.",
    quant: "Q4_K_M (~6.6 GB)",
    url: "https://huggingface.co/bartowski/Llama-3.2-11B-Vision-Instruct-GGUF/resolve/main/Llama-3.2-11B-Vision-Instruct-Q4_K_M.gguf",
    filename: "Llama-3.2-11B-Vision-Instruct-Q4_K_M.gguf",
    sizeGB: 6.62,
    family: ModelFamily.llama,
    minRamTier: DeviceRamTier.flagship,
    isVision: true,
    defaultCtx: 1024,
  ),
];
