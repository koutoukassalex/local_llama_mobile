import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/gguf_model.dart';

class ModelManager {
  late final Directory _modelsDir;
  late final File _databaseFile;
  final List<GgufModel> _models = [];

  List<GgufModel> get models => List.unmodifiable(_models);

  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  /// Initialize local model directory and load available models database
  Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    
    // Create a subfolder specifically for GGUF models
    _modelsDir = Directory(p.join(appDocDir.path, 'gguf_models'));
    if (!await _modelsDir.exists()) {
      await _modelsDir.create(recursive: true);
    }

    _databaseFile = File(p.join(appDocDir.path, 'models_database.json'));
    await _loadDatabase();
  }

  /// Trigger secure system file picker to select a custom local GGUF file
  Future<GgufModel?> importCustomModel({Function(double progress)? onProgress}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Android/iOS don't recognize .gguf mime natively, pick as raw file
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty || result.files.single.path == null) {
      return null;
    }

    final selectedPath = result.files.single.path!;
    final file = File(selectedPath);
    final filename = p.basename(selectedPath);

    // Enforce GGUF extensions
    if (!filename.endsWith('.gguf')) {
      throw Exception("Invalid File: The selected model is not a valid GGUF file. Please import a file ending in '.gguf'.");
    }

    final sizeBytes = await file.length();
    final targetPath = p.join(_modelsDir.path, filename);
    final targetFile = File(targetPath);

    // If model file is already imported and placed inside sandbox, just load it
    if (await targetFile.exists()) {
      return _registerModel(filename, targetPath, sizeBytes);
    }

    // High-speed block copy of large file (>1.5GB) with progress indicator
    final iosSink = targetFile.openWrite(mode: FileMode.write);
    final srcStream = file.openRead();
    int copiedBytes = 0;

    await for (final chunk in srcStream) {
      iosSink.add(chunk);
      copiedBytes += chunk.length;
      if (onProgress != null) {
        onProgress(copiedBytes / sizeBytes);
      }
    }

    await iosSink.close();

    return _registerModel(filename, targetPath, sizeBytes);
  }

  Future<GgufModel> _registerModel(String filename, String path, int sizeBytes) async {
    final family = GgufModel.detectFamily(filename);
    final isVision = GgufModel.detectVision(filename);
    
    // Attempt basic quantization extraction from filename e.g. "q4_k_m" or "Q4_K_M"
    String quantization = "Q4_K_M (Assumed)";
    final quantRegex = RegExp(r'[qQ]\d+_[kK_a-zA-Z\d_]+');
    final match = quantRegex.firstMatch(filename);
    if (match != null) {
      quantization = match.group(0)!.toUpperCase();
    }

    final model = GgufModel(
      id: const Uuid().v4(),
      name: filename.replaceAll('.gguf', '').replaceAll('_', ' '),
      path: path,
      sizeBytes: sizeBytes,
      family: family,
      quantization: quantization,
      isVision: isVision,
    );

    // Save to list and update local JSON DB
    _models.removeWhere((m) => m.path == path);
    _models.add(model);
    await _saveDatabase();

    return model;
  }

  /// Remove imported GGUF model from device local storage to reclaim RAM/disk space
  Future<void> deleteModel(GgufModel model) async {
    final file = File(model.path);
    if (await file.exists()) {
      await file.delete();
    }

    _models.removeWhere((m) => m.id == model.id);
    await _saveDatabase();
  }

  Future<void> _loadDatabase() async {
    if (!await _databaseFile.exists()) return;

    try {
      final jsonStr = await _databaseFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      _models.clear();
      for (var item in jsonList) {
        // Double-check file actually still exists inside sandbox before listing
        final file = File(item['path']);
        if (await file.exists()) {
          _models.add(GgufModel(
            id: item['id'],
            name: item['name'],
            path: item['path'],
            sizeBytes: item['sizeBytes'],
            family: ModelFamily.values.firstWhere(
              (f) => f.toString() == item['family'],
              orElse: () => ModelFamily.unknown,
            ),
            quantization: item['quantization'],
            isVision: item['isVision'] ?? false,
          ));
        }
      }
    } catch (e) {
      // Database corrupted or empty, reset
      stderr.writeln("Failed to load models database: $e");
    }
  }

  /// Download model from URL directly into the sandbox
  Future<GgufModel> downloadModel({
    required String url,
    required String filename,
    Function(double progress)? onProgress,
  }) async {
    final targetPath = p.join(_modelsDir.path, filename);
    final targetFile = File(targetPath);

    // If already exists, return registered model
    if (await targetFile.exists()) {
      final sizeBytes = await targetFile.length();
      return _registerModel(filename, targetPath, sizeBytes);
    }

    final client = HttpClient();
    // Configure longer timeout for big GGUF files
    client.connectionTimeout = const Duration(seconds: 45);
    
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception("Download failed with HTTP ${response.statusCode}");
    }

    final sizeBytes = response.contentLength;
    final iosSink = targetFile.openWrite(mode: FileMode.write);
    int downloadedBytes = 0;

    try {
      await for (final chunk in response) {
        iosSink.add(chunk);
        downloadedBytes += chunk.length;
        if (onProgress != null && sizeBytes > 0) {
          onProgress(downloadedBytes / sizeBytes);
        }
      }
    } catch (e) {
      await iosSink.close();
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      rethrow;
    }

    await iosSink.close();
    return _registerModel(filename, targetPath, downloadedBytes);
  }

  Future<void> _saveDatabase() async {
    final list = _models.map((m) => {
      'id': m.id,
      'name': m.name,
      'path': m.path,
      'sizeBytes': m.sizeBytes,
      'family': m.family.toString(),
      'quantization': m.quantization,
      'isVision': m.isVision,
    }).toList();

    await _databaseFile.writeAsString(jsonEncode(list));
  }
}
