import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final DatabaseService _db = DatabaseService();
  final Connectivity _connectivity = Connectivity();
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isSyncing = false;
  String _deviceId = '';
  bool _initialized = false;

  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('sync_device_id') ?? _uuid.v4();
    await prefs.setString('sync_device_id', _deviceId);

    final exportDone = prefs.getBool('sync_initial_export_done') ?? false;
    if (!exportDone) {
      await _exportAllLocalData();
      await prefs.setBool('sync_initial_export_done', true);
    }

    _connectivitySub = _connectivity.onConnectivityChanged.listen(_onConnectivityChange);
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) => sync());
    _initialized = true;
    sync();
  }

  Future<void> _exportAllLocalData() async {
    final db = await _db.database;
    final tables = ['companies', 'customers', 'products', 'documents'];
    for (final table in tables) {
      final rows = await db.query(table);
      for (final row in rows) {
        final id = row['id'] as int;
        await _db.addToSyncQueue(
          tableName: table,
          recordId: id,
          operation: 'INSERT',
          data: Map<String, dynamic>.from(row),
        );
      }
    }
    final items = await db.query('document_items');
    for (final row in items) {
      final id = row['id'] as int;
      await _db.addToSyncQueue(
        tableName: 'document_items',
        recordId: id,
        operation: 'INSERT',
        data: Map<String, dynamic>.from(row),
      );
    }
  }

  void _onConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) sync();
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) return;

    _isSyncing = true;
    try {
      await _pushLocalChanges();
      await _pullRemoteChanges();
    } catch (e) {
      // Silently fail - will retry on next interval
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _pushLocalChanges() async {
    final pending = await _db.getPendingSyncItems();
    if (pending.isEmpty) return;

    for (final entry in pending) {
      try {
        final tableName = entry['table_name'] as String;
        final operation = entry['operation'] as String;
        final data = entry['data'] != null
            ? jsonDecode(entry['data'] as String) as Map<String, dynamic>
            : null;
        final recordId = entry['record_id'] as int?;
        final syncId = entry['id'] as int;

        if (operation == 'DELETE') {
          await _supabase
              .from(tableName)
              .delete()
              .eq('local_id', recordId!)
              .eq('device_id', _deviceId);
        } else if (data != null) {
          data['device_id'] = _deviceId;
          data['local_id'] = recordId;
          data.remove('id');
          await _supabase.from(tableName).upsert(data,
              onConflict: 'local_id');
        }

        await _db.markSynced(syncId);
      } catch (_) {
        // Skip failed entry, will retry next sync
      }
    }
  }

  Future<void> _pullRemoteChanges() async {
    final lastSync = await _db.getLastSyncTime();
    final since = lastSync?.toUtc().toIso8601String() ??
        DateTime.now().subtract(const Duration(days: 7)).toUtc().toIso8601String();

    await _pullTable('companies', since, _db.upsertCompany);
    await _pullTable('customers', since, _db.upsertCustomer);
    await _pullTable('products', since, _db.upsertProduct);
    await _pullTable('documents', since, (data) async {
      await _db.upsertDocument(data);
    });
    await _pullTable('document_items', since, (data) async {
      await _db.upsertDocumentItem(data);
    });
  }

  Future<void> _pullTable(
    String tableName,
    String since,
    Future<void> Function(Map<String, dynamic>) upsertFn,
  ) async {
    try {
      final response = await _supabase
          .from(tableName)
          .select()
          .gte('updated_at', since)
          .neq('device_id', _deviceId);

      for (final row in response) {
        final data = Map<String, dynamic>.from(row);
        data.remove('id');
        data.remove('local_id');
        data.remove('device_id');
        data.remove('created_at');
        try {
          await upsertFn(data);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    final pending = await _db.countPendingSync();
    final lastSync = await _db.getLastSyncTime();
    final hasConnection = await _checkConnectivity();
    return {
      'pending': pending,
      'lastSync': lastSync?.toIso8601String(),
      'connected': hasConnection,
      'syncing': _isSyncing,
    };
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
  }
}
