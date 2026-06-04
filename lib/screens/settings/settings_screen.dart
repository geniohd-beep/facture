import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../services/file_util.dart';
import '../../services/settings_service.dart';
import '../../services/sync_service.dart';

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

  Future<void> _exportProducts() async {
    final provider = context.read<ProductProvider>();
    final json = await provider.exportProductsToJson();
    await downloadFile(json, 'productos_exportados.json', 'application/json');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Productos exportados correctamente')),
    );
  }

  Future<void> _importProducts() async {
    final json = await uploadFile('.json');
    if (json == null || !mounted) return;
    final provider = context.read<ProductProvider>();
    final result = await provider.importProductsFromJson(json);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result)),
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Exportar / Importar Productos',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Exporta productos desde esta instancia e impórtalos en otra (GitHub)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _exportProducts,
                                  icon: const Icon(Icons.file_download),
                                  label: const Text('Exportar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _importProducts,
                                  icon: const Icon(Icons.file_upload),
                                  label: const Text('Importar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sync,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Sincronización',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sube y descarga datos desde/hacia la nube',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          _SyncAction(),
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

class _SyncAction extends StatefulWidget {
  @override
  State<_SyncAction> createState() => _SyncActionState();
}

class _SyncActionState extends State<_SyncAction> {
  Map<String, dynamic> _status = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _status = await SyncService.instance.getSyncStatus();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final pending = _status['pending'] as Map<String, int>? ?? {};
    final pendingCount = pending.values.fold(0, (int a, b) => a + b);
    final lastSync = _status['lastSync'] as String?;
    final connected = _status['connected'] as bool? ?? false;
    final syncing = _status['syncing'] as bool? ?? false;

    return Column(
      children: [
        Row(
          children: [
            Icon(
              syncing ? Icons.sync : connected ? Icons.cloud_done : Icons.cloud_off,
              size: 18,
              color: syncing ? Colors.blue : connected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                syncing ? 'Sincronizando...' : connected ? 'Conectado' : 'Sin conexión',
                style: TextStyle(
                  fontSize: 13,
                  color: syncing ? Colors.blue : connected ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        if (lastSync != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Última sync: ${_formatDate(lastSync)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        if (pendingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$pendingCount cambio(s) pendiente(s) de subir',
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: syncing
                ? null
                : () => SyncService.instance.sync().then((_) => _refresh()),
            icon: syncing
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: Text(syncing ? 'Sincronizando...' : 'Forzar sincronización'),
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
