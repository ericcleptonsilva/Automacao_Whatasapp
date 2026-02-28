import 'package:flutter/material.dart';
import '../services/native_service.dart';
import '../repositories/notification_repository.dart';

class NotificationLogScreen extends StatefulWidget {
  const NotificationLogScreen({super.key});

  @override
  State<NotificationLogScreen> createState() => _NotificationLogScreenState();
}

class _NotificationLogScreenState extends State<NotificationLogScreen> {
  final List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    
    NativeService().notificationStream.listen((data) {
      if (mounted) {
        setState(() {
          _logs.insert(0, data); // Add to top
        });
      }
    });
  }

  Future<void> _loadLogs() async {
    final savedLogs = await NotificationRepository().getLogs();
    if (mounted) {
      setState(() {
        _logs.addAll(savedLogs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Notificações')),
      body: _logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aguardando notificações...', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Certifique-se de que a permissão está ativada.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: const Icon(Icons.message, color: Colors.white),
                    ),
                    title: Text(log['title'] ?? 'Desconhecido'),
                    subtitle: Text(log['message'] ?? 'Sem conteúdo'),
                    trailing: Text(
                      _formatTime(log['timestamp']),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}
