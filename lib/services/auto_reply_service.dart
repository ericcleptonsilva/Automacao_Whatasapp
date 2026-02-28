import 'dart:async';
import 'ai_service.dart';
import 'native_service.dart';
import '../repositories/auto_reply_repository.dart';
import '../repositories/conversation_repository.dart';
import 'logger_service.dart';

class AutoReplyService {
  final NativeService _nativeService = NativeService();
  final AutoReplyRepository _repository = AutoReplyRepository();
  final ConversationRepository _conversationRepository = ConversationRepository();
  final AIService _aiService = AIService();
  StreamSubscription? _subscription;

  void startListening() {
    _subscription?.cancel();
    _subscription = _nativeService.notificationStream.listen(_handleNotification);
        LoggerService.log("AutoReplyService: Listening for notifications...");
  }

  void stopListening() {
    _subscription?.cancel();
        LoggerService.log("AutoReplyService: Stopped listening.");
  }

  final Map<String, DateTime> _lastReplyTime = {};
  final Set<String> _processing = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, List<String>> _messageBuffers = {};
  static const Duration _cooldown = Duration(seconds: 5);


  String _sanitizeTitle(String title) {
    // Removes "(N messages)", "(N mensagens)", or counts like "5 mensagens"
    return title
        .replaceAll(RegExp(r'\s\(\d+\s\w+\)$'), '') 
        .replaceAll(RegExp(r'^\d+\s+\w+\s'), '')
        .trim();
  }

  Future<void> _handleNotification(Map<String, dynamic> data) async {
    // ... (existing lines 25-52: title extraction, ignore checks, absence mode check)

    final String rawTitle = data['title'] ?? '';
    final String message = data['message'] ?? '';
    final String packageName = data['package'] ?? '';
    final String? replyKey = data['replyKey'] as String?;

    if (packageName != "com.whatsapp" && packageName != "com.whatsapp.w4b") return;
    
    // Check if automation is globally enabled via floating button toggle
    final bool isAutomationEnabled = await _nativeService.isAutomationEnabled();
    if (!isAutomationEnabled) {
          LoggerService.log("AutoReply: Automation is disabled via floating toggle. Ignoring notification.");
      return;
    }

    final String title = _sanitizeTitle(rawTitle);
    
    // Always save incoming message to history for context immediately
    // This ensures that even if we ignore concurrent processing, the context is there for next time
    await _conversationRepository.addMessage(title, 'user', message);

    // Ignore self-messages or system messages
    if (title.toLowerCase() == 'você' || title.toLowerCase() == 'you') {
            LoggerService.log("AutoReply: Ignoring self-message from $title");
        return;
    }

    // Ignore summary messages
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains("novas mensagens") || 
        lowerMessage.contains("new messages") ||
        RegExp(r'^\d+\s+mensagens?$').hasMatch(lowerMessage) ||
        RegExp(r'^\d+\s+messages?$').hasMatch(lowerMessage)) {
           LoggerService.log("AutoReply: Ignoring summary message: '$message'");
       return;
    }

    // Debounce/Grouping Logic:
    // If a notification comes in, we wait a bit to see if more arrive.
    // We append the message to a buffer for this title so we can process all at once.
    _messageBuffers[title] ??= [];
    _messageBuffers[title]!.add(message);

    final int debounceSeconds = await _repository.getDebounceDelay();
    final Duration debounceDelay = Duration(seconds: debounceSeconds);

    _debounceTimers[title]?.cancel();
    _debounceTimers[title] = Timer(debounceDelay, () async {
      final bufferedMessages = _messageBuffers.remove(title) ?? [message];
      final combinedMessage = bufferedMessages.join("\n");
      _debounceTimers.remove(title);
      await _processReply(title, combinedMessage, data, replyKey);
    });
    
        LoggerService.log("AutoReply: Message from $title buffered (Total: ${_messageBuffers[title]!.length}). Waiting ${debounceSeconds}s...");
  }

  Future<void> _processReply(String title, String message, Map<String, dynamic> data, String? replyKey) async {
    // Prevent concurrent processing for the same title
    if (_processing.contains(title)) {
          LoggerService.log("AutoReply: Skipping process for $title - already processing.");
      return;
    }
    
    if (_lastReplyTime.containsKey(title)) {
      final lastTime = _lastReplyTime[title]!;
      if (DateTime.now().difference(lastTime) < _cooldown) {
            LoggerService.log("AutoReply: Skipping reply to $title - Cooldown active");
        return;
      }
    }

    _processing.add(title);
    
    // Safety fallback: auto-clear processing after 60 seconds if something hangs
    final Timer safetyTimer = Timer(const Duration(seconds: 60), () {
      if (_processing.contains(title)) {
            LoggerService.log("AutoReply: Safety fallback triggered - clearing processing for $title");
        _processing.remove(title);
      }
    });

    try {
        // CORRECTION: Use the passed message (combinedMessage) instead of getting it again from data
        // This was the shadowing bug: final message = data['message'] ?? '';

        // Check Absence Mode
        final bool isAbsenceMode = await _repository.isAutoReplyEnabled();
        if (isAbsenceMode) {
            final absenceMessage = await _repository.getAutoReplyMessage();
                LoggerService.log("AutoReply: Absence Mode ON. Sending default message.");
            await _sendReply(title, absenceMessage, tag: data['tag']);
            return;
        }

        // Check Rules
        final rules = await _repository.getRules();
            LoggerService.log("AutoReply: Checking ${rules.length} rules for message: '$message'");
        
        String? replyMessage;

        for (final rule in rules) {
          bool match = false;
          final cleanMessage = message.trim().toLowerCase();
          final cleanKeyword = rule.keyword.trim().toLowerCase();
          
          if (rule.isExactMatch) {
            match = cleanMessage == cleanKeyword;
          } else {
            match = cleanMessage.contains(cleanKeyword);
          }

          if (rule.isActive && match) {
            replyMessage = rule.replyMessage;
                LoggerService.log("AutoReply: Match found! Rule: '${rule.keyword}'");
            break;
          }
        }
        
        bool isAiAttempted = false;

        // If no rule matched, check AI
        if (replyMessage == null) {
          final bool isAiEnabled = await _repository.isAiEnabled();
          if (isAiEnabled) {
              isAiAttempted = true;
                  LoggerService.log("AutoReply: No rule matched. Attempting AI reply...");
              
              // Helper to fetch history
              final history = await _conversationRepository.getHistory(title);
              
              replyMessage = await _aiService.generateReply(message, history: history);
              if (replyMessage != null) {
                    LoggerService.log("AutoReply: AI generated response.");
              }
          }
        }
        
        if (replyMessage != null) {
          if (replyMessage.startsWith("Erro")) {
                LoggerService.log("AutoReply: AI returned an error: $replyMessage. Sending fallback to client.");
            replyMessage = "Olá! Recebi sua mensagem, mas estou processando as informações com um pouco de lentidão. Por favor, aguarde um momento ou tente novamente em instantes.";
          }
              LoggerService.log("AutoReply: Reply generated. Preparing to send to $title...");
          await _sendReply(title, replyMessage, replyKey: replyKey, tag: data['tag']);
          // Save bot reply to history
          await _conversationRepository.addMessage(title, 'model', replyMessage);
        } else if (isAiAttempted) {
              LoggerService.log("AutoReply: AI was enabled but failed to generate for $title. Sending fallback.");
          final fallback = "Olá! No momento não consegui processar sua resposta automaticamente. Um atendente humano verá sua mensagem em breve.";
          await _sendReply(title, fallback, replyKey: replyKey, tag: data['tag']);
          await _conversationRepository.addMessage(title, 'model', fallback);
        } else {
              LoggerService.log("AutoReply: No rule matched, AI is disabled, Absence Mode is off. Ignoring message quietly.");
        }
    } catch (e, stack) {
            LoggerService.log("AutoReply: !!! CRITICAL ERROR !!! for $title: $e");
            LoggerService.log("AutoReply: StackTrace: ${stack.toString()}");
    } finally {
        safetyTimer.cancel();
        _processing.remove(title);
    }
  }

  Future<void> _sendReply(String title, String message, {String? replyKey, String? tag}) async {
      final int delaySeconds = await _repository.getReplyDelay();
      
          LoggerService.log("AutoReply: Replying to $title with '$message' (Delay: ${delaySeconds}s)");
      
      // Update cooldown timestamp BEFORE sending
      _lastReplyTime[title] = DateTime.now();

      // Normal wait and reply
      await Future.delayed(Duration(seconds: delaySeconds));
      final success = await _nativeService.replyToNotification(title, message, replyKey: replyKey);
      if (success) {
            LoggerService.log("AutoReply: Sent successfully.");
      } else {
            LoggerService.log("AutoReply: Failed to send.");
      }
  }
}
