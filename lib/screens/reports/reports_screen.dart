import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/document_provider.dart';
import '../../providers/company_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  Map<String, double> _summary = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    final company = context.read<CompanyProvider>().currentCompany;
    if (company != null) {
      _summary = await context
          .read<DocumentProvider>()
          .getSalesSummary(company.id!, _fromDate, _toDate);
    }

    setState(() => _loading = false);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.date_range),
              title: Text(
                  '${_fromDate.day}/${_fromDate.month}/${_fromDate.year} - ${_toDate.day}/${_toDate.month}/${_toDate.year}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _selectDateRange,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Total Ventas',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(_summary['total_sales'] ?? 0),
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                            'Facturas',
                            currencyFormat.format(
                                _summary['total_facturas'] ?? 0),
                            Colors.indigo),
                        _buildStat(
                            'Boletas',
                            currencyFormat.format(
                                _summary['total_boletas'] ?? 0),
                            Colors.teal),
                        _buildStat(
                            'Documentos',
                            '${(_summary['total_docs'] ?? 0).toInt()}',
                            Colors.blue),
                      ],
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
                    Text('Documentos Recientes',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Consumer<DocumentProvider>(
                      builder: (context, provider, _) {
                        final docs = provider.documents.take(10).toList();
                        if (docs.isEmpty) {
                          return const Text(
                              'No hay documentos en este período');
                        }
                        return Column(
                          children: docs.map((doc) => ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.receipt,
                                  size: 20,
                                  color: doc.documentType ==
                                          'Factura Electrónica'
                                      ? Colors.indigo
                                      : doc.documentType ==
                                              'Boleta Electrónica'
                                          ? Colors.teal
                                          : Colors.grey,
                                ),
                                title: Text(
                                    '${doc.documentType} ${doc.documentNumber}',
                                    style:
                                        const TextStyle(fontSize: 13)),
                                subtitle: Text(doc.customerName,
                                    style:
                                        const TextStyle(fontSize: 11)),
                                trailing: Text(
                                  'S/ ${doc.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              )).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
