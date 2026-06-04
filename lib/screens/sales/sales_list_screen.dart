import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/company_provider.dart';
import '../../widgets/document_card.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  String? _filterType;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    final company = context.read<CompanyProvider>().currentCompany;
    context.read<DocumentProvider>().loadDocuments(
          companyId: company?.id,
          docType: _filterType,
          status: _filterStatus,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos Emitidos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() {
                _filterType = v == 'TODOS' ? null : v;
              });
              _loadDocuments();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'TODOS', child: Text('Todos')),
              const PopupMenuItem(
                  value: 'Factura Electrónica',
                  child: Text('Facturas')),
              const PopupMenuItem(
                  value: 'Boleta Electrónica',
                  child: Text('Boletas')),
              const PopupMenuItem(
                  value: 'Nota de Venta',
                  child: Text('Notas de Venta')),
              const PopupMenuItem(
                  value: 'Nota de Crédito',
                  child: Text('Notas de Crédito')),
              const PopupMenuItem(
                  value: 'Nota de Débito',
                  child: Text('Notas de Débito')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/sales/new'),
        child: const Icon(Icons.add),
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator());
          }

          if (provider.documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                      'No hay documentos emitidos'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                        context, '/sales/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva Venta'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: provider.documents.length,
            itemBuilder: (context, index) {
              final doc = provider.documents[index];
              return DocumentCard(
                document: doc,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/sales/${doc.id}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
