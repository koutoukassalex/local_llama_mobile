import 'dart:ui';
import 'package:flutter/cupertino.dart';
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

class _SettingsSheetState extends State<SettingsSheet> {
  int _selectedSegment = 0;
  late int _localThemeIndex;

  @override
  void initState() {
    super.initState();
    _localThemeIndex = widget.themeBridge.activeThemeIndex;
  }

  void _updateTheme(int newIndex) {
    setState(() {
      _localThemeIndex = newIndex;
    });
    widget.themeBridge.onThemeChanged(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = appThemesList[_localThemeIndex];
    final chatService = Provider.of<ChatService>(context);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: theme.scaffoldBg.withOpacity(0.94),
          height: MediaQuery.of(context).size.height * 0.88,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // iOS Grabber handle
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                // Navigation Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: theme.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            "Done",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // iOS Segmented Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.cardBg.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        _buildSegmentButton(0, "Appearance", theme),
                        _buildSegmentButton(1, "Inference", theme),
                        _buildSegmentButton(2, "Engine", theme),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Divider(color: theme.textSecondary.withOpacity(0.08), height: 1),

                // Tab Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _selectedSegment == 0
                        ? _buildAppearanceTab(context, theme)
                        : _selectedSegment == 1
                            ? _buildInferenceTab(context, chatService, theme)
                            : _buildEngineTab(context, chatService, theme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, AppThemeProfile theme) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? theme.textPrimary : theme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: APPEARANCE
  // ---------------------------------------------------------------------------
  Widget _buildAppearanceTab(BuildContext context, AppThemeProfile activeTheme) {
    final descriptions = [
      "Pure Black • High Contrast",
      "Pure White • Clean Editorial",
      "Apple Navy • Subtle Hue",
      "Warm Sunset • Soft Tones",
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "THEME SELECTION",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: activeTheme.textSecondary.withOpacity(0.7),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: appThemesList.length,
          itemBuilder: (context, index) {
            final t = appThemesList[index];
            final isSelected = _localThemeIndex == index;

            return GestureDetector(
              onTap: () => _updateTheme(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: t.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? t.primaryAccent : t.textSecondary.withOpacity(0.15),
                    width: isSelected ? 2.0 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: t.primaryAccent.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bubble preview circle
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: t.bubbleGradient,
                          ),
                          child: Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: t.primaryAccent, size: 22)
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: t.textSecondary.withOpacity(0.25), width: 1.5),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      t.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      index < descriptions.length ? descriptions[index] : "",
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: INFERENCE
  // ---------------------------------------------------------------------------
  Widget _buildInferenceTab(BuildContext context, ChatService chatService, AppThemeProfile theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section: System Prompt
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "SYSTEM PROMPT",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: theme.textSecondary.withOpacity(0.7),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: chatService.systemPrompt,
                style: TextStyle(color: theme.textPrimary, fontSize: 15, height: 1.4),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter system instructions to guide model responses...",
                  hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5), fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  chatService.systemPrompt = val;
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section: Sampling Parameters
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "SAMPLING PARAMETERS",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: theme.textSecondary.withOpacity(0.7),
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
          ),
          child: Column(
            children: [
              _buildSliderRow(
                title: "Temperature",
                displayValue: chatService.temperature.toStringAsFixed(2),
                subtitle: chatService.temperature < 0.4
                    ? "Strict, deterministic, and factual."
                    : chatService.temperature < 0.9
                        ? "Balanced creativity and coherence."
                        : "Highly expressive and imaginative.",
                value: chatService.temperature,
                min: 0.1,
                max: 1.5,
                theme: theme,
                onChanged: (val) => setState(() => chatService.temperature = val),
              ),
              Divider(color: theme.textSecondary.withOpacity(0.08), height: 1, indent: 16),
              _buildSliderRow(
                title: "Top P",
                displayValue: chatService.topP.toStringAsFixed(2),
                subtitle: "Nucleus sampling threshold.",
                value: chatService.topP,
                min: 0.1,
                max: 1.0,
                theme: theme,
                onChanged: (val) => setState(() => chatService.topP = val),
              ),
              Divider(color: theme.textSecondary.withOpacity(0.08), height: 1, indent: 16),
              _buildSliderRow(
                title: "Top K",
                displayValue: chatService.topK.toString(),
                subtitle: "Limits next token candidate pool.",
                value: chatService.topK.toDouble(),
                min: 10,
                max: 100,
                divisions: 9,
                theme: theme,
                onChanged: (val) => setState(() => chatService.topK = val.toInt()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: ENGINE
  // ---------------------------------------------------------------------------
  Widget _buildEngineTab(BuildContext context, ChatService chatService, AppThemeProfile theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // iOS Warning Callout
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9F0A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF9F0A).withOpacity(0.2), width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFFF9F0A), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Modifying engine parameters will reload the active model and clear temporary context memory.",
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "HARDWARE ALLOCATION",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: theme.textSecondary.withOpacity(0.7),
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
          ),
          child: Column(
            children: [
              _buildSliderRow(
                title: "Context Window",
                displayValue: "${chatService.nCtx} tokens",
                subtitle: "RAM consumption scales with context size.",
                value: chatService.nCtx.toDouble(),
                min: 512,
                max: 8192,
                divisions: 15,
                theme: theme,
                onChanged: (val) => setState(() => chatService.nCtx = val.toInt()),
              ),
              Divider(color: theme.textSecondary.withOpacity(0.08), height: 1, indent: 16),
              _buildSliderRow(
                title: "GPU Layer Offload",
                displayValue: chatService.nGpuLayers == 99 ? "All (99)" : chatService.nGpuLayers.toString(),
                subtitle: "Layers processed on Metal / Vulkan GPU.",
                value: chatService.nGpuLayers.toDouble(),
                min: 0,
                max: 99,
                divisions: 99,
                theme: theme,
                onChanged: (val) => setState(() => chatService.nGpuLayers = val.toInt()),
              ),
              Divider(color: theme.textSecondary.withOpacity(0.08), height: 1, indent: 16),
              _buildSliderRow(
                title: "CPU Threads",
                displayValue: "${chatService.nThreads} threads",
                subtitle: "Parallel threads for token generation.",
                value: chatService.nThreads.toDouble(),
                min: 1,
                max: 16,
                divisions: 15,
                theme: theme,
                onChanged: (val) => setState(() => chatService.nThreads = val.toInt()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SLIDER ROW HELPER
  // ---------------------------------------------------------------------------
  Widget _buildSliderRow({
    required String title,
    required String displayValue,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required AppThemeProfile theme,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: theme.textSecondary),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.primaryAccent,
              inactiveTrackColor: theme.textSecondary.withOpacity(0.15),
              thumbColor: Colors.white,
              overlayColor: theme.primaryAccent.withOpacity(0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
