import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:permission_handler/permission_handler.dart';
import '../models/contact.dart';
import '../repositories/contact_repository.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactRepository _repository = ContactRepository();
  List<Contact> _contacts = [];
  bool _isLoading = true;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  // Showcase Keys
  final GlobalKey _keyContactList = GlobalKey();
  final GlobalKey _keyImport = GlobalKey();
  final GlobalKey _keyAddContact = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTourIfNeeded());
  }

  Future<void> _startTourIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch_contacts_tour') ?? true;
    if (isFirstLaunch && mounted) {
      ShowcaseView.get().startShowCase([
        _keyContactList,
        _keyImport,
        _keyAddContact,
      ]);
      await prefs.setBool('first_launch_contacts_tour', false);
    }
  }

  void _manualTour() {
    ShowcaseView.get().startShowCase([
      _keyContactList,
      _keyImport,
      _keyAddContact,
    ]);
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final contacts = await _repository.getContacts();
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _showContactDialog({Contact? contact}) async {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final tagsController = TextEditingController(
      text: contact?.tags.join(', ') ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(contact == null ? 'Adicionar Contato' : 'Editar Contato'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone (com código do país)',
                ),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Etiquetas (separadas por vírgula)',
                  hintText: 'Cliente, VIP, Amigo',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                final List<String> tags = tagsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final newContact = Contact(
                  id:
                      contact?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  phone: phoneController.text.replaceAll(RegExp(r'\D'), ''),
                  tags: tags,
                );
                await _repository.saveContact(newContact);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _loadContacts();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _importContactsFromDevice() async {
    if (await Permission.contacts.request().isGranted) {
      final contacts = await flutter_contacts.FlutterContacts.getContacts(
        withProperties: true,
      );
      int addedCount = 0;

      for (var c in contacts) {
        if (c.phones.isNotEmpty) {
          String phone = c.phones.first.number.replaceAll(RegExp(r'\D'), '');
          if (phone.length >= 10) {
            final newContact = Contact(
              id:
                  DateTime.now().microsecondsSinceEpoch.toString() +
                  addedCount.toString(),
              name: c.displayName,
              phone: phone,
              tags: ['Dispositivo'],
            );
            await _repository.saveContact(newContact);
            addedCount++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount contatos importados do dispositivo!'),
          ),
        );
        _loadContacts();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de contatos negada.')),
        );
      }
    }
  }

  Future<void> _deleteContact(String id) async {
    await _repository.deleteContact(id);
    _loadContacts();
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Contatos"),
        content: Text(
          "Deseja realmente excluir ${_selectedIds.length} contato(s)?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("EXCLUIR"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _repository.deleteContacts(_selectedIds.toList());
      _selectedIds.clear();
      _isSelectionMode = false;
      await _loadContacts();
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _fixPrefixes() async {
    int count = 0;
    for (var contact in _contacts) {
      if (!contact.phone.startsWith('55')) {
        final updated = Contact(
          id: contact.id,
          name: contact.name,
          phone: '55${contact.phone}',
          tags: contact.tags,
        );
        await _repository.saveContact(updated);
        count++;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count contatos atualizados com +55!')),
      );
      _loadContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(
            _isSelectionMode
                ? "${_selectedIds.length} selecionados"
                : 'Meus Contatos',
          ),
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  }),
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: "Tutorial",
              onPressed: _manualTour,
            ),
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteSelected,
              ),
            Showcase(
              key: _keyImport,
              title: "Ferramentas de Importação",
              description:
                  "Importe contatos do celular, cole uma lista de texto ou corrija o prefixo +55 automaticamente.",
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'text') {
                    _showImportDialog();
                  } else if (value == 'device') {
                    _importContactsFromDevice();
                  } else if (value == 'fix_prefix') {
                    _fixPrefixes();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'device',
                    child: Row(
                      children: [
                        Icon(Icons.contact_phone),
                        SizedBox(width: 8),
                        Text('Importar do Dispositivo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'text',
                    child: Row(
                      children: [
                        Icon(Icons.paste),
                        SizedBox(width: 8),
                        Text('Importar Texto (Colar)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'fix_prefix',
                    child: Row(
                      children: [
                        Icon(Icons.add_call),
                        SizedBox(width: 8),
                        Text('Adicionar +55 Automático'),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.download),
                tooltip: "Ferramentas",
              ),
            ),
          ],
        ),
        body: Showcase(
          key: _keyContactList,
          title: "Sua Agenda",
          description:
              "Aqui estão seus contatos. Você pode clicar para editar, ver etiquetas ou segurar para selecionar vários de uma vez.",
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _contacts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum contato ainda.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final bool has55 = contact.phone.startsWith('55');

                    final isSelected = _selectedIds.contains(contact.id);

                    return Card(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(contact.id);
                          } else {
                            _showContactDialog(contact: contact);
                          }
                        },
                        onLongPress: () => _toggleSelection(contact.id),
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(contact.id),
                              )
                            : CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                child: Text(
                                  contact.name.isNotEmpty
                                      ? contact.name[0].toUpperCase()
                                      : "?",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                        title: Row(
                          children: [
                            Expanded(child: Text(contact.name)),
                            if (has55)
                              const Text("🇧🇷", style: TextStyle(fontSize: 16))
                            else
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.phone),
                            if (contact.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  children: contact.tags
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                        trailing: _isSelectionMode
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showContactDialog(contact: contact),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteContact(contact.id),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
        ),
        floatingActionButton: Showcase(
          key: _keyAddContact,
          title: "Novo Contato",
          description: "Adicione um contato manualmente rapidamente por aqui.",
          child: FloatingActionButton(
            onPressed: () => _showContactDialog(),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Importar Contatos"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Cole os contatos no formato: Nome, Telefone (um por linha)",
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 10,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: "João, 558599999999\nMaria, 558588888888",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text;
              if (text.isNotEmpty) {
                final lines = text.split('\n');
                int addedCount = 0;
                for (var line in lines) {
                  if (line.trim().isEmpty) continue;
                  final parts = line.split(',');
                  if (parts.length >= 2) {
                    final name = parts[0].trim();
                    final phone = parts[1].trim();
                    if (phone.isNotEmpty) {
                      final newContact = Contact(
                        id: DateTime.now().microsecondsSinceEpoch
                            .toString(), // micro to avoid collision in loop
                        name: name,
                        phone: phone,
                      );
                      await _repository.saveContact(newContact);
                      addedCount++;
                    }
                  }
                }
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$addedCount contatos importados com sucesso!',
                    ),
                  ),
                );
                _loadContacts();
              }
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}
