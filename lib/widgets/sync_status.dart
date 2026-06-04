import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class SyncStatus extends StatefulWidget {
  final bool compact;

  const SyncStatus({super.key, this.compact = false});

  @override
  State<SyncStatus> createState() => _SyncStatusState();
}

class _SyncStatusState extends State<SyncStatus> {
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

    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    if (widget.compact) {
      return GestureDetector(
        onTap: () => SyncService.instance.sync().then((_) => _refresh()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncing)
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                connected ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: connected ? Colors.green : Colors.red,
              ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$pendingCount', style: const TextStyle(fontSize: 10, color: Colors.orange)),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: connected ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(
            syncing ? Icons.sync : connected ? Icons.cloud_done : Icons.cloud_off,
            size: 18,
            color: syncing ? Colors.blue : connected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syncing ? 'Sincronizando...' : connected ? 'En línea' : 'Sin conexión',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: connected ? Colors.green : Colors.red),
                ),
                if (lastSync != null)
                  Text(
                    'Última sync: ${dateFormat.format(DateTime.parse(lastSync).toLocal())}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                if (pendingCount > 0)
                  Text('$pendingCount pendientes', style: const TextStyle(fontSize: 10, color: Colors.orange)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: syncing ? null : () => SyncService.instance.sync().then((_) => _refresh()),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Sincronizar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
