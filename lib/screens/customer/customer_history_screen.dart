import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../providers/company_provider.dart';

class CustomerHistoryScreen extends StatefulWidget {
  final Customer customer;

  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  List<InvoiceDocument> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final company = context.read<CompanyProvider>().currentCompany;
    if (company == null) return;

    final db = context.read<DocumentProvider>();
    final docs = await db.getDocumentsByCustomer(
      customerId: widget.customer.id!,
      companyId: company.id!,
    );

    if (!mounted) return;
    setState(() {
      _documents = docs;
      _loading = false;
    });
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'TOTAL':
        return 'Pagado en total';
      case 'ADELANTO':
        return 'Con adelanto';
      case 'PAGO_PARCIAL':
        return 'Pagado en parte';
      default:
        return status;
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case 'TOTAL':
        return Colors.green;
      case 'ADELANTO':
        return Colors.orange;
      case 'PAGO_PARCIAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalPurchased =
        _documents.fold<double>(0, (sum, d) => sum + d.total);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.displayName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _summaryRow(
                            'Documentos emitidos', '${_documents.length}'),
                        _summaryRow(
                            'Total comprado', 'S/ ${totalPurchased.toStringAsFixed(2)}'),
                        const Divider(),
                        Text('Estado de cuentas',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ..._paymentStatusSummary(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _documents.isEmpty
                      ? const Center(child: Text('Sin compras registradas'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _statusColor(doc.status).withValues(alpha: 0.2),
                                  child: Icon(
                                    _statusIcon(doc.documentType),
                                    color: _statusColor(doc.status),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                    '${doc.documentType} ${doc.documentNumber}'),
                                subtitle: Text(
                                  '${doc.issueDate.day}/${doc.issueDate.month}/${doc.issueDate.year} - S/ ${doc.total.toStringAsFixed(2)}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _paymentStatusColor(
                                                doc.paymentStatus)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _paymentStatusLabel(doc.paymentStatus),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _paymentStatusColor(
                                              doc.paymentStatus),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      doc.statusLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _statusColor(doc.status),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => Navigator.pushNamed(
                                    context, '/sales/${doc.id}'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  List<Widget> _paymentStatusSummary() {
    final total = _documents.length;
    final pagadoTotal =
        _documents.where((d) => d.paymentStatus == 'TOTAL').length;
    final adelanto =
        _documents.where((d) => d.paymentStatus == 'ADELANTO').length;
    final parcial =
        _documents.where((d) => d.paymentStatus == 'PAGO_PARCIAL').length;

    return [
      if (pagadoTotal > 0)
        _summaryRow('Pagado en total', '$pagadoTotal/$total'),
      if (adelanto > 0) _summaryRow('Con adelanto', '$adelanto/$total'),
      if (parcial > 0) _summaryRow('Pagado en parte', '$parcial/$total'),
      if (total == 0) const Text('Sin movimientos',
          style: TextStyle(fontSize: 12, color: Colors.grey)),
    ];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PEDIDO':
        return Colors.purple;
      case 'EMITIDO':
        return Colors.blue;
      case 'ENVIADO':
        return Colors.orange;
      case 'ACEPTADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String docType) {
    switch (docType) {
      case 'Factura Electrónica':
        return Icons.receipt;
      case 'Boleta Electrónica':
        return Icons.receipt_long;
      case 'Nota de Venta':
        return Icons.sell;
      case 'Pedido':
        return Icons.local_shipping;
      default:
        return Icons.description;
    }
  }
}
