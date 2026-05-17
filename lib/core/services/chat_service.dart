import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../ffi/llama_isolate.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/gguf_model.dart';
import 'model_manager.dart';

class ChatService extends ChangeNotifier {
  final LlamaIsolateManager _isolateManager = LlamaIsolateManager();
  final ModelManager _modelManager = ModelManager();

  // Multi-thread Chat Sessions
  final List<ChatSession> _sessions = [];
  String? _activeSessionId;

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String? get activeSessionId => _activeSessionId;

  // Dynamically resolve messages belonging to the active thread
  List<ChatMessage> get messages {
    if (_activeSessionId == null || _sessions.isEmpty) return const [];
    final activeSession = _sessions.firstWhere(
      (s) => s.id == _activeSessionId,
      orElse: () => _sessions.first,
    );
    return List.unmodifiable(activeSession.messages);
  }

  // Engine Hyperparameters (Fully customized from settings sliders)
  double _temperature = 0.7;
  double _topP = 0.9;
  int _topK = 40;

  double get temperature => _temperature;
  set temperature(double value) {
    _temperature = value;
    notifyListeners();
  }

  double get topP => _topP;
  set topP(double value) {
    _topP = value;
    notifyListeners();
  }

  int get topK => _topK;
  set topK(int value) {
    _topK = value;
    notifyListeners();
  }

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  String _status = "Initializing system...";
  String get status => _status;

  GgufModel? _activeModel;
  GgufModel? get activeModel => _activeModel;

  StreamSubscription? _tokenSubscription;
  StreamSubscription? _statusSubscription;

  ChatService() {
    _init();
  }

  Future<void> _init() async {
    await _isolateManager.start();
    await _modelManager.init();

    // Create an initial clean session
    createNewSession(title: "First Thread");

    _statusSubscription = _isolateManager.statusStream.listen((event) {
      _status = event.status;
      _isModelLoaded = event.isReady;
      notifyListeners();
    });
  }

  /// Create a fresh new chat conversation session
  void createNewSession({String? title}) {
    final newSession = ChatSession(
      id: const Uuid().v4(),
      title: title ?? "New Conversation",
      messages: [],
      createdAt: DateTime.now(),
    );
    _sessions.insert(0, newSession); // Put newer threads at the top
    _activeSessionId = newSession.id;
    _stopInference(); // Interrupt any generation on previous threads
    notifyListeners();
  }

  /// Switch actively loaded chat thread
  void selectSession(String id) {
    if (_sessions.any((s) => s.id == id)) {
      _activeSessionId = id;
      _stopInference();
      notifyListeners();
    }
  }

  /// Delete a chat session and reclaim RAM/UI state
  void deleteSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    if (_activeSessionId == id) {
      if (_sessions.isNotEmpty) {
        _activeSessionId = _sessions.first.id;
      } else {
        createNewSession(title: "New Conversation");
      }
    }
    notifyListeners();
  }

  /// Rename a chat session dynamically
  void renameSession(String id, String newTitle) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _sessions[idx] = _sessions[idx].copyWith(title: newTitle);
      notifyListeners();
    }
  }

  /// Load a model from GgufModel representation
  Future<void> loadModel(GgufModel model) async {
    _activeModel = model;
    _isolateManager.loadModel(
      model.path,
      nCtx: 2048,
      nGpuLayers: 99, // Automatic full offloading to Vulkan/Metal
    );
    notifyListeners();
  }

  /// Unload active model to conserve system RAM instantly
  void unloadCurrentModel() {
    _isolateManager.unloadModel();
    _activeModel = null;
    _isModelLoaded = false;
    notifyListeners();
  }

  /// Sends the prompt to the background isolate and registers the stream response listener
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating || !_isModelLoaded || _activeModel == null || _activeSessionId == null) return;

    final activeSessionIdx = _sessions.indexWhere((s) => s.id == _activeSessionId);
    if (activeSessionIdx == -1) return;

    // 1. Add User Message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    final currentSession = _sessions[activeSessionIdx];
    final updatedMessages = List<ChatMessage>.from(currentSession.messages)..add(userMessage);

    // Auto-rename session on the first user prompt to make UI beautiful!
    String newTitle = currentSession.title;
    if (currentSession.title == "New Conversation" || currentSession.title == "First Thread") {
      final words = text.split(" ");
      newTitle = words.take(4).join(" ");
      if (text.length > newTitle.length) newTitle += "...";
    }

    _sessions[activeSessionIdx] = currentSession.copyWith(
      messages: updatedMessages,
      title: newTitle,
    );
    _isGenerating = true;
    notifyListeners();

    // 2. Format Context using GGUF Model Specific Template
    final systemPrompt = "You are a helpful, respectful, and fully offline AI mobile assistant. Respond accurately and concisely.";
    final List<Map<String, String>> history = [
      {'role': 'system', 'content': systemPrompt}
    ];

    // Collect last 6 messages to stay within context windows and minimize prompt processing cost
    final recentMessages = updatedMessages.length > 6 ? updatedMessages.sublist(updatedMessages.length - 6) : updatedMessages;
    for (var msg in recentMessages) {
      history.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    final formattedPrompt = _activeModel!.applyTemplate(history);

    // 3. Prepare AI Message Placeholder
    final aiMessageId = const Uuid().v4();
    var aiMessage = ChatMessage(
      id: aiMessageId,
      text: "",
      isUser: false,
      timestamp: DateTime.now(),
    );

    final messagesWithAi = List<ChatMessage>.from(_sessions[activeSessionIdx].messages)..add(aiMessage);
    _sessions[activeSessionIdx] = _sessions[activeSessionIdx].copyWith(messages: messagesWithAi);
    notifyListeners();

    // Cancel any previous subscriptions just in case
    await _tokenSubscription?.cancel();

    // 4. Stream response using customized parameters from sliders
    StringBuffer aiBuffer = StringBuffer();
    
    _isolateManager.generate(
      formattedPrompt,
      temp: _temperature,
      topP: _topP,
      topK: _topK,
    );

    _tokenSubscription = _isolateManager.tokenStream.listen((event) {
      if (event.error != null) {
        _isGenerating = false;
        aiMessage = aiMessage.copyWith(text: "Inference Error: ${event.error}");
        _updateMessage(aiMessage);
        return;
      }

      if (event.isFinished) {
        _isGenerating = false;
        _tokenSubscription?.cancel();
        _tokenSubscription = null;
        notifyListeners();
        return;
      }

      // Append token piece
      aiBuffer.write(event.token);
      aiMessage = aiMessage.copyWith(text: aiBuffer.toString());
      _updateMessage(aiMessage);
    });
  }

  void _updateMessage(ChatMessage updatedMsg) {
    if (_activeSessionId == null) return;
    final activeSessionIdx = _sessions.indexWhere((s) => s.id == _activeSessionId);
    if (activeSessionIdx == -1) return;

    final session = _sessions[activeSessionIdx];
    final msgList = List<ChatMessage>.from(session.messages);
    final idx = msgList.indexWhere((m) => m.id == updatedMsg.id);
    if (idx != -1) {
      msgList[idx] = updatedMsg;
      _sessions[activeSessionIdx] = session.copyWith(messages: msgList);
      notifyListeners();
    }
  }

  void _stopInference() {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _isGenerating = false;
  }

  void clearConversation() {
    if (_activeSessionId == null) return;
    final activeSessionIdx = _sessions.indexWhere((s) => s.id == _activeSessionId);
    if (activeSessionIdx != -1) {
      _sessions[activeSessionIdx] = _sessions[activeSessionIdx].copyWith(messages: []);
      _stopInference();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _statusSubscription?.cancel();
    _isolateManager.dispose();
    super.dispose();
  }
}
