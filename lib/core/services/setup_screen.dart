import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../main.dart'; // To access AppThemeProfile and ThemeProviderBridge

class SetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SetupScreen({super.key, required this.onComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  // Specs values
  String _osName = "Detecting...";
  String _osVersion = "";
  int _cpuCores = 0;
  
  // Audits states
  bool _isAuditing = false;
  double _auditProgress = 0.0;
  String _auditStage = "Hardware standby. Tap 'Run Audit' below.";
  
  // Audited values
  double? _diskWriteSpeed; // MB/s
  int? _benchmarkTimeMs; // ms
  String _benchmarkRank = "Not Audited";
  
  // RAM Selection State
  int _selectedRamTier = -1; // 0: <4GB, 1: 4-6GB, 2: 8GB+
  
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
      _auditStage = "Initializing hardware audit context...";
      _diskWriteSpeed = null;
      _benchmarkTimeMs = null;
      _benchmarkRank = "Not Audited";
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // --- STAGE 1: Disk Ingestion Write Speed Audit ---
    setState(() {
      _auditProgress = 0.25;
      _auditStage = "Testing sandboxed disk transfer rate (10MB payload)...";
    });
    
    await Future.delayed(const Duration(milliseconds: 400));
    
    double diskSpeed = 0.0;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final tempFile = File(p.join(appDocDir.path, 'temp_audit_file.bin'));
      
      // Build a 10MB chunk of data
      final bytes = List<int>.generate(10 * 1024 * 1024, (i) => i % 256);
      
      final stopwatch = Stopwatch()..start();
      await tempFile.writeAsBytes(bytes, flush: true);
      stopwatch.stop();
      
      final elapsedSecs = stopwatch.elapsedMilliseconds / 1000.0;
      diskSpeed = elapsedSecs > 0 ? (10.0 / elapsedSecs) : 1000.0;

      // Immediately cleanup
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      diskSpeed = 50.0; // Fallback
    }

    setState(() {
      _diskWriteSpeed = diskSpeed;
      _auditProgress = 0.5;
      _auditStage = "Disk write audit complete (${diskSpeed.toStringAsFixed(1)} MB/s).";
    });

    await Future.delayed(const Duration(milliseconds: 400));

    // --- STAGE 2: Compute Power Math Benchmark ---
    setState(() {
      _auditProgress = 0.75;
      _auditStage = "Benchmarking raw computational Floating-Point ALU capacity...";
    });

    await Future.delayed(const Duration(milliseconds: 400));

    final stopwatch = Stopwatch()..start();
    
    // Dense math calculation stress loop (5 million operations)
    double sum = 0.0;
    for (int i = 1; i <= 5000000; i++) {
      sum += math.sin(i) * math.cos(i) + math.sqrt(i);
    }
    
    stopwatch.stop();
    final benchmarkTime = stopwatch.elapsedMilliseconds;
    
    String rank;
    if (benchmarkTime < 150) {
      rank = "Flagship Compute (Tier 3)";
    } else if (benchmarkTime < 350) {
      rank = "Standard Compute (Tier 2)";
    } else {
      rank = "Budget Compute (Tier 1)";
    }

    setState(() {
      _benchmarkTimeMs = benchmarkTime;
      _benchmarkRank = rank;
      _auditProgress = 1.0;
      _isAuditing = false;
      _auditStage = "Hardware audit successfully finalized!";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderBridge.of(context).activeTheme;

    final isSystemReady = _cpuCores >= 4;
    final isAuditRun = _diskWriteSpeed != null && _benchmarkTimeMs != null;
    final canProceed = isAuditRun && _selectedRamTier != -1;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Pulsing Engine Core Visual
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryAccent.withOpacity(0.1 + (_pulseController.value * 0.08)),
                        border: Border.all(
                          color: theme.secondaryAccent.withOpacity(0.2 + (_pulseController.value * 0.3)),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.offline_bolt_rounded,
                        size: 48,
                        color: theme.secondaryAccent,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  "NEURAL HARNESS SETUP",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Let's audit your phone specifications to ensure premium high-performance local AI inference.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: theme.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Specifications Summary Card (Glassmorphic)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardBg.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primaryAccent.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "CORE HARDWARE READOUTS",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: theme.secondaryAccent,
                            ),
                          ),
                          Icon(
                            isSystemReady ? Icons.check_circle : Icons.warning_rounded,
                            size: 14,
                            color: isSystemReady ? Colors.greenAccent[400] : Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSpecItem(
                        icon: Icons.developer_mode_rounded,
                        label: "Operating System",
                        value: "$_osName (${_osVersion.split(' ').first})",
                        theme: theme,
                      ),
                      _buildSpecItem(
                        icon: Icons.memory_rounded,
                        label: "Processor Compute Cores",
                        value: "$_cpuCores Cores Detected",
                        statusText: _cpuCores >= 8 
                            ? "Optimal (Octa-Core)" 
                            : _cpuCores >= 4 
                                ? "Compatible" 
                                : "Warning: Weak Core Count",
                        statusColor: _cpuCores >= 8 
                            ? Colors.greenAccent[400] 
                            : _cpuCores >= 4 
                                ? Colors.cyanAccent[400] 
                                : Colors.amber,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // Interactive Benchmark Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardBg.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primaryAccent.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "HARDWARE CAPABILITY AUDIT",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: theme.secondaryAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        _auditStage,
                        style: TextStyle(fontSize: 11.5, color: theme.textPrimary),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      if (_isAuditing)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _auditProgress,
                            backgroundColor: theme.scaffoldBg,
                            color: theme.secondaryAccent,
                            minHeight: 6,
                          ),
                        )
                      else if (isAuditRun)
                        Column(
                          children: [
                            _buildSpecItem(
                              icon: Icons.speed_rounded,
                              label: "Sandboxed Disk Throughput",
                              value: "${_diskWriteSpeed!.toStringAsFixed(1)} MB/s",
                              statusText: _diskWriteSpeed! >= 200 
                                  ? "High-Speed SSD" 
                                  : _diskWriteSpeed! >= 80 
                                      ? "Standard Storage" 
                                      : "Slow Storage",
                              statusColor: _diskWriteSpeed! >= 200 
                                  ? Colors.greenAccent[400] 
                                  : _diskWriteSpeed! >= 80 
                                      ? Colors.cyanAccent[400] 
                                      : Colors.amber,
                              theme: theme,
                            ),
                            _buildSpecItem(
                              icon: Icons.query_stats_rounded,
                              label: "Floating-Point Calculation Benchmark",
                              value: "${_benchmarkTimeMs} ms loop time",
                              statusText: _benchmarkRank,
                              statusColor: _benchmarkTimeMs! < 150 
                                  ? Colors.greenAccent[400] 
                                  : _benchmarkTimeMs! < 350 
                                      ? Colors.cyanAccent[400] 
                                      : Colors.amber,
                              theme: theme,
                            ),
                          ],
                        ),
                        
                      const SizedBox(height: 12),
                      
                      ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on_rounded, size: 16),
                        label: Text(_isAuditing ? "Auditing Specs..." : isAuditRun ? "Re-Run Hardware Audit" : "Run Hardware Performance Audit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isAuditing ? null : _runHardwareAudit,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // RAM Tier Selector Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardBg.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primaryAccent.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DEVICE RAM SPECIFICATION",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: theme.secondaryAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Due to sandboxing restrictions, please confirm your phone's total RAM size:",
                        style: TextStyle(fontSize: 11.5, color: theme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          _buildRamCard(0, "Budget Phone", "< 4 GB", theme),
                          const SizedBox(width: 10),
                          _buildRamCard(1, "Standard Phone", "4 - 6 GB", theme),
                          const SizedBox(width: 10),
                          _buildRamCard(2, "Flagship Phone", "8 GB+", theme),
                        ],
                      ),
                      
                      if (_selectedRamTier != -1) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.primaryAccent.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedRamTier == 2 
                                    ? Icons.check_circle_outline_rounded 
                                    : Icons.info_outline_rounded,
                                color: _selectedRamTier == 2 
                                    ? Colors.greenAccent[400] 
                                    : Colors.cyanAccent[400],
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _getRamTierDescription(),
                                  style: const TextStyle(fontSize: 11, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Proceed Action
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text("Initialize AI System"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed ? theme.secondaryAccent : theme.cardBg.withOpacity(0.5),
                    foregroundColor: canProceed ? Colors.white : theme.textSecondary.withOpacity(0.4),
                    elevation: canProceed ? 8 : 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: canProceed ? widget.onComplete : null,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
    String? statusText,
    Color? statusColor,
    required AppThemeProfile theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.scaffoldBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: theme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: theme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textPrimary),
                ),
                if (statusText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRamCard(int tier, String title, String subtitle, AppThemeProfile theme) {
    final isSelected = _selectedRamTier == tier;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRamTier = tier;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryAccent.withOpacity(0.12) : theme.scaffoldBg.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? theme.primaryAccent : theme.primaryAccent.withOpacity(0.08),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? theme.textPrimary : theme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? theme.secondaryAccent : theme.textPrimary,
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
        return "Recommended for 'Ultra-Mini' 0.5B models only (both Standard & Abliterated versions). Loading larger models may crash the app due to system memory limits.";
      case 1:
        return "Fully supports 0.5B and 1B models (e.g. Llama 3.2 1B Instruct). Safe and stable memory bounds for comfortable local offline chat.";
      case 2:
        return "Flagship hardware detected! Fully compatible with all models up to 1.5B/3B, including dense Reasoning models and abliterated variants.";
      default:
        return "";
    }
  }
}
