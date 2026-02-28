import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger_service.dart';

class NotificationRepository {
  static const String _keyLogs = 'notification_logs';
  static const int _maxLogs = 50; // Limit to 50 logs to avoid performance issues

  Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? logsJson = prefs.getString(_keyLogs);
    if (logsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(logsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      LoggerService.log("Error decoding logs: $e");
      return [];
    }
  }

  Future<void> saveLog(Map<String, dynamic> log) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> logs = await getLogs();

    // Add timestamp if not present
    if (!log.containsKey('timestamp')) {
        log['timestamp'] = DateTime.now().toIso8601String();
    }

    logs.insert(0, log); // Add to top

    if (logs.length > _maxLogs) {
      logs = logs.sublist(0, _maxLogs);
    }

    final String encoded = jsonEncode(logs);
    await prefs.setString(_keyLogs, encoded);
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLogs);
  }
}
