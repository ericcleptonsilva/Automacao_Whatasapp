import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class LLMModelManager {
  static const String _keyModelPath = 'local_llm_model_path';
  final Dio _dio = Dio();

  Future<String?> getDownloadedModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_keyModelPath);
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  Future<void> downloadModel(
    String url, {
    required Function(double) onProgress,
    String? token,
  }) async {
    try {
      final directory = await getApplicationSupportDirectory();
      // Most models are .bin or .tflite for MediaPipe
      final filePath = "${directory.path}/local_model.bin";

      await _dio.download(
        url,
        filePath,
        options: Options(
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          },
          headers: token != null && token.isNotEmpty
              ? {"Authorization": "Bearer $token"}
              : null,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyModelPath, filePath);
    } catch (e) {
      if (e is DioException) {
        if (e.response != null &&
            (e.response!.statusCode == 401 || e.response!.statusCode == 403)) {
          LoggerService.log("LLMDownloadError: Access Denied (401/403).");
          throw Exception(
            "Acesso Negado (401/403). O Token inserido é inválido, expirou ou você não aceitou os termos no site.",
          );
        } else if (e.response != null && e.response!.statusCode == 404) {
          throw Exception(
            "Erro 404: O link não foi encontrado. Verifique se copiou a URL exata do arquivo.",
          );
        }
      }
      LoggerService.log("LLMDownloadError: $e");
      rethrow;
    }
  }

  Future<void> deleteModel() async {
    final path = await getDownloadedModelPath();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyModelPath);
    }
  }
}
