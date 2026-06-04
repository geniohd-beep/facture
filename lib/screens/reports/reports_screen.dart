import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/document_provider.dart';
import '../../providers/company_provider.dart';
import '../../models/document.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  Map<String, double> _summary = {};
  List<InvoiceDocument> _recentDocs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    final company = context.read<CompanyProvider>().currentCompany;
    final docProvider = context.read<DocumentProvider>();

    if (company != null) {
      _summary = await docProvider.getSalesSummary(
          company.id!, _fromDate, _toDate);

      await docProvider.loadDocuments(
        companyId: company.id,
        from: _fromDate,
        to: _toDate,
      );
      setState(() {
        _recentDocs = docProvider.documents;
      });
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

  Future<void> _generatePdf() async {
    final company = context.read<CompanyProvider>().currentCompany;
    final currencyFormat = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Reporte de Ventas',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          if (company != null) ...[
            pw.Text(company.businessName,
                style: const pw.TextStyle(fontSize: 14)),
            pw.Text('RUC: ${company.ruc}',
                style: const pw.TextStyle(fontSize: 10)),
          ],
          pw.SizedBox(height: 10),
          pw.Text(
              'Período: ${_fromDate.day}/${_fromDate.month}/${_fromDate.year} - ${_toDate.day}/${_toDate.month}/${_toDate.year}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Total Ventas: ${currencyFormat.format(_summary['total_sales'] ?? 0)}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('Total Documentos: ${(_summary['total_docs'] ?? 0).toInt()}'),
                pw.Text('Facturas: ${currencyFormat.format(_summary['total_facturas'] ?? 0)}'),
                pw.Text('Boletas: ${currencyFormat.format(_summary['total_boletas'] ?? 0)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          if (_recentDocs.isNotEmpty) ...[
            pw.Text('Documentos Emitidos',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FixedColumnWidth(100),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: ['Documento', 'Cliente', 'Total', 'Estado']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          ))
                      .toList(),
                ),
                ..._recentDocs.map((d) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(d.documentNumber,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(d.customerName,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(currencyFormat.format(d.total),
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(d.statusLabel,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ],
                    )),
              ],
            ),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'Reporte_Ventas_${_fromDate.day}_${_fromDate.month}_${_toDate.day}_${_toDate.month}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _summary.isNotEmpty ? _generatePdf : null,
            tooltip: 'Exportar PDF',
          ),
        ],
      ),
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
                    Text('Total Ventas', style: theme.textTheme.titleMedium),
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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                            'Facturas',
                            currencyFormat.format(_summary['total_facturas'] ?? 0),
                            Colors.indigo),
                        _buildStat(
                            'Boletas',
                            currencyFormat.format(_summary['total_boletas'] ?? 0),
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
            if (_recentDocs.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Documentos Emitidos',
                              style: theme.textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf),
                            onPressed: _generatePdf,
                            tooltip: 'Exportar PDF',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._recentDocs.map((doc) => ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.receipt,
                              size: 20,
                              color: doc.documentType == 'Factura Electrónica'
                                  ? Colors.indigo
                                  : doc.documentType == 'Boleta Electrónica'
                                      ? Colors.teal
                                      : Colors.grey,
                            ),
                            title: Text('${doc.documentType} ${doc.documentNumber}',
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(doc.customerName,
                                style: const TextStyle(fontSize: 11)),
                            trailing: Text(
                              'S/ ${doc.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () => Navigator.pushNamed(context, '/sales/${doc.id}'),
                          )),
                    ],
                  ),
                ),
              ),
            if (_recentDocs.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No hay documentos en este período',
                        style: theme.textTheme.bodyMedium),
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
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
