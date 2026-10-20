import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/gguf_model.dart';

class ModelManager extends ChangeNotifier {
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
    await refreshModels();
  }

  /// Reload database and auto-discover any GGUF models currently on disk
  Future<void> refreshModels() async {
    final Map<String, Map<String, dynamic>> savedMeta = {};

    if (await _databaseFile.exists()) {
      try {
        final jsonStr = await _databaseFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        for (var item in jsonList) {
          final fname = item['filename'] as String? ?? p.basename(item['path'] as String);
          savedMeta[fname] = item as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint("[ModelManager] Warning loading database: $e");
      }
    }

    _models.clear();

    // Reconcile with actual files present inside the sandbox models directory
    if (await _modelsDir.exists()) {
      final entities = _modelsDir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.gguf')) {
          final fname = p.basename(entity.path);
          final sizeBytes = entity.lengthSync();

          // If size is 0 (corrupt/aborted download), remove it
          if (sizeBytes < 1024) {
            try {
              entity.deleteSync();
            } catch (_) {}
            continue;
          }

          final meta = savedMeta[fname];
          if (meta != null) {
            _models.add(GgufModel(
              id: meta['id'] as String? ?? const Uuid().v4(),
              name: meta['name'] as String? ?? _deriveModelName(fname),
              path: entity.path,
              sizeBytes: sizeBytes,
              family: ModelFamily.values.firstWhere(
                (f) => f.toString() == meta['family'],
                orElse: () => GgufModel.detectFamily(fname),
              ),
              quantization: meta['quantization'] as String? ?? _deriveQuantization(fname),
              isVision: meta['isVision'] as bool? ?? GgufModel.detectVision(fname),
            ));
          } else {
            // Auto-discovered new model placed in folder
            _models.add(GgufModel(
              id: const Uuid().v4(),
              name: _deriveModelName(fname),
              path: entity.path,
              sizeBytes: sizeBytes,
              family: GgufModel.detectFamily(fname),
              quantization: _deriveQuantization(fname),
              isVision: GgufModel.detectVision(fname),
            ));
          }
        }
      }
    }

    await _saveDatabase();
    notifyListeners();
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
    final rawFilename = p.basename(selectedPath);

    // Enforce GGUF extensions
    if (!rawFilename.toLowerCase().endsWith('.gguf')) {
      throw Exception("Invalid File: The selected model is not a valid GGUF file. Please import a file ending in '.gguf'.");
    }

    final sizeBytes = await file.length();
    String safeFilename = rawFilename;

    // Avoid collision with existing models
    safeFilename = _getUniqueFilename(safeFilename);

    final targetPath = p.join(_modelsDir.path, safeFilename);
    final targetFile = File(targetPath);

    // High-speed block copy with progress indicator
    final iosSink = targetFile.openWrite(mode: FileMode.write);
    final srcStream = file.openRead();
    int copiedBytes = 0;

    await for (final chunk in srcStream) {
      iosSink.add(chunk);
      copiedBytes += chunk.length;
      if (onProgress != null && sizeBytes > 0) {
        onProgress(copiedBytes / sizeBytes);
      }
    }

    await iosSink.close();
    return _registerModel(safeFilename, targetPath, sizeBytes);
  }

  /// Download model from URL directly into the sandbox.
  /// Follows HTTP redirects automatically and ensures unique filenames so models never overwrite.
  Future<GgufModel> downloadModel({
    required String url,
    required String filename,
    bool? isVision,
    Function(double progress)? onProgress,
  }) async {
    final baseFilename = p.basename(filename);
    final existingModel = _models.firstWhere(
      (m) => p.basename(m.path) == baseFilename,
      orElse: () => GgufModel(
        id: '',
        name: '',
        path: '',
        sizeBytes: 0,
        family: ModelFamily.unknown,
        quantization: '',
      ),
    );

    // If an identical model file already exists and has size > 1MB, reuse it
    if (existingModel.id.isNotEmpty && existingModel.sizeBytes > 1024 * 1024) {
      final existingFile = File(existingModel.path);
      if (await existingFile.exists()) {
        return existingModel;
      }
    }

    // Determine unique non-colliding filename for this download
    final safeFilename = _getUniqueFilename(baseFilename);
    final targetPath = p.join(_modelsDir.path, safeFilename);
    final targetFile = File(targetPath);

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 45);

    final request = await client.getUrl(Uri.parse(url))
      ..maxRedirects = 8
      ..followRedirects = true;
    final response = await request.close();

    if (response.statusCode != 200) {
      client.close();
      throw Exception("Download failed with HTTP ${response.statusCode}");
    }

    final contentLength = response.contentLength;
    final knownSize = contentLength > 0;

    final iosSink = targetFile.openWrite(mode: FileMode.write);
    int downloadedBytes = 0;

    try {
      await for (final chunk in response) {
        iosSink.add(chunk);
        downloadedBytes += chunk.length;
        if (onProgress != null && knownSize) {
          onProgress(downloadedBytes / contentLength);
        }
      }
    } catch (e) {
      await iosSink.close();
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      client.close();
      rethrow;
    }

    await iosSink.close();
    client.close();

    final finalSize = knownSize ? contentLength : downloadedBytes;
    return _registerModel(safeFilename, targetPath, finalSize, isVisionOverride: isVision);
  }

  /// Remove imported GGUF model from device local storage to reclaim RAM/disk space
  Future<void> deleteModel(GgufModel model) async {
    final file = File(model.path);
    if (await file.exists()) {
      await file.delete();
    }

    _models.removeWhere((m) => m.id == model.id || m.path == model.path);
    await _saveDatabase();
    notifyListeners();
  }

  Future<GgufModel> _registerModel(String filename, String path, int sizeBytes, {bool? isVisionOverride}) async {
    final family = GgufModel.detectFamily(filename);
    final isVision = isVisionOverride ?? GgufModel.detectVision(filename);
    final quantization = _deriveQuantization(filename);
    final name = _deriveModelName(filename);

    final model = GgufModel(
      id: const Uuid().v4(),
      name: name,
      path: path,
      sizeBytes: sizeBytes,
      family: family,
      quantization: quantization,
      isVision: isVision,
    );

    _models.removeWhere((m) => m.path == path);
    _models.add(model);
    await _saveDatabase();
    notifyListeners();

    return model;
  }

  String _getUniqueFilename(String desiredFilename) {
    String testName = desiredFilename;
    final ext = p.extension(desiredFilename);
    final stem = p.basenameWithoutExtension(desiredFilename);
    int counter = 1;

    while (File(p.join(_modelsDir.path, testName)).exists() &&
           _models.any((m) => p.basename(m.path) == testName)) {
      testName = "${stem}_$counter$ext";
      counter++;
    }
    return testName;
  }

  static String _deriveModelName(String filename) {
    return filename
        .replaceAll(RegExp(r'\.gguf$', caseSensitive: false), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
  }

  static String _deriveQuantization(String filename) {
    final quantRegex = RegExp(r'[qQ]\d+_[kK_a-zA-Z\d_]+');
    final match = quantRegex.firstMatch(filename);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }
    return "Q4_K_M (Default)";
  }

  Future<void> _saveDatabase() async {
    final list = _models.map((m) => {
      'id': m.id,
      'name': m.name,
      'filename': p.basename(m.path),
      'path': m.path,
      'sizeBytes': m.sizeBytes,
      'family': m.family.toString(),
      'quantization': m.quantization,
      'isVision': m.isVision,
    }).toList();

    await _databaseFile.writeAsString(jsonEncode(list), flush: true);
  }
}
