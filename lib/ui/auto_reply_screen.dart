import 'package:flutter/material.dart';
import '../repositories/auto_reply_repository.dart';
import '../models/auto_reply_rule.dart';
import '../services/ai_service.dart';
import '../services/native_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/logger_service.dart';

class AutoReplyScreen extends StatefulWidget {
  const AutoReplyScreen({super.key});

  @override
  State<AutoReplyScreen> createState() => _AutoReplyScreenState();
}

class _AutoReplyScreenState extends State<AutoReplyScreen> {
  final AutoReplyRepository _repository = AutoReplyRepository();
  bool _isAbsenceEnabled = false;
  final TextEditingController _absenceMessageController = TextEditingController();
  bool _isFloatingButtonEnabled = false;
  
  // AI State
  bool _isAiEnabled = false;
  String _aiProvider = 'Gemini';
  String _aiModel = 'gemini-2.0-flash';
  final TextEditingController _aiPromptController = TextEditingController();

  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _claudeKeyController = TextEditingController();
  final TextEditingController _deepSeekKeyController = TextEditingController();
  final TextEditingController _groqKeyController = TextEditingController();
  final TextEditingController _mistralKeyController = TextEditingController();
  final TextEditingController _openRouterKeyController = TextEditingController();
  
  int _replyDelay = 3;
  int _debounceDelay = 4;
  bool _simulateTyping = false;

  List<AutoReplyRule> _rules = [];
  bool _isLoading = true;

  Future<void> _testAIConnection() async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final aiService = AIService();
      final response = await aiService.generateReply("Olá, isto é um teste de conexão.");
      
      if (mounted) Navigator.pop(context); // Close loading

      if (!mounted) return;
      if (!mounted) return;
      if (response != null && response.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Sucesso!"),
            content: Text("A I.A. respondeu:\n\n\"$response\""),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("Falha: A I.A. não retornou resposta. Verifique a chave e o provedor.")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text("Erro Crítico: $e")));
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link da API')),
        );
      }
    }
  }

  Future<void> _exportLogs() async {
    final path = await LoggerService.getLogFilePath();
    if (path != null) {
      await Share.shareXFiles([XFile(path)], text: 'Logs de Diagnóstico de Erros - Bot WhatsApp');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum log para exportar ainda.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _absenceMessageController.dispose();
    _geminiKeyController.dispose();
    _claudeKeyController.dispose();
    _deepSeekKeyController.dispose();
    _groqKeyController.dispose();
    _mistralKeyController.dispose();
    _openRouterKeyController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final enabled = await _repository.isAutoReplyEnabled();
    final message = await _repository.getAutoReplyMessage();
    final rules = await _repository.getRules();
    
    final aiEnabled = await _repository.isAiEnabled();
    final aiPrompt = await _repository.getAiPrompt();
    var aiModel = await _repository.getAiModel();
    await _repository.getAiProvider();
    
    final geminiKey = await _repository.getAiApiKey() ?? '';
    final claudeKey = await _repository.getClaudeKey() ?? '';
    final deepSeekKey = await _repository.getDeepSeekKey() ?? '';
    final groqKey = await _repository.getGroqKey() ?? '';
    final mistralKey = await _repository.getMistralKey() ?? '';
      String openRouterKey = await _repository.getOpenRouterKey() ?? '';

      // Auto-Migration for decommissioned models
      if (aiModel == 'llama3-8b-8192') aiModel = 'llama-3.1-8b-instant';
      if (aiModel == 'google/gemini-2.0-flash-lite-preview-02-05:free' || aiModel == 'google/gemini-2.0-flash-lite-preview') {
         aiModel = _aiProvider == 'OpenRouter' 
             ? 'google/gemini-2.0-flash-exp:free' 
             : 'gemini-2.0-flash-lite-preview';
      }
      // Outro fallback preventivo para migração desordenada previa
      if (_aiProvider == 'Gemini' && aiModel == 'google/gemini-2.0-flash-exp:free') {
         aiModel = 'gemini-2.0-flash-exp';
      }
    final replyDelay = await _repository.getReplyDelay();
    final debounceDelay = await _repository.getDebounceDelay();
    final simulateTyping = await _repository.isSimulateTypingEnabled();
    final floatingEnabled = await _repository.isFloatingButtonEnabled();

    setState(() {
      _isAbsenceEnabled = enabled;
      _absenceMessageController.text = message;
      _rules = rules;
      
      _isAiEnabled = aiEnabled;
      _aiPromptController.text = aiPrompt;
      _aiModel = aiModel;

      _geminiKeyController.text = geminiKey;
      _claudeKeyController.text = claudeKey;
      _deepSeekKeyController.text = deepSeekKey;
      _groqKeyController.text = groqKey;
      _mistralKeyController.text = mistralKey;
      _openRouterKeyController.text = openRouterKey;

      _replyDelay = replyDelay;
      _debounceDelay = debounceDelay;
      _simulateTyping = simulateTyping;
      _isFloatingButtonEnabled = floatingEnabled;

      _isLoading = false;
    });
  }
  Future<void> _saveAbsenceSettings() async {
    await _repository.setAutoReplyEnabled(_isAbsenceEnabled);
    await _repository.setAutoReplyMessage(_absenceMessageController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configurações de Ausência salvas!")));
  }

  Future<void> _saveAiSettings() async {
    await _repository.setAiEnabled(_isAiEnabled);
    await _repository.setAiPrompt(_aiPromptController.text);
    await _repository.setAiModel(_aiModel);
    await _repository.setAiProvider(_aiProvider);
    await _repository.setAiApiKey(_geminiKeyController.text);
    await _repository.setClaudeKey(_claudeKeyController.text);
    await _repository.setDeepSeekKey(_deepSeekKeyController.text);
    await _repository.setGroqKey(_groqKeyController.text);
    await _repository.setMistralKey(_mistralKeyController.text);
    await _repository.setOpenRouterKey(_openRouterKeyController.text);

    await _repository.setReplyDelay(_replyDelay);
    await _repository.setSimulateTypingEnabled(_simulateTyping);
    await _repository.setReplyDelay(_replyDelay);
    await _repository.setSimulateTypingEnabled(_simulateTyping);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Configurações salvas e aplicadas em tempo real!"),
          duration: Duration(seconds: 3),
        )
      );
    }
  }

  Future<void> _saveAllSettings() async {
    await _saveAbsenceSettings();
    await _saveAiSettings();
    await _repository.saveRules(_rules);
  }

  Future<void> _toggleFloatingButton(bool enabled) async {
    if (enabled) {
      if (!await Permission.systemAlertWindow.isGranted) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Permissão Necessária"),
              content: const Text("O botão flutuante requer a permissão 'Sobrepor a outros apps' para aparecer em cima do WhatsApp. Você será redirecionado para a tela de configurações para habilitá-la."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Permission.systemAlertWindow.request();
                  },
                  child: const Text("Abrir Configurações")
                )
              ]
            )
          );
        }
        setState(() => _isFloatingButtonEnabled = false);
        return;
      }
      await NativeService().showFloatingButton();
    } else {
      await NativeService().hideFloatingButton();
    }

    setState(() => _isFloatingButtonEnabled = enabled);
    await _repository.setFloatingButtonEnabled(enabled);
  }

  Future<void> _addOrEditRule({AutoReplyRule? existingRule, int? index}) async {
    final keywordController = TextEditingController(text: existingRule?.keyword ?? '');
    final replyController = TextEditingController(text: existingRule?.replyMessage ?? '');
    bool isExact = existingRule?.isExactMatch ?? false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingRule == null ? 'Nova Regra' : 'Editar Regra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keywordController,
              decoration: const InputDecoration(labelText: 'Palavra-Chave'),
            ),
            TextField(
              controller: replyController,
              decoration: const InputDecoration(labelText: 'Resposta'),
              maxLines: 3,
            ),
            StatefulBuilder(builder: (context, setState) {
              return CheckboxListTile(
                title: const Text("Correspondência Exata"),
                value: isExact,
                onChanged: (val) => setState(() => isExact = val ?? false),
              );
            }),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (keywordController.text.isNotEmpty && replyController.text.isNotEmpty) {
                final newRule = AutoReplyRule(
                  keyword: keywordController.text,
                  replyMessage: replyController.text,
                  isExactMatch: isExact,
                  isActive: true,
                );
                
                setState(() {
                  if (existingRule != null && index != null) {
                    _rules[index] = newRule;
                  } else {
                    _rules.add(newRule);
                  }
                });
                _repository.saveRules(_rules);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _deleteRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
    _repository.saveRules(_rules);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regras de Automação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: "Exportar Logs de Erro",
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Salvar Tudo",
            onPressed: _saveAllSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionHeader("Modo Ausência Global"),
                SwitchListTile(
                  title: const Text("Ativar Resposta de Ausência"),
                  subtitle: const Text("Responde a qualquer mensagem recebida"),
                  value: _isAbsenceEnabled,
                  onChanged: (val) async {
                    setState(() => _isAbsenceEnabled = val);
                    await _saveAbsenceSettings();
                  },
                ),
                if (_isAbsenceEnabled) ...[
                  TextField(
                    controller: _absenceMessageController,
                    decoration: const InputDecoration(
                      labelText: "Mensagem de Ausência",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (_) => _repository.setAutoReplyMessage(_absenceMessageController.text), // Auto save on type might be too much, but OK for now or add explicit save
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: _saveAbsenceSettings, child: const Text("Salvar Mensagem")),
                ],

                const Divider(height: 40),
                _buildSectionHeader("Controle Rápido (Overlay)"),
                SwitchListTile(
                  title: const Text("Botão de Controle Flutuante"),
                  subtitle: const Text("Mostra um botão sobre o WhatsApp para ativar/desativar o bot"),
                  value: _isFloatingButtonEnabled,
                  onChanged: _toggleFloatingButton,
                ),
                if (_isFloatingButtonEnabled)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Dica: O botão fica verde quando o bot está ATIVO e vermelho quando está DESATIVADO.",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                
                const Divider(height: 40),
                _buildSectionHeader("Inteligência Artificial"),
                SwitchListTile(
                  title: const Text("Ativar I.A. (Resposta Inteligente)"),
                  subtitle: const Text("Responde quando nenhuma regra for encontrada"),
                  value: _isAiEnabled,
                  onChanged: (val) {
                    setState(() => _isAiEnabled = val);
                    _saveAiSettings();
                  },
                ),
                if (_isAiEnabled) ...[
                   // Provider Selection
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Provedor de I.A.", border: OutlineInputBorder()),
                    initialValue: _aiProvider,
                    items: const [
                      DropdownMenuItem(value: "Gemini", child: Text("Google Gemini")),
                      DropdownMenuItem(value: "Claude", child: Text("Anthropic Claude")),
                      DropdownMenuItem(value: "DeepSeek", child: Text("DeepSeek")),
                      DropdownMenuItem(value: "Groq", child: Text("Groq (Rápida)")),
                      DropdownMenuItem(value: "Mistral", child: Text("Mistral AI")),
                      DropdownMenuItem(value: "OpenRouter", child: Text("OpenRouter (Múltiplas IAs)")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _aiProvider = val ?? "Gemini";
                        // Optimized: Only reset model if the current one is not valid for the new provider
                        final validModels = _getModelsForProvider(_aiProvider).map((m) => m.value).toList();
                        if (!validModels.contains(_aiModel)) {
                          if (_aiProvider == 'Gemini') _aiModel = 'gemini-2.0-flash';
                          if (_aiProvider == 'Claude') _aiModel = 'claude-3-haiku-20240307';
                          if (_aiProvider == 'DeepSeek') _aiModel = 'deepseek-chat';
                          if (_aiProvider == 'Groq') _aiModel = 'llama-3.1-8b-instant';
                          if (_aiProvider == 'Mistral') _aiModel = 'mistral-small-latest';
                          if (_aiProvider == 'OpenRouter') _aiModel = 'google/gemini-2.0-flash-exp:free';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Dynamic API Key Field
                  if (_aiProvider == 'Gemini') ...[
                    TextField(
                      controller: _geminiKeyController,
                      decoration: const InputDecoration(labelText: "Gemini API Key", border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("Gerar API Key Grátis (Google AI Studio)"),
                        onPressed: () => _launchURL("https://aistudio.google.com/app/apikey"),
                      ),
                    ),
                  ],
                  if (_aiProvider == 'Claude') ...[
                     TextField(
                      controller: _claudeKeyController,
                      decoration: const InputDecoration(labelText: "Claude API Key", border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("Gerar API Key (Anthropic Console)"),
                        onPressed: () => _launchURL("https://console.anthropic.com/settings/keys"),
                      ),
                    ),
                  ],
                  if (_aiProvider == 'DeepSeek') ...[
                     TextField(
                      controller: _deepSeekKeyController,
                      decoration: const InputDecoration(labelText: "DeepSeek API Key", border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("Gerar API Key (DeepSeek Platform)"),
                        onPressed: () => _launchURL("https://platform.deepseek.com/api_keys"),
                      ),
                    ),
                  ],
                  if (_aiProvider == 'Groq') ...[
                    TextField(
                      controller: _groqKeyController,
                      decoration: const InputDecoration(labelText: "Groq API Key", border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("Gerar API Key Grátis (Groq Cloud)"),
                        onPressed: () => _launchURL("https://console.groq.com/keys"),
                      ),
                    ),
                  ],
                 if (_aiProvider == 'Mistral') ...[
                    TextField(
                      controller: _mistralKeyController,
                      decoration: const InputDecoration(labelText: "Mistral API Key", border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("Gerar API Key (Mistral Console)"),
                        onPressed: () => _launchURL("https://console.mistral.ai/api-keys"),
                      ),
                    ),
                 ],
                 if (_aiProvider == 'OpenRouter') ...[
                    TextField(
                      controller: _openRouterKeyController,
                      decoration: const InputDecoration(labelText: "OpenRouter API Key", border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("Gerar API Key (OpenRouter)"),
                        onPressed: () => _launchURL("https://openrouter.ai/settings/keys"),
                      ),
                    ),
                 ],
                  
                  const SizedBox(height: 10),
                  
                  // Model Selection (Dynamic)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Modelo", border: OutlineInputBorder()),
                    initialValue: _aiModel,
                    items: _getModelsForProvider(_aiProvider),
                    onChanged: (val) => setState(() => _aiModel = val!),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _aiPromptController,
                    decoration: const InputDecoration(
                      labelText: "Personalidade / Instruções",
                      border: OutlineInputBorder(),
                      hintText: "Ex: Você é um assistente útil..."
                    ),
                    maxLines: 3,
                    onChanged: (val) => _repository.setAiPrompt(val),
                  ),
                  const SizedBox(height: 10),
                  
                  // Reply Delay Slider
                  const Text("Delay de Resposta (Segundos)", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _replyDelay.toDouble(),
                          min: 0,
                          max: 60,
                          divisions: 60,
                          label: "${_replyDelay}s",
                          onChanged: (val) => setState(() => _replyDelay = val.toInt()),
                        ),
                      ),
                      Text("${_replyDelay}s", style: const TextStyle(fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Text("Esperar por mais mensagens (Agrupamento)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text("Quanto tempo o bot espera o usuário parar de digitar para responder.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _debounceDelay.toDouble(),
                          min: 1,
                          max: 15,
                          divisions: 14,
                          label: "${_debounceDelay}s",
                          onChanged: (val) => setState(() => _debounceDelay = val.toInt()),
                        ),
                      ),
                      Text("${_debounceDelay}s", style: const TextStyle(fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bolt),
                    label: const Text("TESTAR CONEXÃO I.A. AGORA"),
                    onPressed: _testAIConnection,
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  
                  SwitchListTile(
                    title: const Text("Simular Digitação no WhatsApp"),
                    subtitle: const Text("Abre o chat e simula a digitação real (mostra 'Digitando...')"),
                    value: _simulateTyping,
                    onChanged: (val) {
                      setState(() => _simulateTyping = val);
                      _repository.setSimulateTypingEnabled(val);
                    },
                  ),

                  ElevatedButton(onPressed: _saveAiSettings, child: const Text("Salvar Configurações I.A.")),
                ],

                const Divider(height: 40),
                _buildSectionHeader("Regras por Palavra-Chave"),
                if (_rules.isEmpty) 
                  const Padding(padding: EdgeInsets.all(16), child: Text("Nenhuma regra criada.", style: TextStyle(color: Colors.grey))),

                ..._rules.asMap().entries.map((entry) {
                  final index = entry.key;
                  final rule = entry.value;
                  return Card(
                    child: ListTile(
                      title: Text(rule.keyword, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(rule.replyMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _addOrEditRule(existingRule: rule, index: index)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRule(index)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditRule(),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getModelsForProvider(String provider) {
    switch (provider) {
      case 'Gemini':
        return const [
          // Gemini 2.x Series
          DropdownMenuItem(value: "gemini-2.0-flash", child: Text("Gemini 2.0 Flash (Recomendado)")),
          DropdownMenuItem(value: "gemini-2.0-flash-lite-preview", child: Text("Gemini 2.0 Flash Lite (Preview)")),
          DropdownMenuItem(value: "gemini-2.0-pro-exp-02-05", child: Text("Gemini 2.0 Pro Experimental")),
          DropdownMenuItem(value: "gemini-2.0-flash-exp", child: Text("Gemini 2.0 Flash Exp")),
          
          // Gemini 2.5 Series (Future/Preview)
          DropdownMenuItem(value: "gemini-2.5-flash", child: Text("Gemini 2.5 Flash")),
          DropdownMenuItem(value: "gemini-2.5-flash-lite", child: Text("Gemini 2.5 Flash Lite")),
          DropdownMenuItem(value: "gemini-2.5-pro", child: Text("Gemini 2.5 Pro")),
          
          // Gemini 3.x Series (Future/Preview)
          DropdownMenuItem(value: "gemini-3-flash", child: Text("Gemini 3.0 Flash")),
          DropdownMenuItem(value: "gemini-3-pro", child: Text("Gemini 3.0 Pro")),
          DropdownMenuItem(value: "gemini-3.1-pro", child: Text("Gemini 3.1 Pro")),
          
          // Gemma Series (via API)
          DropdownMenuItem(value: "gemma-3-1b-it", child: Text("Gemma 3 1B (API)")),
          DropdownMenuItem(value: "gemma-3-4b-it", child: Text("Gemma 3 4B (API)")),
          DropdownMenuItem(value: "gemma-3-12b-it", child: Text("Gemma 3 12B (API)")),
          DropdownMenuItem(value: "gemma-3-27b-it", child: Text("Gemma 3 27B (API)")),
          
          // Specialized / Preview
          DropdownMenuItem(value: "gemini-2.5-flash-preview-image", child: Text("Nano Banana (2.5 Flash Preview)")),
          DropdownMenuItem(value: "gemini-3-pro-image", child: Text("Nano Banana Pro (3.0 Pro Image)")),
          
          // Legacy/Stable
          DropdownMenuItem(value: "gemini-1.5-flash", child: Text("Gemini 1.5 Flash")),
          DropdownMenuItem(value: "gemini-1.5-pro", child: Text("Gemini 1.5 Pro")),
        ];

      case 'Claude':
        return const [
          DropdownMenuItem(value: "claude-3-haiku-20240307", child: Text("Claude 3 Haiku (Rápido)")),
          DropdownMenuItem(value: "claude-3-sonnet-20240229", child: Text("Claude 3 Sonnet (Equilibrado)")),
          DropdownMenuItem(value: "claude-3-opus-20240229", child: Text("Claude 3 Opus (Poderoso)")),
        ];
      case 'DeepSeek':
        return const [
          DropdownMenuItem(value: "deepseek-chat", child: Text("DeepSeek Chat")),
          DropdownMenuItem(value: "deepseek-reasoner", child: Text("DeepSeek Reasoner")),
        ];
        
      case 'Groq':
        return const [
          DropdownMenuItem(value: "llama-3.1-8b-instant", child: Text("Llama 3.1 8B (Meta/Rápido)")),
          DropdownMenuItem(value: "llama-3.3-70b-versatile", child: Text("Llama 3.3 70B (Meta)")),
          DropdownMenuItem(value: "mixtral-8x7b-32768", child: Text("Mixtral 8x7b (Mistral)")),
          DropdownMenuItem(value: "gemma2-9b-it", child: Text("Gemma 2 9B (Google)")),
        ];

      case 'Mistral':
        return const [
          DropdownMenuItem(value: "mistral-small-latest", child: Text("Mistral Small (Rápido/Grátis-Tier)")),
          DropdownMenuItem(value: "mistral-large-latest", child: Text("Mistral Large (Poderoso)")),
          DropdownMenuItem(value: "open-mistral-nemo", child: Text("Mistral Nemo (Forte e Leve)")),
          DropdownMenuItem(value: "open-mixtral-8x22b", child: Text("Mixtral 8x22B")),
          DropdownMenuItem(value: "codestral-latest", child: Text("Codestral (Programação)")),
        ];

      case 'OpenRouter':
        return const [
          DropdownMenuItem(value: "google/gemini-2.0-flash-exp:free", child: Text("Gemini 2.0 Flash Exp (Grátis)")),
          DropdownMenuItem(value: "deepseek/deepseek-r1:free", child: Text("DeepSeek R1 (Grátis)")),
          DropdownMenuItem(value: "mistralai/mistral-7b-instruct:free", child: Text("Mistral 7B (Grátis)")),
          DropdownMenuItem(value: "meta-llama/llama-3.1-8b-instruct:free", child: Text("Llama 3.1 8B (Grátis)")),
        ];
      default:
        return const [];
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
    );
  }
}
