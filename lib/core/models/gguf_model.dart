enum ModelFamily {
  llama,
  gemma,
  qwen,
  phi,
  tinyLlama,
  unknown
}

class GgufModel {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final ModelFamily family;
  final String quantization;
  final bool isVision;

  GgufModel({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.family,
    required this.quantization,
    this.isVision = false,
  });

  double get sizeInGB => sizeBytes / (1024 * 1024 * 1024);

  static bool detectVision(String filename) {
    final lower = filename.toLowerCase();
    return lower.contains('llava') || 
           lower.contains('vl-') || 
           lower.contains('-vl') || 
           lower.contains('vision') || 
           lower.contains('minicpm-v') || 
           lower.contains('obsidian') ||
           lower.contains('moondream');
  }

  static ModelFamily detectFamily(String filename) {
    final lower = filename.toLowerCase();
    if (lower.contains('llama')) return ModelFamily.llama;
    if (lower.contains('gemma')) return ModelFamily.gemma;
    if (lower.contains('qwen')) return ModelFamily.qwen;
    if (lower.contains('phi')) return ModelFamily.phi;
    if (lower.contains('tiny')) return ModelFamily.tinyLlama;
    return ModelFamily.unknown;
  }

  /// Builds appropriate system context and prompt templates depending on the model's family.
  /// Handles distinct chat templates (e.g. ChatML for Qwen, custom for Gemma/Llama)
  String applyTemplate(List<Map<String, String>> conversationHistory) {
    StringBuffer promptBuffer = StringBuffer();
    
    switch (family) {
      case ModelFamily.qwen:
        // ChatML Template
        for (var msg in conversationHistory) {
          promptBuffer.write("<|im_start|>${msg['role']}\n${msg['content']}<|im_end|>\n");
        }
        promptBuffer.write("<|im_start|>assistant\n");
        break;

      case ModelFamily.llama:
        // Llama 3 Chat Template
        promptBuffer.write("<|begin_of_text|>");
        for (var msg in conversationHistory) {
          promptBuffer.write("<|start_header_id|>${msg['role']}<|end_header_id|>\n\n${msg['content']}<|eot_id|>");
        }
        promptBuffer.write("<|start_header_id|>assistant<|end_header_id|>\n\n");
        break;

      case ModelFamily.gemma:
        // Gemma Chat Template
        for (var msg in conversationHistory) {
          promptBuffer.write("<start_of_turn>${msg['role']}\n${msg['content']}<end_of_turn>\n");
        }
        promptBuffer.write("<start_of_turn>model\n");
        break;

      case ModelFamily.phi:
        // Phi-3 Chat Template
        for (var msg in conversationHistory) {
          final roleStr = msg['role'] == 'user' ? 'user' : 'assistant';
          promptBuffer.write("<|${roleStr}|>\n${msg['content']}<|end|>\n");
        }
        promptBuffer.write("<|assistant|>\n");
        break;

      default:
        // Generic Instruction Template
        for (var msg in conversationHistory) {
          promptBuffer.write("${(msg['role'] ?? 'user').toUpperCase()}: ${msg['content']}\n");
        }
        promptBuffer.write("ASSISTANT: ");
        break;
    }

    return promptBuffer.toString();
  }
}
