import 'package:shared_preferences/shared_preferences.dart';

class ConversationRepository {
  // Key format: chat_history_<contactId>
  // contactId will be the sanitized title for now (e.g. "Maria")

  static const int _maxHistorySize = 10; // Keep last 10 messages

  Future<void> addMessage(String contactId, String role, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_history_$contactId';

    List<String> history = prefs.getStringList(key) ?? [];

    // Message format: "role:message"
    // role: 'user' or 'model'
    final entry = "$role:${message.replaceAll('\n', ' ')}";

    history.add(entry);

    // Trim history
    if (history.length > _maxHistorySize) {
      history = history.sublist(history.length - _maxHistorySize);
    }

    await prefs.setStringList(key, history);
  }

  Future<List<Map<String, String>>> getHistory(String contactId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_history_$contactId';
    final List<String> history = prefs.getStringList(key) ?? [];

    return history.map((e) {
      final splitIndex = e.indexOf(':');
      if (splitIndex == -1) return {'role': 'user', 'message': e};

      return {
        'role': e.substring(0, splitIndex),
        'message': e.substring(splitIndex + 1),
      };
    }).toList();
  }

  Future<void> clearHistory(String contactId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history_$contactId');
  }
}
