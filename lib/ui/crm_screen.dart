import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/department.dart';
import '../repositories/crm_repository.dart';

class CRMScreen extends StatefulWidget {
  const CRMScreen({super.key});

  @override
  State<CRMScreen> createState() => _CRMScreenState();
}

class _CRMScreenState extends State<CRMScreen> {
  final CRMRepository _repository = CRMRepository();
  List<Department> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    final departments = await _repository.getDepartments();
    setState(() {
      _departments = departments;
      _isLoading = false;
    });
  }

  Future<void> _addOrEditDepartment({Department? existingDepartment}) async {
    final nameController = TextEditingController(text: existingDepartment?.name ?? '');
    final phoneController = TextEditingController(text: existingDepartment?.phoneNumber ?? '');
    final descController = TextEditingController(text: existingDepartment?.description ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existingDepartment == null ? 'Novo Departamento' : 'Editar Departamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome (Ex: Financeiro)'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'WhatsApp (Ex: 551199999999)'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descrição (Ex: Assuntos de cobrança)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                final newDepartment = Department(
                  id: existingDepartment?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                  description: descController.text,
                );

                if (existingDepartment != null) {
                  await _repository.updateDepartment(newDepartment);
                } else {
                  await _repository.addDepartment(newDepartment);
                }
                
                await _loadDepartments();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDepartment(String id) async {
    await _repository.removeDepartment(id);
    _loadDepartments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.medium(
            title: Text('CRM / Departamentos'),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_departments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('Nenhum departamento cadastrado.', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => _addOrEditDepartment(),
                      child: const Text('Adicionar Primeiro Departamento'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final department = _departments[index];
                  return Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        child: Text(department.name.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(department.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(department.phoneNumber),
                          if (department.description.isNotEmpty)
                            Text(department.description, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEditDepartment(existingDepartment: department)),
                          IconButton(
                            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error), 
                            onPressed: () => _deleteDepartment(department.id)
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _departments.length,
              ),
            ),
             const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditDepartment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
