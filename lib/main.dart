import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'core/services/chat_service.dart';
import 'core/services/model_manager.dart';
import 'core/models/chat_message.dart';
import 'core/models/gguf_model.dart';
import 'core/services/setup_screen.dart';
import 'core/ui/settings_sheet.dart';
import 'core/ui/huggingface_search_screen.dart';
import 'core/ui/gguf_library_screen.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatService(),
      child: const LocalAIChatbotApp(),
    ),
  );
}

// Curated Premium Aesthetic Theme Profiles with dynamic custom background gradients
class AppThemeProfile {
  final String name;
  final Color scaffoldBg;
  final LinearGradient backgroundGradient;
  final Color cardBg;
  final Color primaryAccent;
  final Color secondaryAccent;
  final LinearGradient bubbleGradient;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  AppThemeProfile({
    required this.name,
    required this.scaffoldBg,
    required this.backgroundGradient,
    required this.cardBg,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.bubbleGradient,
    required this.textPrimary,
    required this.textSecondary,
    this.isDark = true,
  });
}

final List<AppThemeProfile> appThemesList = [
  // 1. Obsidian — Default dark theme using iOS system colors
  //    textSecondary #98989D on #000000 = 5.6:1 ✓
  AppThemeProfile(
    name: "Obsidian",
    scaffoldBg: const Color(0xFF000000),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF0A0A10)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF1C1C1E),
    primaryAccent: const Color(0xFF0A84FF),
    secondaryAccent: const Color(0xFF5E5CE6),
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFF5F5F7),
    textSecondary: const Color(0xFF98989D),
  ),
  // 2. Daylight — Clean light theme
  //    textSecondary #6C6C70 on #FFFFFF = 5.3:1 ✓
  AppThemeProfile(
    name: "Daylight",
    scaffoldBg: const Color(0xFFF2F2F7),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFFF2F2F7), Color(0xFFE5E5EA)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFFFFFFFF),
    primaryAccent: const Color(0xFF007AFF),
    secondaryAccent: const Color(0xFF5856D6),
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFF1D1D1F),
    textSecondary: const Color(0xFF6C6C70),
    isDark: false,
  ),
  // 3. Midnight — Deep dark with teal accent for late-night use
  //    textSecondary #98989D on #050510 = 5.4:1 ✓
  AppThemeProfile(
    name: "Midnight",
    scaffoldBg: const Color(0xFF050510),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF050510), Color(0xFF0A1628)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF12121E),
    primaryAccent: const Color(0xFF64D2FF),
    secondaryAccent: const Color(0xFF30D158),
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF64D2FF), Color(0xFF5E5CE6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFF0F0F5),
    textSecondary: const Color(0xFF98989D),
  ),
  // 4. Warm Ember — Amber-accented dark theme for warm preference
  //    textSecondary #A89880 on #0F0A05 = 5.1:1 ✓
  AppThemeProfile(
    name: "Warm Ember",
    scaffoldBg: const Color(0xFF0F0A05),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0F0A05), Color(0xFF1A1008)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF1C1610),
    primaryAccent: const Color(0xFFFF9F0A),
    secondaryAccent: const Color(0xFFFFD60A),
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFFFF9F0A), Color(0xFFFF6723)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFF5F0E8),
    textSecondary: const Color(0xFFA89880),
  ),
];

class RecommendedModel {
  final String name;
  final String description;
  final String quant;
  final String url;
  final String filename;
  final bool isVision;

  const RecommendedModel({
    required this.name,
    required this.description,
    required this.quant,
    required this.url,
    required this.filename,
    this.isVision = false,
  });
}

const List<RecommendedModel> recommendedModelsList = [
  RecommendedModel(
    name: "Qwen 2.5 0.5B Instruct",
    description: "Standard ultra-mini instruct model.",
    quant: "Q4_K_M (Ultra-Fast & Tiny, ~398MB)",
    url: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
    filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
    isVision: false,
  ),
  RecommendedModel(
    name: "Qwen 2.5 0.5B Instruct Abliterated",
    description: "Tiny & uncensored instruct model (no safety filters).",
    quant: "Q4_K_M (Fast & Uncensored, ~398MB)",
    url: "https://huggingface.co/mradermacher/Qwen2.5-0.5B-Instruct-abliterated-v3-GGUF/resolve/main/Qwen2.5-0.5B-Instruct-abliterated-v3.Q4_K_M.gguf",
    filename: "Qwen2.5-0.5B-Instruct-abliterated-v3.Q4_K_M.gguf",
    isVision: false,
  ),
  RecommendedModel(
    name: "Llama 3.2 1B Instruct",
    description: "Standard small high-dialogue model.",
    quant: "Q4_K_M (Dialogue Specialized, ~810MB)",
    url: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
    filename: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
    isVision: false,
  ),
  RecommendedModel(
    name: "Llama 3.2 1B Instruct Abliterated",
    description: "Small & uncensored high-dialogue model (no safety filters).",
    quant: "Q4_K_M (Dialogue & Uncensored, ~810MB)",
    url: "https://huggingface.co/tensorblock/Llama-3.2-1B-Instruct-abliterated-GGUF/resolve/main/Llama-3.2-1B-Instruct-abliterated-Q4_K_M.gguf",
    filename: "Llama-3.2-1B-Instruct-abliterated-Q4_K_M.gguf",
    isVision: false,
  ),
  RecommendedModel(
    name: "Llama 3.2 11B Vision Instruct",
    description: "Multimodal model that can understand images (Requires high RAM).",
    quant: "Q4_K_M (Vision Capable, ~6.6GB)",
    url: "https://huggingface.co/bartowski/Llama-3.2-11B-Vision-Instruct-GGUF/resolve/main/Llama-3.2-11B-Vision-Instruct-Q4_K_M.gguf",
    filename: "Llama-3.2-11B-Vision-Instruct-Q4_K_M.gguf",
    isVision: true,
  ),
  RecommendedModel(
    name: "Qwen 2.5 1.5B Instruct",
    description: "Smarter model with excellent reasoning capabilities.",
    quant: "Q4_K_M (High Quality Reasoning, ~1.1GB)",
    url: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
    filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
    isVision: false,
  ),
  RecommendedModel(
    name: "Qwen 2.5 1.5B Instruct Abliterated",
    description: "Reasoning model without safety alignments.",
    quant: "Q4_K_M (Smarter & Uncensored, ~1.1GB)",
    url: "https://huggingface.co/mradermacher/Qwen2.5-1.5B-Instruct-abliterated-i1-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-abliterated.i1-Q4_K_M.gguf",
    filename: "Qwen2.5-1.5B-Instruct-abliterated.i1-Q4_K_M.gguf",
    isVision: false,
  ),
];

class LocalAIChatbotApp extends StatefulWidget {
  const LocalAIChatbotApp({super.key});

  @override
  State<LocalAIChatbotApp> createState() => _LocalAIChatbotAppState();
}

class _LocalAIChatbotAppState extends State<LocalAIChatbotApp> {
  int _activeThemeIndex = 0;
  bool _isSetupCompleted = false;
  bool _isCheckingSetup = true;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(appDocDir.path, 'setup_completed.txt'));
      if (await file.exists()) {
        setState(() {
          _isSetupCompleted = true;
        });
      }
    } catch (e) {
      // Ignore
    } finally {
      setState(() {
        _isCheckingSetup = false;
      });
    }
  }

  Future<void> _completeSetup() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(appDocDir.path, 'setup_completed.txt'));
      await file.writeAsString('completed');
      setState(() {
        _isSetupCompleted = true;
      });
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = appThemesList[_activeThemeIndex];
    
    Widget homeWidget;
    if (_isCheckingSetup) {
      homeWidget = Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: activeTheme.backgroundGradient),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    } else if (!_isSetupCompleted) {
      homeWidget = SetupScreen(onComplete: _completeSetup);
    } else {
      homeWidget = const ChatScreen();
    }

    return MaterialApp(
      title: 'locallAI',
      debugShowCheckedModeBanner: false,
      themeMode: activeTheme.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: activeTheme.scaffoldBg,
        colorScheme: ColorScheme.light(
          primary: activeTheme.primaryAccent,
          secondary: activeTheme.secondaryAccent,
          surface: activeTheme.cardBg,
          background: activeTheme.scaffoldBg,
          onSurface: activeTheme.textPrimary,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: activeTheme.scaffoldBg,
        colorScheme: ColorScheme.dark(
          primary: activeTheme.primaryAccent,
          secondary: activeTheme.secondaryAccent,
          surface: activeTheme.cardBg,
          background: activeTheme.scaffoldBg,
          onSurface: activeTheme.textPrimary,
        ),
      ),
      home: ThemeProviderBridge(
        activeTheme: activeTheme,
        activeThemeIndex: _activeThemeIndex,
        onThemeChanged: (idx) {
          setState(() {
            _activeThemeIndex = idx;
          });
        },
        child: homeWidget,
      ),
    );
  }
}

// Provide active theme parameters down to sub-widgets
class ThemeProviderBridge extends InheritedWidget {
  final AppThemeProfile activeTheme;
  final int activeThemeIndex;
  final Function(int) onThemeChanged;

  const ThemeProviderBridge({
    super.key,
    required this.activeTheme,
    required this.activeThemeIndex,
    required this.onThemeChanged,
    required super.child,
  });

  static ThemeProviderBridge of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProviderBridge>()!;
  }

  @override
  bool updateShouldNotify(ThemeProviderBridge oldWidget) {
    return oldWidget.activeThemeIndex != activeThemeIndex;
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  double _importProgress = 0.0;
  bool _isImporting = false;

  // Direct downloading state variables
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  String _downloadingModelName = "";
  
  // Interactive feature states
  bool _webSearchEnabled = false;
  String? _selectedImagePath;

  // Simulated Text-To-Speech (TTS) Engine States
  String? _currentlySpeakingMsgId;
  Timer? _ttsPlaybackTimer;
  double _ttsPulseScale = 1.0;
  late AnimationController _ttsWaveController;

  @override
  void initState() {
    super.initState();
    _ttsWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        setState(() {
          _ttsPulseScale = 1.0 + (_ttsWaveController.value * 0.15);
        });
      });
  }

  @override
  void dispose() {
    _ttsPlaybackTimer?.cancel();
    _ttsWaveController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(ChatService chatService) {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    
    // Append internet context mock tags if Web Search is active
    String promptText = text;
    if (_webSearchEnabled) {
      promptText = "[RAG ACTIVE: Searching Offline KB Databases] $text";
    }

    chatService.sendMessage(promptText);
    
    setState(() {
      _selectedImagePath = null; // Clear image attachment placeholder
    });
    
    _scrollToBottom();
  }

  Future<void> _handleImport(BuildContext context) async {
    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
    });

    try {
      final manager = ModelManager();
      final model = await manager.importCustomModel(
        onProgress: (progress) {
          setState(() {
            _importProgress = progress;
          });
        },
      );

      if (mounted && model != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Model '${model.name}' imported successfully!"),
            backgroundColor: Colors.greenAccent[700],
          ),
        );
        setState(() {}); // Redraw
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _handleDownload(BuildContext context, String url, String filename, {bool? isVision}) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadingModelName = filename.replaceAll('.gguf', '').replaceAll('_', ' ');
    });

    try {
      final manager = ModelManager();
      final model = await manager.downloadModel(
        url: url,
        filename: filename,
        isVision: isVision,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Model '${model.name}' downloaded and installed successfully!"),
            backgroundColor: Colors.greenAccent[700],
          ),
        );
        setState(() {}); // Redraw
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download Failed: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _pickAttachmentImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      setState(() {
        _selectedImagePath = result.files.single.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image attached for offline vision processing context."),
          backgroundColor: Color(0xFF06B6D4),
        ),
      );
    }
  }

  // Simulated Text-To-Speech (TTS) Read-Out Engine
  void _toggleTtsPlayback(ChatMessage message) {
    if (_currentlySpeakingMsgId == message.id) {
      _stopTts();
    } else {
      _stopTts();
      setState(() {
        _currentlySpeakingMsgId = message.id;
        _ttsWaveController.repeat(reverse: true);
      });

      // Calculate simulated readout duration based on word count
      final wordCount = message.text.split(" ").length;
      final playDuration = Duration(milliseconds: (wordCount * 300) + 1000);

      _ttsPlaybackTimer = Timer(playDuration, () {
        _stopTts();
      });
    }
  }

  void _stopTts() {
    _ttsPlaybackTimer?.cancel();
    _ttsWaveController.stop();
    setState(() {
      _currentlySpeakingMsgId = null;
      _ttsPulseScale = 1.0;
    });
  }

  // Copy to Clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard!"),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  // Share Prompt
  void _shareMessage(String text) {
    // Under mobile, we fall back to system clipboard notification or standard shares
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Transcript ready to export / share!"),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  // Open Parameter Config Dialog
  // Rename Thread dialog
  void _showRenameDialog(BuildContext context, ChatService chatService, String sessionId, String oldTitle, AppThemeProfile theme) {
    final textController = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardBg,
          title: Text("Rename Conversation Thread", style: TextStyle(fontSize: 16, color: theme.textPrimary)),
          content: TextField(
            controller: textController,
            style: TextStyle(color: theme.textPrimary),
            decoration: InputDecoration(
              hintText: "Enter thread title",
              hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: theme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryAccent),
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  chatService.renameSession(sessionId, textController.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeBridge = ThemeProviderBridge.of(context);
    final theme = themeBridge.activeTheme;
    final chatService = Provider.of<ChatService>(context);

    if (chatService.isGenerating) {
      _scrollToBottom();
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBg.withOpacity(0.92),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.square_rounded, color: theme.primaryAccent, size: 22),
          tooltip: "Model Vault",
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "locallAI",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chatService.isModelLoaded
                        ? const Color(0xFF30D158)
                        : chatService.activeModel != null
                            ? const Color(0xFFFFD60A)
                            : theme.textSecondary.withOpacity(0.5),
                    boxShadow: chatService.isModelLoaded
                        ? [BoxShadow(color: const Color(0xFF30D158).withOpacity(0.5), blurRadius: 4)]
                        : [],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    chatService.activeModel != null
                        ? chatService.activeModel!.name
                        : "No model loaded",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: theme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_stories_rounded, color: theme.textSecondary, size: 22),
            tooltip: "Model Library",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GgufLibraryScreen(
                    onDownloadRequested: (url, filename, isVision) {
                      _handleDownload(context, url, filename, isVision: isVision);
                    },
                    onImportRequested: () => _handleImport(context),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: theme.textSecondary, size: 22),
            tooltip: "Settings",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SettingsSheet(themeBridge: themeBridge),
              );
            },
          ),
        ],
      ),
      drawer: _buildModelDrawer(context, chatService, themeBridge),
      body: Container(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildStatusBar(chatService, theme),
              Expanded(
                child: chatService.messages.isEmpty
                    ? _buildEmptyState(chatService, theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: chatService.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chatService.messages[index];
                          return _buildMessageBubble(msg, theme);
                        },
                      ),
              ),
              _buildInputBar(chatService, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(ChatService chatService, AppThemeProfile theme) {
    final hasError = chatService.status.contains("Error") || chatService.status.contains("Panic");
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFFF453A).withOpacity(0.12)
            : theme.cardBg.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.textSecondary.withOpacity(0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasError
                  ? const Color(0xFFFF453A)
                  : chatService.isModelLoaded
                      ? const Color(0xFF30D158)
                      : const Color(0xFFFFD60A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chatService.status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: hasError ? const Color(0xFFFF453A) : theme.textSecondary,
              ),
              maxLines: hasError ? 3 : 1,
              overflow: hasError ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ChatService chatService, AppThemeProfile theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryAccent.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.primaryAccent.withOpacity(0.12),
                    child: Icon(Icons.psychology_rounded, size: 44, color: theme.primaryAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              "locallAI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Run AI models directly on your device.\nFully private, fully offline.",
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                color: theme.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 36),
            if (chatService.activeModel == null) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_stories_rounded, size: 20),
                  label: const Text("Browse Models", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GgufLibraryScreen(
                          onDownloadRequested: (url, filename, isVision) {
                            _handleDownload(context, url, filename, isVision: isVision);
                          },
                          onImportRequested: () => _handleImport(context),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open_rounded, size: 20),
                  label: const Text("Import Model", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textPrimary,
                    side: BorderSide(color: theme.textSecondary.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
            ] else
              Text(
                "Send a message to begin",
                style: TextStyle(fontSize: 15, color: theme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, AppThemeProfile theme) {
    final isUser = msg.isUser;
    final isSpeaking = _currentlySpeakingMsgId == msg.id;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? theme.bubbleGradient : null,
                color: isUser ? null : theme.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                border: isUser
                    ? null
                    : Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : theme.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  if (isSpeaking)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded, color: theme.primaryAccent, size: 16),
                          const SizedBox(width: 6),
                          AnimatedScale(
                            scale: _ttsPulseScale,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: 60,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1.5),
                                color: theme.primaryAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Speaking",
                            style: TextStyle(fontSize: 13, color: theme.primaryAccent, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Action bar with 44pt touch targets per HIG
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  _buildMsgAction(Icons.copy_rounded, () => _copyToClipboard(msg.text), theme.textSecondary.withOpacity(0.5)),
                  _buildMsgAction(
                    isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                    () => _toggleTtsPlayback(msg),
                    isSpeaking ? theme.primaryAccent : theme.textSecondary.withOpacity(0.5),
                  ),
                  _buildMsgAction(Icons.ios_share_rounded, () => _shareMessage(msg.text), theme.textSecondary.withOpacity(0.5)),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: TextStyle(fontSize: 12, color: theme.textSecondary.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMsgAction(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildInputBar(ChatService chatService, AppThemeProfile theme) {
    final isInteractive = chatService.isModelLoaded && !chatService.isGenerating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBg.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image attachment preview
          if (_selectedImagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.textSecondary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.image_rounded, color: theme.primaryAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.basename(_selectedImagePath!),
                        style: TextStyle(fontSize: 13, color: theme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedImagePath = null),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        child: Icon(Icons.close_rounded, size: 16, color: theme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Accessory buttons
              IconButton(
                icon: Icon(
                  Icons.add_circle_rounded,
                  color: theme.textSecondary,
                  size: 26,
                ),
                tooltip: "Attach",
                onPressed: isInteractive ? _pickAttachmentImage : null,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),

              const SizedBox(width: 4),

              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: theme.textSecondary.withOpacity(0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 5,
                    enabled: isInteractive,
                    style: TextStyle(color: theme.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: chatService.activeModel == null
                          ? "Load a model to begin"
                          : chatService.isGenerating
                              ? "Generating..."
                              : "Message",
                      hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5), fontSize: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send / Stop button — 44pt
              if (chatService.isGenerating)
                GestureDetector(
                  onTap: () => chatService.stopEngineInference(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF453A),
                    ),
                    child: const Icon(Icons.stop_rounded, color: Colors.white, size: 22),
                  ),
                )
              else
                GestureDetector(
                  onTap: isInteractive ? () => _handleSend(chatService) : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isInteractive ? theme.bubbleGradient : null,
                      color: isInteractive ? null : theme.cardBg,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: isInteractive ? Colors.white : theme.textSecondary.withOpacity(0.3),
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelDrawer(BuildContext context, ChatService chatService, ThemeProviderBridge themeBridge) {
    final theme = themeBridge.activeTheme;
    final modelManager = ModelManager();
    final installedModels = modelManager.models;
    final sessions = chatService.sessions;

    return Drawer(
      backgroundColor: theme.scaffoldBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.primaryAccent.withOpacity(0.12),
                          child: Icon(Icons.folder_copy_rounded, size: 22, color: theme.primaryAccent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Model Vault",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: theme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${installedModels.length} models installed",
                          style: TextStyle(fontSize: 13, color: theme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(color: theme.textSecondary.withOpacity(0.1), height: 1),

            if (_isImporting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Importing GGUF...", style: TextStyle(fontSize: 13, color: theme.textPrimary)),
                        Text("${(_importProgress * 100).toStringAsFixed(0)}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryAccent)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _importProgress,
                        backgroundColor: theme.cardBg,
                        color: theme.primaryAccent,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

            if (_isDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Downloading $_downloadingModelName...",
                            style: TextStyle(fontSize: 13, color: theme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "${(_downloadProgress * 100).toStringAsFixed(0)}%",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.secondaryAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor: theme.cardBg,
                        color: theme.secondaryAccent,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

            // Content list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // 1. Thread Session manager
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "CHATS",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: theme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => chatService.createNewSession(),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            child: Icon(Icons.add_circle_rounded, color: theme.primaryAccent, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...sessions.map((s) {
                    final isActive = s.id == chatService.activeSessionId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isActive ? theme.primaryAccent.withOpacity(0.1) : theme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? theme.primaryAccent.withOpacity(0.3) : theme.textSecondary.withOpacity(0.06),
                          width: 0.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        dense: true,
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? theme.primaryAccent : theme.textPrimary,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 15,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _showRenameDialog(context, chatService, s.id, s.title, theme),
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: Icon(Icons.edit_outlined, size: 16, color: theme.textSecondary.withOpacity(0.6)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => chatService.deleteSession(s.id),
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFFF453A)),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          chatService.selectSession(s.id);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // 2. Installed Models Section
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      "INSTALLED MODELS",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: theme.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ),

                  if (installedModels.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 28, color: theme.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 8),
                          Text(
                            "No Models Installed",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Download a model below or import a .gguf file.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: theme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ...installedModels.map((m) {
                      final isActive = chatService.activeModel?.path == m.path;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isActive ? theme.primaryAccent.withOpacity(0.08) : theme.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive ? theme.primaryAccent.withOpacity(0.4) : theme.textSecondary.withOpacity(0.08),
                            width: isActive ? 1.0 : 0.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          dense: true,
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  m.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (m.isVision) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.primaryAccent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.visibility_rounded, size: 11, color: theme.primaryAccent),
                                      const SizedBox(width: 3),
                                      Text("Vision", style: TextStyle(fontSize: 11, color: theme.primaryAccent, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "${m.quantization} • ${m.sizeInGB.toStringAsFixed(2)} GB",
                              style: TextStyle(fontSize: 13, color: theme.textSecondary),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isActive && chatService.isModelLoaded)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 22)
                              else if (isActive && !chatService.isModelLoaded)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryAccent),
                                )
                              else
                                GestureDetector(
                                  onTap: () async {
                                    await modelManager.deleteModel(m);
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFFF453A)),
                                  ),
                                )
                            ],
                          ),
                          onTap: () {
                            if (isActive) {
                              chatService.unloadCurrentModel();
                            } else {
                              chatService.loadModel(m);
                            }
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 20),

                  // Section 3: Recommended Downloads
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      "RECOMMENDED MODELS",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: theme.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ),

                  ...recommendedModelsList.map((model) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: _buildRecommendedModelCard(
                        context,
                        theme,
                        name: model.name,
                        quant: model.quant,
                        url: model.url,
                        filename: model.filename,
                        isVision: model.isVision,
                        installedModels: installedModels,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBg,
                border: Border(
                  top: BorderSide(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_stories_rounded, size: 20),
                      label: const Text("Open Model Library", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GgufLibraryScreen(
                              onDownloadRequested: (url, filename, isVision) {
                                _handleDownload(context, url, filename, isVision: isVision);
                              },
                              onImportRequested: () => _handleImport(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text("Hugging Face", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textPrimary,
                              side: BorderSide(color: theme.textSecondary.withOpacity(0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HuggingFaceSearchScreen(
                                    onDownloadRequested: (url, filename, isVision) {
                                      _handleDownload(context, url, filename, isVision: isVision);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.file_upload_outlined, size: 18),
                            label: const Text("Import File", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textPrimary,
                              side: BorderSide(color: theme.textSecondary.withOpacity(0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isImporting || _isDownloading ? null : () => _handleImport(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedModelCard(
    BuildContext context,
    AppThemeProfile theme, {
    required String name,
    required String quant,
    required String url,
    required String filename,
    required bool isVision,
    required List<GgufModel> installedModels,
  }) {
    final isInstalled = installedModels.any((m) => m.path.endsWith(filename));
    final expectedDownloadingName = filename.replaceAll('.gguf', '').replaceAll('_', ' ');
    final isThisDownloading = _isDownloading && _downloadingModelName == expectedDownloadingName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInstalled ? const Color(0xFF30D158).withOpacity(0.12) : theme.primaryAccent.withOpacity(0.1),
            ),
            child: Icon(
              isInstalled ? Icons.check_circle_rounded : Icons.cloud_download_rounded,
              size: 18,
              color: isInstalled ? const Color(0xFF30D158) : theme.primaryAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVision) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text("Vision", style: TextStyle(fontSize: 10, color: theme.primaryAccent, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  quant,
                  style: TextStyle(fontSize: 13, color: theme.textSecondary),
                ),
              ],
            ),
          ),
          if (isThisDownloading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: _downloadProgress,
                strokeWidth: 2.5,
                color: theme.secondaryAccent,
              ),
            )
          else if (isInstalled)
            const Icon(Icons.check_rounded, color: Color(0xFF30D158), size: 22)
          else
            GestureDetector(
              onTap: _isDownloading || _isImporting
                  ? null
                  : () => _handleDownload(context, url, filename, isVision: isVision),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(Icons.arrow_downward_rounded, color: theme.primaryAccent, size: 20),
              ),
            ),
        ],
      ),
    );
  }

}
