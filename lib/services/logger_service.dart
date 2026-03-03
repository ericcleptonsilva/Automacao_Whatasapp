import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static const String _fileName = 'app_logs.txt';

  // Gets the persistence file securely
  static Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Logs a message with timestamp to the file
  static Future<void> log(String message) async {
    try {
      final file = await _localFile;
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] $message\n';

      // Append to file, create if it doesn't exist
      await file.writeAsString(logMessage, mode: FileMode.append);

      // Print to console normally for dev
      debugPrint("LoggerService: $message");
    } catch (e) {
      debugPrint("LoggerService: Failed to write log - $e");
    }
  }

  // Reads the entire log file manually (if needed)
  static Future<String> readLogs() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
      return "No logs available yet.";
    } catch (e) {
      return "Error reading logs: $e";
    }
  }

  // Prepares the path to export externally (e.g for share_plus)
  static Future<String?> getLogFilePath() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        return file.path;
      }
      return null; // Return null if file hasn't been created yet
    } catch (e) {
      debugPrint("LoggerService: Error getting path - $e");
      return null;
    }
  }

  // Empties the file contents to not flood user memory
  static Future<void> clearLogs() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.writeAsString(''); // Overwrite with empty
      }
    } catch (e) {
      debugPrint("LoggerService: Error clearing logs - $e");
    }
  }
}
