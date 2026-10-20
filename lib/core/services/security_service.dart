import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum SecurityUnlockResult {
  success,
  killSwitchTriggered,
  failed,
}

class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  late final File _configFile;
  bool _isInitialized = false;

  bool _isConfigured = false;
  bool _isUnlocked = false;
  bool _hasCompletedOnboarding = false;

  String? _masterHash;
  String? _killSwitchHash;
  String? _salt;

  bool get isInitialized => _isInitialized;
  bool get isConfigured => _isConfigured;
  bool get isUnlocked => _isUnlocked;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// Initialize security config from application documents
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _configFile = File(p.join(appDocDir.path, 'security_config.json'));

      if (await _configFile.exists()) {
        final content = await _configFile.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;

        _hasCompletedOnboarding = map['hasCompletedOnboarding'] as bool? ?? false;
        _isConfigured = map['isConfigured'] as bool? ?? false;
        _masterHash = map['masterHash'] as String?;
        _killSwitchHash = map['killSwitchHash'] as String?;
        _salt = map['salt'] as String?;
        
        // If security is not configured, consider it automatically unlocked
        _isUnlocked = !_isConfigured;
      } else {
        _hasCompletedOnboarding = false;
        _isConfigured = false;
        _isUnlocked = true;
      }
    } catch (e) {
      debugPrint("[SecurityService] Error loading config: $e");
      _isConfigured = false;
      _isUnlocked = true;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Mark welcome onboarding completed
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _saveConfig();
    notifyListeners();
  }

  /// Setup or update passcodes
  Future<void> setPasscodes({
    required String masterCode,
    required String killSwitchCode,
  }) async {
    if (masterCode.trim().isEmpty || killSwitchCode.trim().isEmpty) {
      throw Exception("Passcodes cannot be empty.");
    }
    if (masterCode.trim() == killSwitchCode.trim()) {
      throw Exception("Kill Switch passcode must be different from Master passcode.");
    }

    _salt ??= DateTime.now().microsecondsSinceEpoch.toString();
    _masterHash = _hash(masterCode.trim(), _salt!);
    _killSwitchHash = _hash(killSwitchCode.trim(), _salt!);
    _isConfigured = true;
    _isUnlocked = true; // User just set them, so unlocked
    _hasCompletedOnboarding = true;

    await _saveConfig();
    notifyListeners();
  }

  /// Disable passcodes and remove security lock
  Future<void> disableSecurity() async {
    _isConfigured = false;
    _isUnlocked = true;
    _masterHash = null;
    _killSwitchHash = null;

    await _saveConfig();
    notifyListeners();
  }

  /// Lock app manually
  void lock() {
    if (_isConfigured) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  /// Attempt to unlock with given passcode
  Future<SecurityUnlockResult> unlock(String enteredCode) async {
    if (!_isConfigured) {
      _isUnlocked = true;
      notifyListeners();
      return SecurityUnlockResult.success;
    }

    if (_salt == null) return SecurityUnlockResult.failed;

    final trimmed = enteredCode.trim();
    final enteredHash = _hash(trimmed, _salt!);

    if (enteredHash == _masterHash) {
      _isUnlocked = true;
      notifyListeners();
      return SecurityUnlockResult.success;
    } else if (enteredHash == _killSwitchHash) {
      _isUnlocked = true;
      notifyListeners();
      return SecurityUnlockResult.killSwitchTriggered;
    } else {
      return SecurityUnlockResult.failed;
    }
  }

  Future<void> _saveConfig() async {
    try {
      final map = {
        'hasCompletedOnboarding': _hasCompletedOnboarding,
        'isConfigured': _isConfigured,
        'masterHash': _masterHash,
        'killSwitchHash': _killSwitchHash,
        'salt': _salt,
      };
      await _configFile.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      debugPrint("[SecurityService] Error saving config: $e");
    }
  }

  /// Self-contained multi-round cryptographic SHA-256 hash
  static String _hash(String input, String salt) {
    final bytes = utf8.encode("$salt::$input::duress_shield");
    return _sha256(bytes);
  }

  static String _sha256(List<int> data) {
    // Standard SHA-256 implementation in pure Dart
    final h = <int>[
      0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
      0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ];

    const k = <int>[
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];

    final bitLen = data.length * 8;
    final padded = List<int>.from(data)..add(0x80);
    while ((padded.length % 64) != 56) {
      padded.add(0);
    }
    for (int i = 7; i >= 0; i--) {
      padded.add((bitLen >> (i * 8)) & 0xff);
    }

    final w = List<int>.filled(64, 0);

    for (int chunk = 0; chunk < padded.length; chunk += 64) {
      for (int i = 0; i < 16; i++) {
        w[i] = (padded[chunk + i * 4] << 24) |
               (padded[chunk + i * 4 + 1] << 16) |
               (padded[chunk + i * 4 + 2] << 8) |
               (padded[chunk + i * 4 + 3]);
      }
      for (int i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }

      int a = h[0], b = h[1], c = h[2], d = h[3];
      int e = h[4], f = h[5], g = h[6], hVal = h[7];

      for (int i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ (~e & g);
        final temp1 = (hVal + s1 + ch + k[i] + w[i]) & 0xffffffff;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xffffffff;

        hVal = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }

      h[0] = (h[0] + a) & 0xffffffff;
      h[1] = (h[1] + b) & 0xffffffff;
      h[2] = (h[2] + c) & 0xffffffff;
      h[3] = (h[3] + d) & 0xffffffff;
      h[4] = (h[4] + e) & 0xffffffff;
      h[5] = (h[5] + f) & 0xffffffff;
      h[6] = (h[6] + g) & 0xffffffff;
      h[7] = (h[7] + hVal) & 0xffffffff;
    }

    return h.map((v) => v.toRadixString(16).padLeft(8, '0')).join();
  }

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xffffffff;
}
