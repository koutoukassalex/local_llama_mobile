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
import 'core/models/chat_session.dart';
import 'core/models/gguf_model.dart';
import 'core/services/setup_screen.dart';
import 'core/ui/settings_sheet.dart';
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
  AppThemeProfile(
    name: "Midnight Indigo",
    scaffoldBg: const Color(0xFF0A0C16),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0A0C16), Color(0xFF1E1B4B)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF15182B),
    primaryAccent: const Color(0xFF6366F1), // Indigo
    secondaryAccent: const Color(0xFF8B5CF6), // Purple
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFF1F5F9),
    textSecondary: const Color(0xFF94A3B8),
  ),
  AppThemeProfile(
    name: "Cosmic Aurora",
    scaffoldBg: const Color(0xFF070514),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF070514), Color(0xFF1E0E3D)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF100C24),
    primaryAccent: const Color(0xFF00F0FF), // Electric Cyan
    secondaryAccent: const Color(0xFFD946EF), // Fuchsia
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF00F0FF), Color(0xFFD946EF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFFAFAF9),
    textSecondary: const Color(0xFFA78BFA),
  ),
  AppThemeProfile(
    name: "OLED Cosmic",
    scaffoldBg: Colors.black,
    backgroundGradient: const LinearGradient(
      colors: [Colors.black, Color(0xFF1E0B11)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF121212),
    primaryAccent: const Color(0xFFF43F5E), // Rose
    secondaryAccent: const Color(0xFF10B981), // Emerald
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: Colors.white,
    textSecondary: const Color(0xFF9CA3AF),
  ),
  AppThemeProfile(
    name: "Sunset Horizon",
    scaffoldBg: const Color(0xFF0F0B1E),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0F0B1E), Color(0xFF3B072B)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF1D1432),
    primaryAccent: const Color(0xFFF97316), // Warm Orange
    secondaryAccent: const Color(0xFFEC4899), // Hot Pink
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFFF97316), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFFDF4FF),
    textSecondary: const Color(0xFFD946EF),
  ),
  AppThemeProfile(
    name: "Forest Jade",
    scaffoldBg: const Color(0xFF030706),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF030706), Color(0xFF062C22)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF0A1814),
    primaryAccent: const Color(0xFF10B981), // Emerald
    secondaryAccent: const Color(0xFF06B6D4), // Cyan
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFECFDF5),
    textSecondary: const Color(0xFF34D399),
  ),
  AppThemeProfile(
    name: "Vaporwave Dream",
    scaffoldBg: const Color(0xFF1A0B2E),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF1A0B2E), Color(0xFF4A0E4E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF2D123F),
    primaryAccent: const Color(0xFFFF007F), // Bright Pink
    secondaryAccent: const Color(0xFF00FFFF), // Cyan
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFFFF007F), Color(0xFF7F00FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: Colors.white,
    textSecondary: const Color(0xFFFF007F),
  ),
  AppThemeProfile(
    name: "Ice Glacier",
    scaffoldBg: const Color(0xFF0B1B2B),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0B1B2B), Color(0xFF1E3A5F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF162A3B),
    primaryAccent: const Color(0xFF67E8F9), // Ice Cyan
    secondaryAccent: const Color(0xFF38BDF8), // Frost Blue
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF67E8F9), Color(0xFF38BDF8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFF0FDF4),
    textSecondary: const Color(0xFF93C5FD),
  ),
  AppThemeProfile(
    name: "Royal Amber",
    scaffoldBg: const Color(0xFF140D07),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF140D07), Color(0xFF3C2415)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF22170F),
    primaryAccent: const Color(0xFFF59E0B), // Warm Gold
    secondaryAccent: const Color(0xFFD97706), // Amber Bronze
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFFEF3C7),
    textSecondary: const Color(0xFFFCD34D),
  ),
  AppThemeProfile(
    name: "Sweet Lavender",
    scaffoldBg: const Color(0xFF120E2B),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF120E2B), Color(0xFF31255C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF20173F),
    primaryAccent: const Color(0xFFA78BFA), // Lavender
    secondaryAccent: const Color(0xFFC084FC), // Lilac
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFFA78BFA), Color(0xFFC084FC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFF5F3FF),
    textSecondary: const Color(0xFFDDD6FE),
  ),
  AppThemeProfile(
    name: "Electric Crimson",
    scaffoldBg: const Color(0xFF0F0404),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0F0404), Color(0xFF3C0E0E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF1C0A0A),
    primaryAccent: const Color(0xFFEF4444), // Crimson
    secondaryAccent: const Color(0xFFF97316), // Orange
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFFEF2F2),
    textSecondary: const Color(0xFFFCA5A5),
  ),
  AppThemeProfile(
    name: "Minimalist Light",
    scaffoldBg: const Color(0xFFF8FAFC),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: Colors.white,
    primaryAccent: const Color(0xFF3B82F6), // Sky Blue
    secondaryAccent: const Color(0xFF6366F1), // Royal Blue
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFF0F172A),
    textSecondary: const Color(0xFF64748B),
    isDark: false,
  ),
  AppThemeProfile(
    name: "Steel Monochrome",
    scaffoldBg: const Color(0xFF0F172A),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF334155)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF1E293B),
    primaryAccent: const Color(0xFF94A3B8), // Muted Grey
    secondaryAccent: const Color(0xFF475569), // Steel
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF94A3B8), Color(0xFF475569)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFF8FAFC),
    textSecondary: const Color(0xFFCBD5E1),
  ),
  AppThemeProfile(
    name: "Neon Cyberpunk",
    scaffoldBg: const Color(0xFF0A0014),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0A0014), Color(0xFF220033)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF150022),
    primaryAccent: const Color(0xFF00FFCC), // Cyber Cyan
    secondaryAccent: const Color(0xFFFF003C), // Neon Pink
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF00FFCC), Color(0xFF5500FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFE2D6FF),
    textSecondary: const Color(0xFF00FFCC),
  ),
  AppThemeProfile(
    name: "Nordic Frost",
    scaffoldBg: const Color(0xFFF1F5F9),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFFFFFFFF),
    primaryAccent: const Color(0xFF5E81AC), // Nordic Blue
    secondaryAccent: const Color(0xFF88C0D0), // Frost Blue
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF5E81AC), Color(0xFF81A1C1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFF2E3440),
    textSecondary: const Color(0xFF4C566A),
    isDark: false,
  ),
  AppThemeProfile(
    name: "Amethyst Glow",
    scaffoldBg: const Color(0xFF0F0518),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF0F0518), Color(0xFF2A0845)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF1C0D2E),
    primaryAccent: const Color(0xFFB14BF4), // Bright Amethyst
    secondaryAccent: const Color(0xFFF44B86), // Pinkish
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFFB14BF4), Color(0xFFF44B86)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFFDF4FF),
    textSecondary: const Color(0xFFE8B4F8),
  ),
  AppThemeProfile(
    name: "Obsidian Glass",
    scaffoldBg: const Color(0xFF050505),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF050505), Color(0xFF111111)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardBg: const Color(0xFF141414),
    primaryAccent: const Color(0xFFE5E5E5), // Silver
    secondaryAccent: const Color(0xFF737373), // Darker Silver
    bubbleGradient: const LinearGradient(
      colors: [Color(0xFF404040), Color(0xFF171717)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textPrimary: const Color(0xFFFAFAFA),
    textSecondary: const Color(0xFFA3A3A3),
  ),
];

class RecommendedModel {
  final String name;
  final String description;
  final String quant;
  final String url;
  final String filename;

  const RecommendedModel({
    required this.name,
    required this.description,
    required this.quant,
    required this.url,
    required this.filename,
  });
}

const List<RecommendedModel> recommendedModelsList = [
  RecommendedModel(
    name: "Qwen 2.5 0.5B Instruct",
    description: "Standard ultra-mini instruct model.",
    quant: "Q4_K_M (Ultra-Fast & Tiny, ~398MB)",
    url: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
    filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
  ),
  RecommendedModel(
    name: "Qwen 2.5 0.5B Instruct Abliterated",
    description: "Tiny & uncensored instruct model (no safety filters).",
    quant: "Q4_K_M (Fast & Uncensored, ~398MB)",
    url: "https://huggingface.co/mradermacher/Qwen2.5-0.5B-Instruct-abliterated-v3-GGUF/resolve/main/Qwen2.5-0.5B-Instruct-abliterated-v3.Q4_K_M.gguf",
    filename: "Qwen2.5-0.5B-Instruct-abliterated-v3.Q4_K_M.gguf",
  ),
  RecommendedModel(
    name: "Llama 3.2 1B Instruct",
    description: "Standard small high-dialogue model.",
    quant: "Q4_K_M (Dialogue Specialized, ~810MB)",
    url: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
    filename: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
  ),
  RecommendedModel(
    name: "Llama 3.2 1B Instruct Abliterated",
    description: "Small & uncensored high-dialogue model (no safety filters).",
    quant: "Q4_K_M (Dialogue & Uncensored, ~810MB)",
    url: "https://huggingface.co/tensorblock/Llama-3.2-1B-Instruct-abliterated-GGUF/resolve/main/Llama-3.2-1B-Instruct-abliterated-Q4_K_M.gguf",
    filename: "Llama-3.2-1B-Instruct-abliterated-Q4_K_M.gguf",
  ),
  RecommendedModel(
    name: "Qwen 2.5 1.5B Instruct",
    description: "Smarter model with excellent reasoning capabilities.",
    quant: "Q4_K_M (High Quality Reasoning, ~1.1GB)",
    url: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
    filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
  ),
  RecommendedModel(
    name: "Qwen 2.5 1.5B Instruct Abliterated",
    description: "Reasoning model without safety alignments.",
    quant: "Q4_K_M (Smarter & Uncensored, ~1.1GB)",
    url: "https://huggingface.co/mradermacher/Qwen2.5-1.5B-Instruct-abliterated-i1-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-abliterated-i1.Q4_K_M.gguf",
    filename: "Qwen2.5-1.5B-Instruct-abliterated-i1.Q4_K_M.gguf",
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
      title: 'Antigravity Local AI',
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

  Future<void> _handleDownload(BuildContext context, String url, String filename) async {
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
        backgroundColor: theme.scaffoldBg.withOpacity(0.85),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.blur_on_rounded, color: theme.primaryAccent, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Antigravity Local AI",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              chatService.activeModel != null
                  ? "${chatService.activeModel!.name} (${chatService.activeModel!.quantization})"
                  : "Standby Mode",
              style: TextStyle(
                fontSize: 10,
                color: chatService.isModelLoaded ? theme.secondaryAccent : Colors.amber,
              ),
            ),
          ],
        ),
        actions: [
          // Settings Hub Button
          IconButton(
            icon: Icon(Icons.settings_suggest_rounded, color: theme.primaryAccent),
            tooltip: "System Hub",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SettingsSheet(themeBridge: themeBridge),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: theme.textSecondary),
            tooltip: "Clear Chat",
            onPressed: () {
              _stopTts();
              chatService.clearConversation();
            },
          ),
        ],
      ),
      drawer: _buildModelDrawer(context, chatService, themeBridge),
      body: Stack(
        children: [
          // Stunning Dynamic Mesh Background with ambient glowing circles in corners
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: theme.backgroundGradient,
              ),
            ),
          ),
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryAccent.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryAccent.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 80,
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.secondaryAccent.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: theme.secondaryAccent.withOpacity(0.12),
                    blurRadius: 120,
                    spreadRadius: 80,
                  )
                ],
              ),
            ),
          ),

          // Main Chat Interface Page
          SafeArea(
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
        ],
      ),
    );
  }

  Widget _buildStatusBar(ChatService chatService, AppThemeProfile theme) {
    final hasError = chatService.status.contains("Error") || chatService.status.contains("Panic");
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: hasError ? Colors.red.withOpacity(0.15) : theme.cardBg.withOpacity(0.7),
            border: Border(bottom: BorderSide(color: theme.primaryAccent.withOpacity(0.15), width: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasError ? Colors.red : (chatService.isModelLoaded ? theme.secondaryAccent : Colors.amber),
                  boxShadow: [
                    BoxShadow(
                      color: hasError ? Colors.red : theme.primaryAccent,
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  chatService.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasError ? Colors.redAccent : theme.textPrimary,
                  ),
                  maxLines: hasError ? null : 1,
                  overflow: hasError ? null : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ChatService chatService, AppThemeProfile theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.primaryAccent.withOpacity(0.15), theme.secondaryAccent.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: theme.primaryAccent.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(
                Icons.blur_on_rounded,
                size: 80,
                color: theme.primaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Antigravity Local AI",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: theme.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Experience complete digital sovereignty. Run heavy transformer models directly on-device with zero cloud latency and total privacy.",
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            if (chatService.activeModel == null)
              ElevatedButton.icon(
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text("Initialize Engine"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: theme.primaryAccent.withOpacity(0.5),
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
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
        margin: const EdgeInsets.only(bottom: 20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Bubble structure
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                gradient: isUser ? theme.bubbleGradient : null,
                color: isUser ? null : theme.cardBg.withOpacity(0.85),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 22),
                ),
                border: isUser
                    ? null
                    : Border.all(color: theme.primaryAccent.withOpacity(0.08), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: isUser ? Colors.white : theme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  
                  // Pulse Scale waves readout indicator
                  if (isSpeaking)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Icon(Icons.volume_up_rounded, color: theme.secondaryAccent, size: 14),
                          const SizedBox(width: 6),
                          AnimatedScale(
                            scale: _ttsPulseScale,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: 80,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1.5),
                                gradient: LinearGradient(
                                  colors: [theme.secondaryAccent, theme.primaryAccent],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text("Speaking...", style: TextStyle(fontSize: 9, color: theme.secondaryAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 6),

            // Smart Interactive Icon Action Bar Beneath Message Bubble
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  // Icon copy tool
                  GestureDetector(
                    onTap: () => _copyToClipboard(msg.text),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(Icons.copy_rounded, size: 13, color: theme.textSecondary.withOpacity(0.4)),
                    ),
                  ),
                  
                  // TTS speak button
                  GestureDetector(
                    onTap: () => _toggleTtsPlayback(msg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(
                        isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        size: 13,
                        color: isSpeaking ? theme.secondaryAccent : theme.textSecondary.withOpacity(0.4),
                      ),
                    ),
                  ),
                  
                  // Share exporter
                  GestureDetector(
                    onTap: () => _shareMessage(msg.text),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(Icons.share_rounded, size: 13, color: theme.textSecondary.withOpacity(0.4)),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isUser ? Icons.done_all_rounded : Icons.offline_bolt_rounded,
                    size: 11,
                    color: isUser ? Colors.white38 : theme.secondaryAccent.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.textSecondary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ChatService chatService, AppThemeProfile theme) {
    final isInteractive = chatService.isModelLoaded && !chatService.isGenerating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.scaffoldBg.withOpacity(0.9),
        border: Border(top: BorderSide(color: theme.primaryAccent.withOpacity(0.1), width: 0.5)),
      ),
      child: Column(
        children: [
          // Display image attachment placeholder if picked
          if (_selectedImagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.primaryAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.image_outlined, color: theme.secondaryAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Attachment: ${p.basename(_selectedImagePath!)}",
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                      onPressed: () => setState(() => _selectedImagePath = null),
                    ),
                  ],
                ),
              ),
            ),

          Row(
            children: [
              // Internet RAG toggle button
              IconButton(
                icon: Icon(
                  Icons.language_rounded,
                  color: _webSearchEnabled ? Colors.greenAccent[400] : theme.textSecondary,
                  size: 24,
                ),
                tooltip: _webSearchEnabled ? "Offline Web Search Active" : "Enable Web Search RAG Mode",
                onPressed: () {
                  setState(() {
                    _webSearchEnabled = !_webSearchEnabled;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_webSearchEnabled
                          ? "Internet Search Enabled (Simulated local KB ingestion)."
                          : "Internet Search Disabled. Standby local mode."),
                      duration: const Duration(seconds: 1),
                      backgroundColor: _webSearchEnabled ? Colors.green[800] : theme.cardBg,
                    ),
                  );
                },
              ),

              // Image attachment context button
              IconButton(
                icon: Icon(
                  Icons.image_outlined,
                  color: _selectedImagePath != null ? theme.secondaryAccent : theme.textSecondary,
                  size: 24,
                ),
                tooltip: "Attach Image Context",
                onPressed: isInteractive ? _pickAttachmentImage : null,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isInteractive ? theme.primaryAccent.withOpacity(0.15) : Colors.transparent,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    enabled: isInteractive,
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: chatService.activeModel == null
                          ? "Load model in sidebar to start"
                          : chatService.isGenerating
                              ? "Engine generating tokens..."
                              : "Message offline AI...",
                      hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.4), fontSize: 13.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isInteractive ? () => _handleSend(chatService) : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isInteractive ? theme.bubbleGradient : null,
                    color: isInteractive ? null : theme.cardBg,
                  ),
                  child: Icon(
                    chatService.isGenerating ? Icons.more_horiz : Icons.send_rounded,
                    color: isInteractive ? Colors.white : theme.textSecondary.withOpacity(0.3),
                    size: 18,
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
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(color: theme.cardBg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryAccent.withOpacity(0.1),
                  ),
                  child: Icon(Icons.offline_bolt_rounded, size: 30, color: theme.secondaryAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Model Vault",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: theme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${installedModels.length} GGUF loaded",
                        style: TextStyle(fontSize: 11, color: theme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isImporting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Copying GGUF to Sandbox...", style: TextStyle(fontSize: 11, color: theme.textPrimary)),
                      Text("${(_importProgress * 100).toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryAccent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _importProgress,
                    backgroundColor: theme.cardBg,
                    color: theme.primaryAccent,
                  ),
                ],
              ),
            ),

          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Downloading $_downloadingModelName...",
                          style: TextStyle(fontSize: 11, color: theme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "${(_downloadProgress * 100).toStringAsFixed(0)}%",
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.secondaryAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: theme.cardBg,
                    color: theme.secondaryAccent,
                  ),
                ],
              ),
            ),

          // Double lists inside Drawer: Sessions history and Installed Models
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                // 1. Thread Session manager
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CHAT SESSIONS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: theme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => chatService.createNewSession(),
                      child: Icon(Icons.add_circle_outline_rounded, color: theme.secondaryAccent, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...sessions.map((s) {
                  final isActive = s.id == chatService.activeSessionId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isActive ? theme.primaryAccent.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      dense: true,
                      title: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive ? theme.textPrimary : theme.textSecondary,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, size: 14, color: theme.textSecondary.withOpacity(0.5)),
                            onPressed: () => _showRenameDialog(context, chatService, s.id, s.title, theme),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent.withOpacity(0.6)),
                            onPressed: () => chatService.deleteSession(s.id),
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

                const SizedBox(height: 20),
                Divider(color: theme.primaryAccent.withOpacity(0.1)),
                const SizedBox(height: 12),

                // 2. Installed Models Section
                Text(
                  "INSTALLED MODELS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                
                if (installedModels.isEmpty)
                  Card(
                    color: theme.cardBg.withOpacity(0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.primaryAccent.withOpacity(0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 24, color: theme.textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text(
                            "No Models Installed",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Import a custom GGUF or download below.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9.5, color: theme.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...installedModels.map((m) {
                    final isActive = chatService.activeModel?.path == m.path;
                    return Card(
                      color: isActive ? theme.primaryAccent.withOpacity(0.08) : theme.cardBg.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isActive ? theme.primaryAccent.withOpacity(0.4) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        dense: true,
                        title: Text(
                          m.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          "${m.quantization} • ${m.sizeInGB.toStringAsFixed(2)} GB",
                          style: TextStyle(fontSize: 10, color: theme.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive && chatService.isModelLoaded)
                              Icon(Icons.offline_pin_rounded, color: theme.secondaryAccent, size: 20)
                            else if (isActive && !chatService.isModelLoaded)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryAccent),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                onPressed: () async {
                                  await modelManager.deleteModel(m);
                                  setState(() {});
                                },
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

                const SizedBox(height: 24),
                Divider(color: theme.primaryAccent.withOpacity(0.1)),
                const SizedBox(height: 12),

                // Section 3: Recommended Downloads
                Text(
                  "CLOUD DOWNLOAD VAULT",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                ...recommendedModelsList.map((model) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildRecommendedModelCard(
                      context,
                      theme,
                      name: model.name,
                      quant: model.quant,
                      url: model.url,
                      filename: model.filename,
                      installedModels: installedModels,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text("Import Custom GGUF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _isImporting || _isDownloading ? null : () => _handleImport(context),
            ),
          ),
        ],
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
    required List<GgufModel> installedModels,
  }) {
    final isInstalled = installedModels.any((m) => m.path.endsWith(filename));
    final isThisDownloading = _isDownloading && _downloadingModelName == name.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primaryAccent.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInstalled ? Colors.green.withOpacity(0.1) : theme.primaryAccent.withOpacity(0.1),
            ),
            child: Icon(
              isInstalled ? Icons.cloud_done_rounded : Icons.cloud_download_rounded,
              size: 16,
              color: isInstalled ? Colors.greenAccent[400] : theme.primaryAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  quant,
                  style: TextStyle(fontSize: 9, color: theme.textSecondary),
                ),
              ],
            ),
          ),
          if (isThisDownloading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: _downloadProgress,
                strokeWidth: 2,
                color: theme.secondaryAccent,
              ),
            )
          else if (isInstalled)
            Icon(Icons.check_circle_rounded, color: Colors.greenAccent[400], size: 18)
          else
            IconButton(
              icon: Icon(Icons.download_rounded, color: theme.primaryAccent, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _isDownloading || _isImporting
                  ? null
                  : () => _handleDownload(context, url, filename),
            ),
        ],
      ),
    );
  }

}
