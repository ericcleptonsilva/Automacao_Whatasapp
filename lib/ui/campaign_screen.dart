import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../repositories/contact_repository.dart';
import '../services/native_service.dart';
import '../services/meta_api_service.dart';
import '../repositories/campaign_repository.dart';
import '../models/campaign_log.dart';
import '../repositories/auto_reply_repository.dart';
import '../services/logger_service.dart';
import '../ui/campaign_history_screen.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  final ContactRepository _repository = ContactRepository();
  List<Contact> _contacts = [];
  List<Contact> _selectedContacts = [];
  bool _isLoading = true;
  bool _isSending = false;

  final CampaignRepository _campaignRepository = CampaignRepository();
  final AutoReplyRepository _autoReplyRepository = AutoReplyRepository();

  String _activeAiProvider = 'Carregando...';
  String _activeAiModel = '';

  final TextEditingController _messageController = TextEditingController();
  int _delaySeconds = 5;
  String? _selectedFilePath;
  bool _isImage = true;
  Set<String> _allTags = {};
  String? _selectedTagFilter;
  bool? _prefixFilter; // null = all, true = with 55, false = without 55

  // Showcase Keys
  final GlobalKey _keyApiToggle = GlobalKey();
  final GlobalKey _keyMsgField = GlobalKey();
  final GlobalKey _keyDelay = GlobalKey();
  final GlobalKey _keyStartBtn = GlobalKey();
  final GlobalKey _keyFilters = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTourIfNeeded());
  }

  Future<void> _startTourIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch_campaign_tour') ?? true;
    if (isFirstLaunch && mounted) {
      ShowcaseView.get().startShowCase([
        _keyApiToggle,
        _keyMsgField,
        _keyDelay,
        _keyStartBtn,
        _keyFilters,
      ]);
      await prefs.setBool('first_launch_campaign_tour', false);
    }
  }

  void _manualTour() {
    ShowcaseView.get().startShowCase([
      _keyApiToggle,
      _keyMsgField,
      _keyDelay,
      _keyStartBtn,
      _keyFilters,
    ]);
  }

  Future<void> _loadInitialData() async {
    final draft = await _campaignRepository.getDraft();
    final provider = await _autoReplyRepository.getAiProvider();
    final model = await _autoReplyRepository.getAiModel();
    final isAiEnabled = await _autoReplyRepository.isAiEnabled();

    if (mounted) {
      setState(() {
        if (draft != null) {
          _messageController.text = draft;
        }
        _activeAiProvider = isAiEnabled ? provider : 'Desativada';
        _activeAiModel = isAiEnabled ? model : '';
      });
    }
  }

  Future<void> _saveDraft() async {
    await _campaignRepository.saveDraft(_messageController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rascunho salvo com sucesso!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final contacts = await _repository.getContacts();

    final tags = <String>{};
    for (var c in contacts) {
      if (c.tags.isNotEmpty) {
        tags.addAll(c.tags);
      }
    }

    setState(() {
      _contacts = contacts;
      _allTags = tags;
      _isLoading = false;
    });
  }

  void _selectByFilter() {
    setState(() {
      _selectedContacts.clear();
      for (var contact in _contacts) {
        bool matchTag =
            _selectedTagFilter == null ||
            contact.tags.contains(_selectedTagFilter);
        bool matchPrefix =
            _prefixFilter == null ||
            (_prefixFilter == true && contact.phone.startsWith('55')) ||
            (_prefixFilter == false && !contact.phone.startsWith('55'));

        if (matchTag && matchPrefix) {
          _selectedContacts.add(contact);
        }
      }
    });
  }

  // Removed unused attachment methods as per user request to focus on text
  
  bool _useOfficialApi = false;
  final MetaApiService _apiService = MetaApiService();

  Future<void> _startCampaign() async {
    if (_selectedContacts.isEmpty ||
        (_messageController.text.isEmpty && _selectedFilePath == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione contatos e digite uma mensagem ou escolha um arquivo',
          ),
        ),
      );
      return;
    }

    // Countdown Dialog
    bool shouldStart =
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            int timeLeft = 5;
            return StatefulBuilder(
              builder: (context, setState) {
                // Start timer only once
                if (timeLeft == 5) {
                  Future.doWhile(() async {
                    await Future.delayed(const Duration(seconds: 1));
                    if (!context.mounted) return false;
                    setState(() => timeLeft--);
                    if (timeLeft <= 0) {
                      Navigator.of(context).pop(true);
                      return false;
                    }
                    return true;
                  });
                }

                return AlertDialog(
                  title: const Text("Iniciando Campanha..."),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        "Envio começa em $timeLeft segundos",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        "CANCELAR",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!shouldStart) return;

    // Save campaign message for AI context
    await CampaignRepository().saveCampaignMessage(_messageController.text);

    setState(() => _isSending = true);

    for (int i = 0; i < _selectedContacts.length; i++) {
      if (!mounted) break;
      final contact = _selectedContacts[i];

      // Personalize message
      String message = _messageController.text
          .replaceAll('{name}', contact.name)
          .replaceAll('{phone}', contact.phone)
          .replaceAll('{first_name}', contact.name.split(' ').first);

      bool success = false;

      if (_useOfficialApi) {
        // Meta Cloud API
        // Note: Currently supports text only for MVP
        if (_selectedFilePath != null) {
          LoggerService.log("File sending via API not implemented yet");
        }
        success = await _apiService.sendMessage(
          to: contact.phone,
          message: message,
        );
      } else {
        // Native Automation
        // Check if we are sending file or just text
        if (_selectedFilePath != null) {
          await NativeService().sendFile(
            contact.phone,
            _selectedFilePath!,
            message,
            isImage: _isImage,
          );
          success =
              true; // Assuming success as we can't fully track native intent
        } else {
          // Native Automation with auto-click support
          await NativeService().sendText(contact.phone, message);
          success = true;
        }
      }

      if (!success && _useOfficialApi && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Falha ao enviar para ${contact.name} via API"),
          ),
        );
      }

      await Future.delayed(Duration(seconds: _delaySeconds + 2));
    }

    // NEW: Save to History
    try {
      final log = CampaignLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: _messageController.text,
        contacts: List.from(_selectedContacts),
        timestamp: DateTime.now(),
      );
      await CampaignRepository().addLog(log);
    } catch (e) {
      LoggerService.log("Error saving campaign log: $e");
    }

    if (mounted) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campanha Finalizada e Salva no Histórico!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Nova Campanha'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Tutorial',
                  onPressed: _manualTour,
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Histórico',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CampaignHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Showcase(
                      key: _keyApiToggle,
                      title: "API Oficial vs Nativa",
                      description:
                          "Alterna entre a API Oficial (Nuvem) e a Automação Nativa (por acessibilidade).",
                      child: SwitchListTile(
                        title: const Text("Usar API Oficial (Meta)"),
                        subtitle: const Text(
                          "Envia em background sem abrir o WhatsApp",
                        ),
                        value: _useOfficialApi,
                        onChanged: (val) =>
                            setState(() => _useOfficialApi = val),
                      ),
                    ),
                    Showcase(
                      key: _keyMsgField,
                      title: "Sua Mensagem",
                      description:
                          "Digite aqui sua mensagem. Use {name} para personalizar com o nome do contato automaticamente.",
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Modelo de Mensagem',
                          hintText: 'Olá {first_name}, confira esta oferta!',
                          helperText:
                              "Variáveis: {name}, {first_name}, {phone}",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.text_fields),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.save_outlined),
                            tooltip: 'Salvar Rascunho',
                            onPressed: _saveDraft,
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                "I.A. Ativa: $_activeAiProvider ${_activeAiModel.isNotEmpty ? '($_activeAiModel)' : ''}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Text("Intervalo (seg): "),
                        Showcase(
                          key: _keyDelay,
                          title: "Evite Banimentos",
                          description:
                              "Intervalo em segundos entre cada envio. Recomendamos pelo menos 5-10 segundos.",
                          child: SizedBox(
                            width: 60,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _delaySeconds = int.tryParse(val) ?? 5;
                                });
                              },
                              controller: TextEditingController(
                                text: _delaySeconds.toString(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Showcase(
                            key: _keyStartBtn,
                            title: "Mãos à obra",
                            description:
                                "Clique aqui para começar o processo de envio para os contatos selecionados.",
                            child: FilledButton.icon(
                              onPressed: _isSending ? null : _startCampaign,
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              label: Text(
                                _isSending ? "Enviando..." : "Iniciar Campanha",
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Filtrar e Selecionar",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text("Todos"),
                            selected:
                                _selectedTagFilter == null &&
                                _prefixFilter == null,
                            onSelected: (val) {
                              setState(() {
                                _selectedTagFilter = null;
                                _prefixFilter = null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text("Com 55 🇧🇷"),
                            selected: _prefixFilter == true,
                            onSelected: (val) {
                              setState(() {
                                _prefixFilter = val ? true : null;
                                _selectByFilter();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text("Sem 55 ⚠️"),
                            selected: _prefixFilter == false,
                            onSelected: (val) {
                              setState(() {
                                _prefixFilter = val ? false : null;
                                _selectByFilter();
                              });
                            },
                          ),
                          if (_allTags.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(
                                height: 30,
                                child: VerticalDivider(),
                              ),
                            ),
                            ..._allTags.map(
                              (tag) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(tag),
                                  selected: _selectedTagFilter == tag,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedTagFilter = val ? tag : null;
                                      _selectByFilter();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Contatos (${_selectedContacts.length}/${_contacts.length})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedContacts.length ==
                                  _contacts.length) {
                                _selectedContacts.clear();
                              } else {
                                _selectedContacts = List.from(_contacts);
                              }
                            });
                          },
                          child: Text(
                            _selectedContacts.length == _contacts.length
                                ? "Desmarcar Todos"
                                : "Selecionar Todos",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_contacts.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text("Nenhum contato disponível.")),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final contact = _contacts[index];
                  final isSelected = _selectedContacts.contains(contact);
                  return CheckboxListTile(
                    title: Text(contact.name),
                    subtitle: Text(contact.phone),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedContacts.add(contact);
                        } else {
                          _selectedContacts.remove(contact);
                        }
                      });
                    },
                  );
                }, childCount: _contacts.length),
              ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 80),
            ), // Extra padding for bottom
          ],
        ),
      ),
    );
  }
}
