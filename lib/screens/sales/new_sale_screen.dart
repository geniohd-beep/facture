import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/customer.dart';
import '../../models/product.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _productSearchController = TextEditingController();
  final _seriesController = TextEditingController(text: 'NV001');
  final _notesController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  String _documentType = 'Nota de Venta';
  String _paymentMethod = 'Efectivo';
  String _taxRegime = 'GENERAL';
  DateTime? _deliveryDate;

  static const _documentTypes = [
    'Nota de Venta',
    'Boleta Electrónica',
    'Factura Electrónica',
    'Pedido',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _seriesController.dispose();
    _notesController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  String _seriesForType(String type) {
    switch (type) {
      case 'Boleta Electrónica':
        return 'B001';
      case 'Factura Electrónica':
        return 'F001';
      case 'Nota de Venta':
        return 'NV001';
      case 'Pedido':
        return 'PD001';
      default:
        return 'NV001';
    }
  }

  void _selectCustomer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CustomerSearchSheet(
        onSelected: (customer) {
          context.read<DocumentProvider>().selectCustomer(customer);
          Navigator.pop(ctx);
        },
        onNewCustomer: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, '/customers/form');
        },
      ),
    );
  }

  void _addProduct(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductSearchSheet(
        onSelected: (product) {
          Navigator.pop(ctx);
          _showQuantityDialog(context, product);
        },
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Product product) {
    final quantityController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name),
        content: TextField(
          controller: quantityController,
          decoration: const InputDecoration(labelText: 'Cantidad'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(quantityController.text) ?? 1;
              if (qty > 0) {
                context
                    .read<DocumentProvider>()
                    .addItem(product, qty, taxRegime: _taxRegime);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deliveryDate = picked);
    }
  }

  Future<void> _createDocument() async {
    final docProvider = context.read<DocumentProvider>();
    final companyProvider = context.read<CompanyProvider>();

    if (!companyProvider.hasCompany) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe registrar una empresa primero')),
      );
      return;
    }

    if (docProvider.currentItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue al menos un producto')),
      );
      return;
    }

    if (_documentType != 'Nota de Venta' &&
        _documentType != 'Pedido' &&
        docProvider.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un cliente')),
      );
      return;
    }

    if (_documentType == 'Pedido' && _deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione la fecha de entrega')),
      );
      return;
    }

    final doc = await docProvider.createDocument(
      company: companyProvider.currentCompany!,
      documentType: _documentType,
      series: _seriesController.text,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      taxRegime: _taxRegime,
      deliveryDate: _deliveryDate,
      deliveryAddress: _deliveryAddressController.text.trim(),
    );

    if (!mounted) return;

    if (doc != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_documentType ${doc.documentNumber} creada')),
      );
      Navigator.pushNamed(context, '/sales/${doc.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createDocument,
            tooltip: 'Emitir documento',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDocumentTypeCard(theme),
                const SizedBox(height: 12),
                if (_documentType == 'Pedido') _buildDeliveryCard(theme),
                if (_documentType == 'Pedido') const SizedBox(height: 12),
                _buildTaxRegimeCard(theme),
                const SizedBox(height: 12),
                _buildCustomerCard(),
                const SizedBox(height: 12),
                _buildProductsCard(theme),
                const SizedBox(height: 12),
                _buildNotesCard(theme),
              ],
            ),
          ),
          _buildTotalsBar(theme),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo Documento', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _documentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _documentType = v!;
                  _seriesController.text = _seriesForType(v);
                  if (v != 'Pedido') {
                    _deliveryDate = null;
                    _deliveryAddressController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Serie',
                      helperText: 'Auto-generado según tipo',
                    ),
                    controller: _seriesController,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Pago'),
                    items: const [
                      DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'Tarjeta Débito', child: Text('Tarjeta Débito')),
                      DropdownMenuItem(value: 'Tarjeta Crédito', child: Text('Tarjeta Crédito')),
                      DropdownMenuItem(value: 'Yape', child: Text('Yape')),
                      DropdownMenuItem(value: 'Plin', child: Text('Plin')),
                      DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                    ],
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Entrega', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDeliveryDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Entrega',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _deliveryDate != null
                      ? '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de Entrega',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxRegimeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Régimen Tributario', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'GENERAL', label: Text('General'), icon: Icon(Icons.check_circle)),
                ButtonSegment(value: 'RUS', label: Text('RUS'), icon: Icon(Icons.percent)),
              ],
              selected: {_taxRegime},
              onSelectionChanged: (v) {
                setState(() => _taxRegime = v.first);
              },
            ),
            if (_taxRegime == 'RUS')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Régimen Único Simplificado — IGV exonerado (0%)',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Consumer<DocumentProvider>(
      builder: (context, docProv, _) {
        final customer = docProv.selectedCustomer;
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(customer?.displayName ?? 'Seleccionar Cliente'),
            subtitle: customer != null
                ? Text('${customer.documentType}: ${customer.documentNumber}')
                : const Text('Obligatorio para Boleta/Factura'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (customer != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => docProv.selectCustomer(null),
                  ),
                const Icon(Icons.search),
              ],
            ),
            onTap: () => _selectCustomer(context),
          ),
        );
      },
    );
  }

  Widget _buildProductsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Productos', style: theme.textTheme.titleSmall),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  onPressed: () => _addProduct(context),
                ),
              ],
            ),
            Consumer<DocumentProvider>(
              builder: (context, docProv, _) {
                if (docProv.currentItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Agregue productos a la venta')),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docProv.currentItems.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = docProv.currentItems[index];
                    return Dismissible(
                      key: ValueKey('${item.productId}-$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => docProv.removeItem(index),
                      child: ListTile(
                        dense: true,
                        title: Text(item.productName),
                        subtitle: Text(
                            '${item.quantity.toStringAsFixed(2)} x S/ ${item.unitPrice.toStringAsFixed(2)}'),
                        trailing: Text(
                          'S/ ${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildTotalsBar(ThemeData theme) {
    return Consumer<DocumentProvider>(
      builder: (context, docProv, _) {
        final isRus = _taxRegime == 'RUS';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('S/ ${docProv.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isRus ? 'IGV (Exonerado):' : 'IGV (18%):'),
                    Text(isRus
                        ? 'S/ 0.00'
                        : 'S/ ${docProv.igv.toStringAsFixed(2)}'),
                  ],
                ),
                if (isRus)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'RUS — Exonerado',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      isRus
                          ? 'S/ ${docProv.subtotal.toStringAsFixed(2)}'
                          : 'S/ ${docProv.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        docProv.currentItems.isEmpty ? null : _createDocument,
                    icon: const Icon(Icons.check_circle),
                    label: Text('Guardar $_documentType'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomerSearchSheet extends StatefulWidget {
  final ValueChanged<Customer> onSelected;
  final VoidCallback onNewCustomer;

  const _CustomerSearchSheet({
    required this.onSelected,
    required this.onNewCustomer,
  });

  @override
  State<_CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<_CustomerSearchSheet> {
  final _searchController = TextEditingController();
  final _dniController = TextEditingController();
  bool _consultingDni = false;

  @override
  void dispose() {
    _searchController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _consultDni() async {
    final dni = _dniController.text.trim();
    if (dni.length != 8) return;

    setState(() => _consultingDni = true);

    final provider = context.read<CustomerProvider>();
    final result = await provider.searchByDNI(dni);

    if (!mounted) return;
    setState(() => _consultingDni = false);

    if (result.isSuccess && result.data != null) {
      widget.onSelected(result.data!);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'No se encontró el DNI')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dniController,
                    decoration: InputDecoration(
                      labelText: 'Consultar DNI',
                      hintText: 'N° de documento',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _consultingDni
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.cloud_download),
                              onPressed: _dniController.text.length >= 8
                                  ? _consultDni
                                  : null,
                              tooltip: 'Consultar RENIEC',
                            ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: widget.onNewCustomer,
                  tooltip: 'Nuevo cliente',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar cliente por nombre...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                if (v.length >= 2) {
                  context.read<CustomerProvider>().searchCustomers(v);
                }
                setState(() {});
              },
            ),
          ),
          Consumer<CustomerProvider>(
            builder: (context, provider, _) {
              final results = _searchController.text.length >= 2
                  ? provider.searchResults
                  : provider.customers;
              return SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final c = results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                            c.displayName.isNotEmpty ? c.displayName[0] : '?'),
                      ),
                      title: Text(c.displayName),
                      subtitle: Text('${c.documentType}: ${c.documentNumber}'),
                      onTap: () => widget.onSelected(c),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductSearchSheet extends StatefulWidget {
  final ValueChanged<Product> onSelected;

  const _ProductSearchSheet({required this.onSelected});

  @override
  State<_ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<_ProductSearchSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                if (v.length >= 2) {
                  context.read<ProductProvider>().searchProducts(v);
                }
                setState(() {});
              },
            ),
          ),
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              final results = _searchController.text.length >= 2
                  ? provider.searchResults
                  : provider.products;
              return SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final p = results[index];
                    return ListTile(
                      leading: CircleAvatar(
                          child:
                              Text(p.code.isNotEmpty ? p.code[0] : 'P')),
                      title: Text(p.name),
                      subtitle: Text(
                          'Stock: ${p.stock} | S/ ${p.salePrice.toStringAsFixed(2)}'),
                      trailing: const Icon(Icons.add_circle),
                      onTap: () => widget.onSelected(p),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
