import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../repositories/meta_api_repository.dart';

class MetaApiSettingsScreen extends StatefulWidget {
  const MetaApiSettingsScreen({super.key});

  @override
  State<MetaApiSettingsScreen> createState() => _MetaApiSettingsScreenState();
}

class _MetaApiSettingsScreenState extends State<MetaApiSettingsScreen> {
  final MetaApiRepository _repository = MetaApiRepository();
  final _tokenController = TextEditingController();
  final _phoneIdController = TextEditingController();
  final _businessIdController = TextEditingController();
  bool _isLoading = true;
  bool _isObscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    setState(() => _isLoading = true);
    final creds = await _repository.getCredentials();
    setState(() {
      _tokenController.text = creds['accessToken'] ?? '';
      _phoneIdController.text = creds['phoneId'] ?? '';
      _businessIdController.text = creds['businessId'] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveCredentials() async {
    if (_tokenController.text.isEmpty || _phoneIdController.text.isEmpty || _businessIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _repository.saveCredentials(
      accessToken: _tokenController.text,
      phoneId: _phoneIdController.text,
      businessId: _businessIdController.text,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciais salvas com sucesso!')),
      );
    }
  }

  Future<void> _testConnection() async {
    if (_tokenController.text.isEmpty || _phoneIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salve o Token e Phone ID antes de testar.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://graph.facebook.com/v18.0/${_phoneIdController.text}');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${_tokenController.text}'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(backgroundColor: Colors.green, content: Text('Conexão com a Meta API: SUCESSO! ✅')),
           );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('Falha na conexão: ${response.statusCode} - ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Erro ao conectar: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração API Oficial')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Configuração da Meta Cloud API",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Insira as credenciais obtidas no painel de desenvolvedor do Facebook (Meta for Developers).",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: "Access Token (Token de Acesso)",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscureToken ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isObscureToken = !_isObscureToken),
                      ),
                    ),
                    obscureText: _isObscureToken,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneIdController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number ID",
                      border: OutlineInputBorder(),
                      helperText: "ID do número de telefone que enviará as mensagens",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _businessIdController,
                    decoration: const InputDecoration(
                      labelText: "WhatsApp Business Account ID",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveCredentials,
                          icon: const Icon(Icons.save),
                          label: const Text("Salvar Credenciais"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _testConnection,
                        icon: const Icon(Icons.wifi_find),
                        label: const Text("Testar"),
                         style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
