import 'dart:async';
// Add this for kIsWeb
import 'package:flutter/services.dart';
import '../services/logger_service.dart';
import '../repositories/notification_repository.dart';


class NativeService {
  static const platform = MethodChannel('com.clept.whatsappautomation/channel');
  
  static final NativeService _instance = NativeService._internal();
  factory NativeService() => _instance;

  final _notificationStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;

  NativeService._internal() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  DateTime? _lastNotificationTime;
  Map<String, dynamic>? _lastNotificationData;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == "onNotification") {
      try {
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        
        // Simple deduplication logic
        final now = DateTime.now();
        if (_lastNotificationData != null && 
            _lastNotificationTime != null &&
            now.difference(_lastNotificationTime!) < const Duration(seconds: 2)) {
          
          final lastTitle = _lastNotificationData!['title'];
          final lastMessage = _lastNotificationData!['message'];
          final newTitle = data['title'];
          final newMessage = data['message'];

          if (lastTitle == newTitle && lastMessage == newMessage) {
            LoggerService.log("NativeService: Ignoring duplicate notification: $newTitle - $newMessage");
            return;
          }
        }

        _lastNotificationData = data;
        _lastNotificationTime = now;
        
        // Add timestamp
        if (!data.containsKey('timestamp')) {
          data['timestamp'] = now.toIso8601String();
        }

        // Save to persistent storage
        NotificationRepository().saveLog(data);
        
        _notificationStreamController.add(data);
      } catch (e) {
        LoggerService.log("Error processing notification data: $e");
      }
    }
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool result = await platform.invokeMethod('isAccessibilityServiceEnabled');
      return result;
    } on PlatformException catch (e) {
      LoggerService.log("Failed to check accessibility status: '${e.message}'.");
      return false;
    }
  }

  Future<bool> isNotificationListenerEnabled() async {
    try {
      final bool result = await platform.invokeMethod('isNotificationListenerEnabled');
      return result;
    } on PlatformException catch (e) {
      LoggerService.log("Failed to check notification status: '${e.message}'.");
      return false;
    }
  }

  Future<void> sendFile(String phone, String filePath, String message, {bool isImage = true}) async {
    try {
      await platform.invokeMethod('sendFile', {
        'phone': phone,
        'filePath': filePath,
        'message': message,
        'isImage': isImage, 
      });
    } on PlatformException catch (e) {
      LoggerService.log("Failed to send file: '${e.message}'.");
    }
  }
  
  Future<void> sendText(String phone, String message) async {
    try {
      await platform.invokeMethod('sendText', {
        'phone': phone,
        'message': message,
      });
    } on PlatformException catch (e) {
      LoggerService.log("Failed to send text: '${e.message}'.");
    }
  }

  Future<bool> replyToNotification(String title, String message, {String? replyKey}) async {
    try {
      final bool result = await platform.invokeMethod('replyToNotification', {
        'title': title,
        'message': message,
        'replyKey': replyKey,
      });
      return result;
    } on PlatformException catch (e) {
      LoggerService.log("Failed to reply: '${e.message}'.");
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      LoggerService.log("Failed to open settings: '${e.message}'.");
    }
  }

  Future<void> openNotificationListenerSettings() async {
    try {
      await platform.invokeMethod('openNotificationListenerSettings');
    } on PlatformException catch (e) {
      LoggerService.log("Failed to open settings: '${e.message}'.");
    }
  }

  Future<void> openAppSettings() async {
    try {
      await platform.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      LoggerService.log("Failed to open settings: '${e.message}'.");
    }
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await platform.invokeMethod('isIgnoringBatteryOptimizations');
    } catch (e) {
      return false;
    }
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      LoggerService.log("Error requesting battery optimization: $e");
    }
  }

  Future<bool> toggleAutomation({bool? enabled}) async {
    try {
      return await platform.invokeMethod('toggleAutomation', {'enabled': enabled});
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAutomationEnabled() async {
    try {
      return await platform.invokeMethod('isAutomationEnabled');
    } catch (e) {
      return true;
    }
  }

  Future<void> showFloatingButton() async {
    try {
      await platform.invokeMethod('showFloatingButton');
    } catch (e) {
      LoggerService.log("Error showing floating button: $e");
    }
  }

  Future<void> hideFloatingButton() async {
    try {
      await platform.invokeMethod('hideFloatingButton');
    } catch (e) {
      LoggerService.log("Error hiding floating button: $e");
    }
  }
}
