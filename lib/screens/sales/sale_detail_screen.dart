import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/company_provider.dart';
import '../../models/document.dart';

class SaleDetailScreen extends StatefulWidget {
  final int documentId;

  const SaleDetailScreen({super.key, required this.documentId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  InvoiceDocument? _document;
  List<DocumentItem> _items = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final provider = context.read<DocumentProvider>();
    _document = await provider.getDocumentById(widget.documentId);
    if (_document != null) {
      _items = await provider.getDocumentItems(widget.documentId);
    }
    setState(() => _loading = false);
  }

  Future<void> _sendToSunat() async {
    if (_document == null) return;

    setState(() => _sending = true);

    final company = context.read<CompanyProvider>().currentCompany;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay empresa seleccionada')),
      );
      setState(() => _sending = false);
      return;
    }

    final result = await context
        .read<DocumentProvider>()
        .sendToSunat(_document!, company);

    if (!mounted) return;
    setState(() => _sending = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.data?['message'] ?? 'Enviado correctamente')),
      );
      _loadDocument();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Error al enviar')),
      );
    }
  }

  Future<void> _printDocument() async {
    if (_document == null) return;

    final company = context.read<CompanyProvider>().currentCompany;
    if (company == null) return;

    await context
        .read<DocumentProvider>()
        .printDocument(_document!, company);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Documento')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Documento')),
        body: const Center(child: Text('Documento no encontrado')),
      );
    }

    final doc = _document!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${doc.documentType} ${doc.documentNumber}'),
        actions: [
          if (doc.documentType == 'Factura Electrónica' ||
              doc.documentType == 'Boleta Electrónica')
            IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              onPressed: _sending ? null : _sendToSunat,
              tooltip: 'Enviar a SUNAT',
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printDocument,
            tooltip: 'Imprimir/PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(doc.documentType,
                          style: theme.textTheme.titleMedium),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: doc.status == 'ACEPTADO'
                              ? Colors.green
                              : doc.status == 'RECHAZADO'
                                  ? Colors.red
                                  : Colors.orange,
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(
                          doc.statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Serie-Número', doc.documentNumber),
                  _infoRow(
                    'Fecha',
                    '${doc.issueDate.day}/${doc.issueDate.month}/${doc.issueDate.year}',
                  ),
                  _infoRow('Método Pago', doc.paymentMethod),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _infoRow('Nombre', doc.customerName),
                  _infoRow(
                      doc.customerDocType,
                      doc.customerDocNumber),
                  if (doc.customerAddress.isNotEmpty)
                    _infoRow('Dirección', doc.customerAddress),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Productos',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ..._items.map((item) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName),
                                  Text(
                                    '${item.quantity.toStringAsFixed(2)} x S/ ${item.unitPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'S/ ${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  _infoRow('Subtotal',
                      'S/ ${doc.subtotal.toStringAsFixed(2)}'),
                  _infoRow('IGV',
                      'S/ ${doc.igv.toStringAsFixed(2)}'),
                  Text(
                    'Total: S/ ${doc.total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (doc.notes != null && doc.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notas',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(doc.notes!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
