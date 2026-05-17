import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../services/chat_service.dart';

class SettingsSheet extends StatefulWidget {
  final ThemeProviderBridge themeBridge;

  const SettingsSheet({super.key, required this.themeBridge});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeBridge.activeTheme;
    final chatService = Provider.of<ChatService>(context);

    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: theme.cardBg.withOpacity(0.9),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 16, top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings_suggest_rounded, color: theme.primaryAccent),
                        const SizedBox(width: 10),
                        Text(
                          "System Hub",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: theme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: theme.primaryAccent,
                labelColor: theme.primaryAccent,
                unselectedLabelColor: theme.textSecondary,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "Aesthetics", icon: Icon(Icons.palette_rounded)),
                  Tab(text: "AI Tuning", icon: Icon(Icons.psychology_alt_rounded)),
                  Tab(text: "Hardware", icon: Icon(Icons.memory_rounded)),
                ],
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAestheticsTab(context, theme),
                    _buildAiTuningTab(context, chatService, theme),
                    _buildHardwareTab(context, chatService, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAestheticsTab(BuildContext context, AppThemeProfile activeTheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: appThemesList.length,
      itemBuilder: (context, index) {
        final t = appThemesList[index];
        final isSelected = widget.themeBridge.activeThemeIndex == index;

        return GestureDetector(
          onTap: () {
            widget.themeBridge.onThemeChanged(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: t.backgroundGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? t.primaryAccent : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: t.primaryAccent.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Icon(Icons.check_circle_rounded, color: t.primaryAccent, size: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: t.bubbleGradient,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.name,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiTuningTab(BuildContext context, ChatService chatService, AppThemeProfile theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Prompt Field
          Text("System Prompt", style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            "Define the AI's core persona and behavioral boundaries.",
            style: TextStyle(fontSize: 12, color: theme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: chatService.systemPrompt,
            style: TextStyle(color: theme.textPrimary, fontSize: 14),
            maxLines: 4,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryAccent.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryAccent),
              ),
            ),
            onChanged: (val) {
              chatService.systemPrompt = val;
            },
          ),
          const SizedBox(height: 32),

          // Temperature Slider
          _buildSlider(
            title: "Temperature",
            value: chatService.temperature,
            min: 0.1,
            max: 1.5,
            theme: theme,
            onChanged: (val) => setState(() => chatService.temperature = val),
            subtitle: chatService.temperature < 0.4
                ? "Strict, predictable, and highly factual answers."
                : chatService.temperature < 0.9
                    ? "Balanced combination of creativity and logic."
                    : "Unconstrained creative writing and rapid brainstorming.",
          ),
          const SizedBox(height: 24),

          // Top P Slider
          _buildSlider(
            title: "Top P (Nucleus Sampling)",
            value: chatService.topP,
            min: 0.1,
            max: 1.0,
            theme: theme,
            onChanged: (val) => setState(() => chatService.topP = val),
            isSecondary: true,
          ),
          const SizedBox(height: 24),

          // Top K Slider
          _buildSlider(
            title: "Top K (Vocabulary Filter)",
            value: chatService.topK.toDouble(),
            min: 10,
            max: 100,
            divisions: 9,
            theme: theme,
            onChanged: (val) => setState(() => chatService.topK = val.toInt()),
            isSecondary: false,
            displayValue: chatService.topK.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareTab(BuildContext context, ChatService chatService, AppThemeProfile theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.primaryAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Warning: Changing hardware parameters will reload the active model and clear the current context memory.",
                    style: TextStyle(fontSize: 12, color: theme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Context Length Slider
          _buildSlider(
            title: "Context Window (nCtx)",
            value: chatService.nCtx.toDouble(),
            min: 512,
            max: 8192,
            divisions: 15,
            theme: theme,
            onChanged: (val) => setState(() => chatService.nCtx = val.toInt()),
            displayValue: "${chatService.nCtx} tokens",
            subtitle: "Higher context uses significantly more RAM.",
          ),
          const SizedBox(height: 24),

          // GPU Layers Slider
          _buildSlider(
            title: "GPU Layers Offload",
            value: chatService.nGpuLayers.toDouble(),
            min: 0,
            max: 99,
            divisions: 99,
            theme: theme,
            onChanged: (val) => setState(() => chatService.nGpuLayers = val.toInt()),
            isSecondary: true,
            displayValue: chatService.nGpuLayers == 99 ? "MAX" : chatService.nGpuLayers.toString(),
            subtitle: "Number of layers to offload to Vulkan/Metal GPU.",
          ),
          const SizedBox(height: 24),

          // Threads Slider
          _buildSlider(
            title: "CPU Threads",
            value: chatService.nThreads.toDouble(),
            min: 1,
            max: 16,
            divisions: 15,
            theme: theme,
            onChanged: (val) => setState(() => chatService.nThreads = val.toInt()),
            displayValue: chatService.nThreads.toString(),
            subtitle: "Number of CPU threads for evaluation.",
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required AppThemeProfile theme,
    required Function(double) onChanged,
    String? subtitle,
    bool isSecondary = false,
    String? displayValue,
  }) {
    final activeColor = isSecondary ? theme.secondaryAccent : theme.primaryAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary)),
            Text(
              displayValue ?? value.toStringAsFixed(2),
              style: TextStyle(fontWeight: FontWeight.bold, color: activeColor),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10.5, color: theme.textSecondary)),
        ],
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          inactiveColor: activeColor.withOpacity(0.15),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
