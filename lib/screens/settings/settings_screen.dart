import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sunatTokenController = TextEditingController();
  final _reniecTokenController = TextEditingController();
  final _settingsService = SettingsService();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTokens();
    });
  }

  Future<void> _loadTokens() async {
    final sunatToken = await _settingsService.getSunatToken();
    final reniecToken = await _settingsService.getReniecToken();
    if (!mounted) return;
    setState(() {
      _sunatTokenController.text = sunatToken ?? '';
      _reniecTokenController.text = reniecToken ?? '';
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    await _settingsService.setSunatToken(_sunatTokenController.text.trim());
    await _settingsService.setReniecToken(_reniecTokenController.text.trim());

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }

  @override
  void dispose() {
    _sunatTokenController.dispose();
    _reniecTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cloud, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('API SUNAT',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Token para enviar comprobantes electrónicos a SUNAT',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _sunatTokenController,
                            decoration: const InputDecoration(
                              labelText: 'Token SUNAT',
                              hintText: 'Ingrese el token de API',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_search, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('API RENIEC / SUNAT',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Token para consultar DNI y RUC automáticamente',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _reniecTokenController,
                            decoration: const InputDecoration(
                              labelText: 'Token RENIEC/SUNAT',
                              hintText: 'Ingrese el token de API',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar Configuración'),
                  ),
                ],
              ),
            ),
    );
  }
}
