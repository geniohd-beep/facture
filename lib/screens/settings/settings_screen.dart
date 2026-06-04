import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sunatTokenController = TextEditingController();
  final _apiintiTokenController = TextEditingController();
  final _jsonpeTokenController = TextEditingController();
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
    final apiintiToken = await _settingsService.getApiintiToken();
    final jsonpeToken = await _settingsService.getJsonpeToken();
    if (!mounted) return;
    setState(() {
      _sunatTokenController.text = sunatToken ?? '';
      _apiintiTokenController.text = apiintiToken ?? '';
      _jsonpeTokenController.text = jsonpeToken ?? '';
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    await _settingsService.setSunatToken(_sunatTokenController.text.trim());
    await _settingsService.setApiintiToken(_apiintiTokenController.text.trim());
    await _settingsService.setJsonpeToken(_jsonpeTokenController.text.trim());

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }

  @override
  void dispose() {
    _sunatTokenController.dispose();
    _apiintiTokenController.dispose();
    _jsonpeTokenController.dispose();
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
                              Icon(Icons.cloud,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('API SUNAT',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
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
                  _buildApiCard(
                    icon: Icons.person_search,
                    title: 'API Inti',
                    description:
                        'Consulta DNI y RUC (apiinti.dev) — Se intenta primero',
                    controller: _apiintiTokenController,
                    label: 'Token API Inti',
                    hint: 'Ingrese su API Key de apiinti.dev',
                  ),
                  const SizedBox(height: 12),
                  _buildApiCard(
                    icon: Icons.alternate_email,
                    title: 'json.pe',
                    description:
                        'Alternativa para consulta DNI y RUC (json.pe)',
                    controller: _jsonpeTokenController,
                    label: 'Token json.pe',
                    hint: 'Ingrese su token de json.pe',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.public,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GraphPeru',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  'API gratuita sin token (graphperu.daustinn.com) — Última opción',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
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
                    label: Text(
                        _isSaving ? 'Guardando...' : 'Guardar Configuración'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildApiCard({
    required IconData icon,
    required String title,
    required String description,
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
