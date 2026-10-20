import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../main.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SetupScreen({super.key, required this.onComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  String _osName = "Detecting...";
  String _osVersion = "";
  int _cpuCores = 0;

  bool _isAuditing = false;
  double _auditProgress = 0.0;
  String _auditStage = "Ready to audit hardware capabilities.";

  double? _diskWriteSpeed;
  int? _benchmarkTimeMs;
  String _benchmarkRank = "Not Audited";

  int _selectedRamTier = -1;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _detectCoreSpecs();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _detectCoreSpecs() {
    setState(() {
      _osName = Platform.operatingSystem.toUpperCase();
      _osVersion = Platform.operatingSystemVersion;
      _cpuCores = Platform.numberOfProcessors;
    });
  }

  Future<void> _runHardwareAudit() async {
    if (_isAuditing) return;

    setState(() {
      _isAuditing = true;
      _auditProgress = 0.0;
      _auditStage = "Initializing hardware audit...";
      _diskWriteSpeed = null;
      _benchmarkTimeMs = null;
      _benchmarkRank = "Not Audited";
    });

    await Future.delayed(const Duration(milliseconds: 400));

    // STAGE 1: Disk Ingestion Write Speed Audit
    setState(() {
      _auditProgress = 0.3;
      _auditStage = "Measuring storage read/write performance...";
    });

    await Future.delayed(const Duration(milliseconds: 300));

    double diskSpeed = 0.0;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final tempFile = File(p.join(appDocDir.path, 'temp_audit_file.bin'));
      final bytes = List<int>.generate(10 * 1024 * 1024, (i) => i % 256);

      final stopwatch = Stopwatch()..start();
      await tempFile.writeAsBytes(bytes, flush: true);
      stopwatch.stop();

      final elapsedSecs = stopwatch.elapsedMilliseconds / 1000.0;
      diskSpeed = elapsedSecs > 0 ? (10.0 / elapsedSecs) : 1000.0;

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      diskSpeed = 150.0;
    }

    // STAGE 2: CPU Floating Point Matrix Math Benchmark
    setState(() {
      _diskWriteSpeed = diskSpeed;
      _auditProgress = 0.7;
      _auditStage = "Running CPU floating-point benchmark...";
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final mathStopwatch = Stopwatch()..start();
    double acc = 0.0;
    for (int i = 0; i < 4000000; i++) {
      acc += math.sin(i.toDouble()) * math.cos(i.toDouble()) + math.sqrt(i.toDouble() + 1.0);
    }
    mathStopwatch.stop();

    final benchTime = mathStopwatch.elapsedMilliseconds;
    String rank;
    if (benchTime < 150) {
      rank = "Tier 1: High Performance";
    } else if (benchTime < 350) {
      rank = "Tier 2: Standard Performance";
    } else {
      rank = "Tier 3: Entry Performance";
    }

    // Auto-select RAM Tier based on cores if not already set
    if (_selectedRamTier == -1) {
      if (_cpuCores >= 8) {
        _selectedRamTier = 2;
      } else if (_cpuCores >= 6) {
        _selectedRamTier = 1;
      } else {
        _selectedRamTier = 0;
      }
    }

    setState(() {
      _benchmarkTimeMs = benchTime;
      _benchmarkRank = rank;
      _auditProgress = 1.0;
      _auditStage = "Audit completed successfully.";
      _isAuditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderBridge.of(context).activeTheme;
    final isAuditRun = _diskWriteSpeed != null && _benchmarkTimeMs != null;
    final canProceed = _selectedRamTier != -1;

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Emblem
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryAccent.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.primaryAccent.withOpacity(0.12),
                      child: Icon(Icons.tune_rounded, size: 38, color: theme.primaryAccent),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Device Setup",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll verify your device specifications to configure optimal performance for on-device inference.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: theme.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // Specifications Card
              _buildSectionHeader("SYSTEM INFORMATION", theme),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      label: "Operating System",
                      value: "$_osName (${_osVersion.split(' ').first})",
                      theme: theme,
                    ),
                    Divider(color: theme.textSecondary.withOpacity(0.08), height: 20),
                    _buildRow(
                      label: "CPU Compute Cores",
                      value: "$_cpuCores Cores",
                      badge: _cpuCores >= 8 ? "Optimal" : _cpuCores >= 4 ? "Compatible" : "Entry",
                      badgeColor: _cpuCores >= 8 ? const Color(0xFF30D158) : const Color(0xFF0A84FF),
                      theme: theme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Benchmark Section
              _buildSectionHeader("HARDWARE AUDIT", theme),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auditStage,
                      style: TextStyle(fontSize: 14, color: theme.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    if (_isAuditing) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _auditProgress,
                          backgroundColor: theme.scaffoldBg,
                          color: theme.primaryAccent,
                          minHeight: 5,
                        ),
                      ),
                    ] else if (isAuditRun) ...[
                      const SizedBox(height: 16),
                      _buildRow(
                        label: "Storage Throughput",
                        value: "${_diskWriteSpeed!.toStringAsFixed(1)} MB/s",
                        badge: _diskWriteSpeed! >= 150 ? "Fast" : "Standard",
                        badgeColor: _diskWriteSpeed! >= 150 ? const Color(0xFF30D158) : const Color(0xFF0A84FF),
                        theme: theme,
                      ),
                      Divider(color: theme.textSecondary.withOpacity(0.08), height: 20),
                      _buildRow(
                        label: "CPU Math Benchmark",
                        value: "${_benchmarkTimeMs} ms",
                        badge: _benchmarkRank.split(':').last.trim(),
                        badgeColor: const Color(0xFF30D158),
                        theme: theme,
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        icon: Icon(_isAuditing ? Icons.hourglass_top_rounded : Icons.flash_on_rounded, size: 18),
                        label: Text(
                          _isAuditing ? "Auditing..." : isAuditRun ? "Re-Run Hardware Audit" : "Run Hardware Performance Audit",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primaryAccent,
                          side: BorderSide(color: theme.primaryAccent.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isAuditing ? null : _runHardwareAudit,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // RAM Specification Section
              _buildSectionHeader("TOTAL DEVICE RAM", theme),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select your device's RAM tier to ensure safe memory bounds:",
                      style: TextStyle(fontSize: 13, color: theme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildRamOption(0, "Budget", "< 4 GB", theme),
                        const SizedBox(width: 8),
                        _buildRamOption(1, "Standard", "4 - 6 GB", theme),
                        const SizedBox(width: 8),
                        _buildRamOption(2, "Flagship", "8+ GB", theme),
                      ],
                    ),
                    if (_selectedRamTier != -1) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getRamTierDescription(),
                          style: TextStyle(fontSize: 13, color: theme.textPrimary, height: 1.35),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Proceed CTA Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed ? theme.primaryAccent : theme.cardBg,
                    foregroundColor: canProceed ? Colors.white : theme.textSecondary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: canProceed ? widget.onComplete : null,
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeProfile theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: theme.textSecondary.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    String? badge,
    Color? badgeColor,
    required AppThemeProfile theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, color: theme.textSecondary),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textPrimary),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? theme.primaryAccent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor ?? theme.primaryAccent),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRamOption(int tier, String title, String subtitle, AppThemeProfile theme) {
    final isSelected = _selectedRamTier == tier;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRamTier = tier),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryAccent.withOpacity(0.12) : theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primaryAccent : theme.textSecondary.withOpacity(0.12),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? theme.primaryAccent : theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRamTierDescription() {
    switch (_selectedRamTier) {
      case 0:
        return "Optimized for models < 1.0 GB (SmolLM2, Qwen 0.5B, Llama 1B). Safe and stable memory bounds.";
      case 1:
        return "Fully supports models up to 2.5 GB (DeepSeek 1.5B, Llama 3.2 1B/3B, Qwen 1.5B).";
      case 2:
        return "Flagship hardware! Fully compatible with large models up to 3B+, including Reasoning and Vision models.";
      default:
        return "";
    }
  }
}
