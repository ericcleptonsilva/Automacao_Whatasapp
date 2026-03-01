import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'logger_service.dart';
class OfflineAIService {
  final SmartReply _smartReply = SmartReply();
  
  final OnDeviceTranslator _ptToEn = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.portuguese,
    targetLanguage: TranslateLanguage.english,
  );
  
  final OnDeviceTranslator _enToPt = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.english,
    targetLanguage: TranslateLanguage.portuguese,
  );

  Future<String?> generateReply(String message, {List<Map<String, String>> history = const []}) async {
    try {
      final String messageInEn = await _ptToEn.translateText(message);
      
      for (var entry in history) {
        final rawHistoryMsg = entry['message'] ?? '';
        final translatedHistoryMsg = await _ptToEn.translateText(rawHistoryMsg);
        
        if (entry['role'] == 'user') {
          _smartReply.addMessageToConversationFromRemoteUser(
            translatedHistoryMsg, 
            DateTime.now().millisecondsSinceEpoch, 
            'remote_user'
          );
        } else {
          _smartReply.addMessageToConversationFromLocalUser(
            translatedHistoryMsg, 
            DateTime.now().millisecondsSinceEpoch
          );
        }
      }
      
      _smartReply.addMessageToConversationFromRemoteUser(
        messageInEn, 
        DateTime.now().millisecondsSinceEpoch, 
        'remote_user'
      );

      final response = await _smartReply.suggestReplies();
      LoggerService.log("OfflineAI: Smart Reply status: ${response.status}");
      
      if (response.status == SmartReplySuggestionResultStatus.success && response.suggestions.isNotEmpty) {
        final bestSuggestionInEn = response.suggestions.first;

        LoggerService.log("OfflineAI: Suggestion found (EN): $bestSuggestionInEn");
        final String replyInPt = await _enToPt.translateText(bestSuggestionInEn);
        LoggerService.log("OfflineAI: Final reply (PT): $replyInPt");
        return replyInPt;
      }
      
      if (response.status == SmartReplySuggestionResultStatus.noReply) {
        LoggerService.log("OfflineAI: No suggestion (Status: noReply)");
      } else if (response.suggestions.isEmpty) {
        LoggerService.log("OfflineAI: No suggestion (List empty)");
      }
      
      return null;
    } catch (e) {
      LoggerService.log("OfflineAI Mobile Error: $e");
      return null;
    } finally {
      LoggerService.log("OfflineAI: Clearing conversation context.");
      _smartReply.clearConversation();
    }
  }

  void dispose() {
    _smartReply.close();
    _ptToEn.close();
    _enToPt.close();
  }
}
