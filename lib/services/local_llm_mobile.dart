import 'dart:isolate';
import 'package:mediapipe_genai/mediapipe_genai.dart';
import 'package:path_provider/path_provider.dart';
import 'llm_model_manager.dart';
import 'logger_service.dart';

class LocalLLMService {
  final LLMModelManager _modelManager = LLMModelManager();
  LlmInferenceEngine? _engine;
  bool _isGenerating = false;

  bool _hasPermanentError = false;

  bool _isMainIsolate() {
    return Isolate.current.debugName == 'main' ||
        Isolate.current.debugName == null;
  }

  Future<bool> isReady() async {
    if (_hasPermanentError) return false;
    // MediaPipe often fails in background isolates due to native asset resolution issues.
    if (!_isMainIsolate()) return false;

    final path = await _modelManager.getDownloadedModelPath();
    return path != null;
  }

  Future<String?> generateReply(
    String prompt, {
    List<Map<String, String>> history = const [],
  }) async {
    if (_hasPermanentError) {
      LoggerService.log("LocalLLM: Skipping due to previous permanent error.");
      return null;
    }

    if (!_isMainIsolate()) {
      LoggerService.log(
        "LocalLLM: Skipping - MediaPipe is not supported in background isolates.",
      );
      return null;
    }

    if (_isGenerating) {
      LoggerService.log(
        "LocalLLM: Engine is currently busy generating a previous response. Skipping concurrent request to avoid MediaPipe assertion.",
      );
      return null;
    }

    try {
      _isGenerating = true;
      final modelPath = await _modelManager.getDownloadedModelPath();
      if (modelPath == null) return null;

      if (_engine == null) {
        LoggerService.log(
          "LocalLLM: Initializing engine with model: $modelPath",
        );
        try {
          final supportDir = await getApplicationSupportDirectory();
          _engine = LlmInferenceEngine(
            LlmInferenceOptions.cpu(
              modelPath: modelPath,
              cacheDir: supportDir.path,
              maxTokens: 512,
              temperature: 0.7,
              topK: 40,
            ),
          );
        } catch (e) {
          LoggerService.log(
            "LocalLLM Native Error: Failed to initialize engine. $e",
          );
          _hasPermanentError = true;
          return null;
        }
      }

      final fullPrompt = _buildFullPrompt(prompt, history);
      final responseStream = _engine!.generateResponse(fullPrompt);

      final buffer = StringBuffer();
      await for (final part in responseStream) {
        buffer.write(part);
      }

      final fullResponse = buffer.toString();
      return fullResponse.isNotEmpty ? fullResponse : null;
    } catch (e) {
      if (e is ArgumentError && e.toString().contains('native function')) {
        LoggerService.log(
          "LocalLLM Native Error (FFI): Plugin not available in this isolate. Disabling LocalLLM for this session.",
        );
        _hasPermanentError = true;
      } else {
        LoggerService.log("LocalLLM Mobile Error: $e");
      }
      _engine = null; // Reset engine on error
      return null;
    } finally {
      _isGenerating = false;
    }
  }

  String _buildFullPrompt(
    String userMessage,
    List<Map<String, String>> history,
  ) {
    final buffer = StringBuffer();
    for (var entry in history) {
      final role = entry['role'] == 'model' ? 'Assistant' : 'User';
      buffer.writeln("$role: ${entry['message']}");
    }
    buffer.writeln("User: $userMessage");
    buffer.writeln("Assistant:");
    return buffer.toString();
  }

  void dispose() {
    _engine = null;
  }
}
