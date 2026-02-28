import 'package:flutter/material.dart';
import '../services/llm_model_manager.dart';

class LLMManagementScreen extends StatefulWidget {
  const LLMManagementScreen({super.key});

  @override
  State<LLMManagementScreen> createState() => _LLMManagementScreenState();
}

class _LLMManagementScreenState extends State<LLMManagementScreen> {
  final LLMModelManager _manager = LLMModelManager();
  final TextEditingController _urlController = TextEditingController(
    text: "https://huggingface.co/litert-community/Gemma3-270M-IT/resolve/main/gemma3-270m-it-int4.task"
  );
  final TextEditingController _tokenController = TextEditingController();
  
  String? _modelPath;
  double _downloadProgress = 0;
  bool _isDownloading = false;
  String _status = "Aguardando...";

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    final path = await _manager.getDownloadedModelPath();
    if (mounted) {
      setState(() {
        _modelPath = path;
        _status = path != null ? "Modelo pronto para uso local" : "Sem modelo local baixado";
      });
    }
  }

  Future<void> _startDownload() async {
    if (_urlController.text.isEmpty) return;
    
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _status = "Iniciando download...";
    });

    try {
      await _manager.downloadModel(
        _urlController.text,
        token: _tokenController.text.trim(),
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _status = "Baixando: ${(progress * 100).toStringAsFixed(1)}%";
            });
          }
        },
      );
      await _checkModel();
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorMsg = e.toString().contains("Exception: ") 
              ? e.toString().split("Exception: ").last 
              : e.toString();
          _status = "Erro: $errorMsg";
        });
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _deleteModel() async {
    await _manager.deleteModel();
    await _checkModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("I.A. Local Avançada")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.psychology, size: 64, color: Colors.blue),
                      const SizedBox(height: 10),
                      Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_modelPath != null) ...[
                        const SizedBox(height: 10),
                        Text("Caminho: $_modelPath", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text("Remover Modelo (Liberar Espaço)"),
                          onPressed: _deleteModel,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_modelPath == null) ...[
                const Text("Download de Modelo LLM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("Selecione um preset ou insira uma URL manual:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                
                // Presets
                Row(
                  children: [
                    Expanded(
                      child: ActionChip(
                        avatar: const Icon(Icons.flash_on, size: 16),
                        label: const Text("Gemma 3 270M (Leve)"),
                        onPressed: () => setState(() => _urlController.text = "https://huggingface.co/litert-community/Gemma3-270M-IT/resolve/main/gemma3-270m-it-int4.task"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ActionChip(
                        avatar: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text("Gemma 3 1B (Forte)"),
                        onPressed: () => setState(() => _urlController.text = "https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: "URL do Modelo (.bin, .tflite ou .task)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Hugging Face Access Token (Opcional)",
                    hintText: "hf_...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isDownloading)
                  Column(
                    children: [
                      LinearProgressIndicator(value: _downloadProgress),
                      const SizedBox(height: 5),
                      Text("Aviso: Não feche o app durante o download.", style: TextStyle(fontSize: 10, color: Colors.red[300])),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _startDownload,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.download),
                    label: const Text("Baixar Modelo Selecionado"),
                  ),
              ],
              const SizedBox(height: 40),
              const Text(
                "Nota: Para rodar LLMs locais, recomendamos aparelhos com pelo menos 6GB de RAM. Aparelhos básicos podem travar ou demorar muito para responder.",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
