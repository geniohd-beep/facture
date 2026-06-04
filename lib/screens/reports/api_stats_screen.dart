import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class ApiStatsScreen extends StatefulWidget {
  const ApiStatsScreen({super.key});

  @override
  State<ApiStatsScreen> createState() => _ApiStatsScreenState();
}

class _ApiStatsScreenState extends State<ApiStatsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _stats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      _stats = await _db.getConsultationStatsSummary();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Consultas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
              ? const Center(
                  child: Text('Aún no hay consultas registradas'),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resumen por Proveedor',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 12),
                            ..._buildSummaryRows(theme),
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
                            Text('Detalle por Proveedor y Tipo',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 12),
                            ..._buildDetailRows(theme),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildSummaryRows(ThemeData theme) {
    final totals = <String, Map<String, int>>{};
    for (final row in _stats) {
      final provider = row['provider'] as String;
      totals.putIfAbsent(provider, () => {'total': 0, 'success': 0});
      totals[provider]!['total'] =
          totals[provider]!['total']! + (row['total'] as int);
      totals[provider]!['success'] =
          totals[provider]!['success']! + (row['success_count'] as int);
    }

    return totals.entries.map((e) {
      final total = e.value['total']!;
      final success = e.value['success']!;
      final pct = total > 0 ? (success / total * 100).toStringAsFixed(1) : '0.0';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.api, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500))),
            Expanded(
              child: Text('$success/$total',
                  textAlign: TextAlign.center),
            ),
            SizedBox(
              width: 60,
              child: Text('$pct%',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: success == total ? Colors.green : Colors.orange)),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildDetailRows(ThemeData theme) {
    return _stats.map((row) {
      final total = row['total'] as int;
      final success = row['success_count'] as int;
      final pct = total > 0 ? (success / total * 100).toStringAsFixed(1) : '0.0';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              row['document_type'] == 'DNI' ? Icons.person : Icons.business,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                '${row['provider']} - ${row['document_type']}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Text('$success/$total',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            ),
            SizedBox(
              width: 60,
              child: Text('$pct%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    color: success == total ? Colors.green : Colors.orange,
                  )),
            ),
          ],
        ),
      );
    }).toList();
  }
}
