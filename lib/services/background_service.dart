import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auto_reply_service.dart';
import 'ai_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'foreground_service_channel',
    'Serviço em Segundo Plano',
    description: 'Este serviço mantém o app rodando para processar notificações.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'foreground_service_channel',
      initialNotificationTitle: 'Automação Ativa',
      initialNotificationContent: 'O app está processando notificações em segundo plano.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  AIService.isBackgroundContext = true;

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService(); // Force foreground on start
    
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Start the actual logic
  final autoReplyService = AutoReplyService();
  autoReplyService.startListening();

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Optional: Update notification content periodically
        /*
        flutterLocalNotificationsPlugin.show(
          888,
          'Automação Ativa',
          'Processando em segundo plano...',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'foreground_service_channel',
              'Serviço em Segundo Plano',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
        */
      }
    }
    // print('Background Service running...');
  });
}
