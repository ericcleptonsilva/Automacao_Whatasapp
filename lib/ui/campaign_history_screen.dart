import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/campaign_log.dart';
import '../repositories/campaign_repository.dart';

class CampaignHistoryScreen extends StatefulWidget {
  const CampaignHistoryScreen({super.key});

  @override
  State<CampaignHistoryScreen> createState() => _CampaignHistoryScreenState();
}

class _CampaignHistoryScreenState extends State<CampaignHistoryScreen> {
  final CampaignRepository _repository = CampaignRepository();
  List<CampaignLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _repository.getLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Campanhas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma campanha enviada ainda.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final dateStr = DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(log.timestamp);

                return Dismissible(
                  key: Key(log.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    await _repository.deleteLog(log.id);
                    setState(() {
                      _logs.removeAt(index);
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Campanha removida do histórico.'),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.send, size: 20),
                      ),
                      title: Text(
                        log.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$dateStr • ${log.contacts.length} contatos',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showCampaignDetails(log),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCampaignDetails(CampaignLog log) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Detalhes da Campanha',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                dateStr,
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
              const Divider(height: 32),
              const Text(
                'Mensagem:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(child: Text(log.message)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enviado para (${log.contacts.length}):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  controller: scrollController,
                  itemCount: log.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = log.contacts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 16),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
