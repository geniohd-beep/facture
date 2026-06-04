import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../models/kardex_entry.dart';
import '../../services/database_service.dart';

class KardexScreen extends StatefulWidget {
  final Product product;

  const KardexScreen({super.key, required this.product});

  @override
  State<KardexScreen> createState() => _KardexScreenState();
}

class _KardexScreenState extends State<KardexScreen> {
  final _db = DatabaseService();
  List<KardexEntry> _entries = [];
  Map<String, dynamic> _summary = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKardex();
  }

  Future<void> _loadKardex() async {
    setState(() => _loading = true);
    final entries = await _db.getKardexByProduct(widget.product.id!);
    final summary = await _db.getKardexSummary(widget.product.id!);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _summary = summary;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cardex: ${widget.product.name}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(theme, currencyFormat),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('No hay movimientos registrados'))
                      : ListView.builder(
                          itemCount: _entries.length,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemBuilder: (_, i) => _buildEntryCard(_entries[i], theme, currencyFormat),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, NumberFormat currencyFormat) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(theme, 'Stock Actual', '${widget.product.stock}', Icons.inventory, Colors.blue),
                _stat(theme, 'Entradas', '${(_summary['total_in'] as num).toInt()}', Icons.arrow_downward, Colors.green),
                _stat(theme, 'Salidas', '${(_summary['total_out'] as num).toInt()}', Icons.arrow_upward, Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Valor total: ${currencyFormat.format(_summary['total_value'] ?? 0)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildEntryCard(KardexEntry entry, ThemeData theme, NumberFormat currencyFormat) {
    final isIn = entry.quantityIn > 0;
    final isOut = entry.quantityOut > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: isIn ? Colors.green : isOut ? Colors.red : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${entry.date.day}/${entry.date.month}/${entry.date.year} ${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _docColor(entry.documentType).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          entry.documentType,
                          style: TextStyle(fontSize: 9, color: _docColor(entry.documentType)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.reference.isNotEmpty ? entry.reference : entry.documentNumber ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isIn)
                  Text('+${entry.quantityIn.toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                if (isOut)
                  Text('-${entry.quantityOut.toInt()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Stock: ${entry.stockBalance}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _docColor(String type) {
    switch (type) {
      case 'VENTA':
      case 'Factura Electrónica':
      case 'Boleta Electrónica':
      case 'Nota de Venta':
        return Colors.red;
      case 'COMPRA':
        return Colors.green;
      case 'AJUSTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
