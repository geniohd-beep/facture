import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/document.dart';

class NewSaleScreen extends StatefulWidget {
  final InvoiceDocument? document;

  const NewSaleScreen({super.key, this.document});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _seriesController = TextEditingController(text: 'NV001');
  final _notesController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  String _documentType = 'Nota de Venta';
  String _paymentMethod = 'Efectivo';
  String _paymentStatus = 'TOTAL';
  String _taxRegime = 'GENERAL';
  DateTime? _deliveryDate;
  bool _isEditing = false;

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
      if (widget.document != null) {
        _loadDocumentForEditing(widget.document!);
      } else {
        _checkSavedCart();
      }
    });
  }

  Future<void> _loadDocumentForEditing(InvoiceDocument doc) async {
    _isEditing = true;
    _documentType = doc.documentType;
    _seriesController.text = doc.series;
    _paymentMethod = doc.paymentMethod;
    _paymentStatus = doc.paymentStatus;
    _taxRegime = doc.taxRegime;
    _deliveryDate = doc.deliveryDate;
    _deliveryAddressController.text = doc.deliveryAddress;
    if (doc.notes != null) _notesController.text = doc.notes!;

    final docProv = context.read<DocumentProvider>();
    docProv.selectCustomer(Customer(
      documentType: doc.customerDocType,
      documentNumber: doc.customerDocNumber,
      firstName: doc.customerName,
      fullName: doc.customerName,
      address: doc.customerAddress,
      phone: doc.customerPhone,
      email: doc.customerEmail,
    ));
    await docProv.loadItemsForEdit(doc.id!);
    setState(() {});
  }

  Future<void> _checkSavedCart() async {
    final docProv = context.read<DocumentProvider>();
    final hasCart = await docProv.hasSavedCart;
    if (!hasCart) return;
    if (!mounted) return;

    final restore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Carrito guardado'),
        content: const Text('Tiene un carrito con productos guardados de una sesión anterior. ¿Desea restaurarlo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (restore == true) {
      await docProv.restoreCart();
    } else {
      await docProv.clearSavedCart();
    }
  }

  @override
  void dispose() {
    if (mounted) {
      context.read<DocumentProvider>().saveCart();
    }
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
          _autoFillNotes(customer);
          Navigator.pop(ctx);
        },
        onNewCustomer: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, '/customers/form');
        },
      ),
    );
  }

  void _autoFillNotes(Customer customer) {
    final name = (customer.fullName.isNotEmpty
            ? customer.fullName
            : '${customer.firstName} ${customer.lastName}')
        .trim();
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final firstName = parts[0];
      final lastNameInitials = parts.skip(1).map((p) => p[0].toUpperCase()).join('');
      _notesController.text = '$firstName $lastNameInitials';
    } else {
      _notesController.text = name;
    }
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

  void _showQuantityDialog(BuildContext context, Product product, {double initialQty = 1}) {
    double qty = initialQty;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock disponible: ${product.stock}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: ListWheelScrollView(
                  itemExtent: 40,
                  diameterRatio: 2,
                  useMagnifier: true,
                  offAxisFraction: 0,
                  onSelectedItemChanged: (i) {
                    setDialogState(() => qty = (i + 1).toDouble());
                  },
                  controller: FixedExtentScrollController(initialItem: qty.round() - 1),
                  children: List.generate(100, (i) {
                    final val = i + 1;
                    return Center(
                      child: Text(
                        val.toString(),
                        style: TextStyle(
                          fontSize: val == qty.round() ? 24 : 16,
                          fontWeight: val == qty.round() ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                context.read<DocumentProvider>().addItem(product, qty, taxRegime: _taxRegime);
                Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _editItemQuantity(BuildContext context, int index, DocumentItem item) {
    double qty = item.quantity;
    final docProv = context.read<DocumentProvider>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item.productName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Desliza para cambiar cantidad',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: ListWheelScrollView(
                  itemExtent: 40,
                  diameterRatio: 2,
                  useMagnifier: true,
                  offAxisFraction: 0,
                  onSelectedItemChanged: (i) {
                    setDialogState(() => qty = (i + 1).toDouble());
                  },
                  controller: FixedExtentScrollController(initialItem: qty.round() - 1),
                  children: List.generate(100, (i) {
                    final val = i + 1;
                    return Center(
                      child: Text(
                        val.toString(),
                        style: TextStyle(
                          fontSize: val == qty.round() ? 24 : 16,
                          fontWeight: val == qty.round() ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: qty == 0
                  ? null
                  : () {
                      showDialog(
                        context: ctx,
                        builder: (ctx2) => AlertDialog(
                          title: const Text('Eliminar producto'),
                          content: Text(
                              '¿Eliminar "${item.productName}" de la lista?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx2),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () {
                                docProv.removeItem(index);
                                Navigator.pop(ctx2);
                                Navigator.pop(ctx);
                              },
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                    },
              child: const Text('Eliminar'),
            ),
            FilledButton(
              onPressed: qty > 0
                  ? () {
                      context
                          .read<DocumentProvider>()
                          .updateItemQuantity(index, qty, taxRegime: _taxRegime);
                      Navigator.pop(ctx);
                    }
                  : null,
              child: Text(qty > 0 ? 'Actualizar' : ''),
            ),
          ],
        ),
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

    late String? error;
    if (_isEditing && widget.document != null) {
      error = await docProvider.updateDocument(
        documentId: widget.document!.id!,
        company: companyProvider.currentCompany!,
        documentType: _documentType,
        series: _seriesController.text,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentStatus,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        taxRegime: _taxRegime,
        deliveryDate: _deliveryDate,
        deliveryAddress: _deliveryAddressController.text.trim(),
      );
    } else {
      error = await docProvider.createDocument(
        company: companyProvider.currentCompany!,
        documentType: _documentType,
        series: _seriesController.text,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentStatus,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        taxRegime: _taxRegime,
        deliveryDate: _deliveryDate,
        deliveryAddress: _deliveryAddressController.text.trim(),
      );
    }

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? '$_documentType actualizada exitosamente'
              : '$_documentType creada exitosamente'),
        ),
      );
      if (_isEditing && widget.document != null) {
        Navigator.pushReplacementNamed(
            context, '/sales/${widget.document!.id}');
      } else {
        final docId = docProvider.lastCreatedDocId;
        if (docId != null) {
          Navigator.pushReplacementNamed(context, '/sales/$docId');
        } else {
          Navigator.pushNamed(context, '/sales');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editando ${widget.document!.documentNumber}' : 'Nueva Venta'),
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
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Serie',
                helperText: 'Auto-generado según tipo',
              ),
              controller: _seriesController,
              readOnly: true,
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

  Widget _buildCustomerCard() {
    return Consumer<DocumentProvider>(
      builder: (context, docProv, _) {
        final customer = docProv.selectedCustomer;
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(customer?.displayName ?? 'Seleccionar Cliente'),
            subtitle: customer != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${customer.documentType}: ${customer.documentNumber}'),
                      Row(
                        children: [
                          if (customer.phone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone, size: 12),
                                  const SizedBox(width: 2),
                                  Text(customer.phone,
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          if (customer.email.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email, size: 12),
                                const SizedBox(width: 2),
                                Text(customer.email,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  )
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantity.toStringAsFixed(2)} x S/ ${item.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text('S/ ${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editItemQuantity(context, index, item),
                            tooltip: 'Editar cantidad',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => docProv.removeItem(index),
                            tooltip: 'Eliminar producto',
                          ),
                        ],
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
                  children: [
                    Text('Régimen:', style: theme.textTheme.labelMedium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'GENERAL', label: Text('General', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: 'RUS', label: Text('RUS', style: TextStyle(fontSize: 11))),
                        ],
                        selected: {_taxRegime},
                        onSelectionChanged: (v) {
                          setState(() => _taxRegime = v.first);
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      isRus
                          ? 'S/ ${docProv.subtotal.toStringAsFixed(2)}'
                          : 'S/ ${docProv.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Método de Pago',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'Tarjeta Débito', child: Text('Tarjeta Débito')),
                    DropdownMenuItem(value: 'Tarjeta Crédito', child: Text('Tarjeta Crédito')),
                    DropdownMenuItem(value: 'Yape', child: Text('Yape')),
                    DropdownMenuItem(value: 'Plin', child: Text('Plin')),
                    DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                    DropdownMenuItem(value: 'Contraentrega', child: Text('Contraentrega')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado de Pago',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'TOTAL', child: Text('Pagado en total')),
                    DropdownMenuItem(value: 'ADELANTO', child: Text('Con adelanto')),
                    DropdownMenuItem(value: 'PAGO_PARCIAL', child: Text('Pagado en parte')),
                  ],
                  onChanged: (v) => setState(() => _paymentStatus = v!),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: docProv.currentItems.isEmpty ? null : _createDocument,
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

  const _CustomerSearchSheet({required this.onSelected, required this.onNewCustomer});

  @override
  State<_CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<_CustomerSearchSheet> {
  final _searchController = TextEditingController();
  final _dniController = TextEditingController();
  final _rucController = TextEditingController();
  bool _consultingDNI = false;
  bool _consultingRUC = false;

  @override
  void dispose() {
    _searchController.dispose();
    _dniController.dispose();
    _rucController.dispose();
    super.dispose();
  }

  Future<void> _consultDNI() async {
    final dni = _dniController.text.trim();
    if (dni.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un DNI válido (8 dígitos)')),
      );
      return;
    }

    setState(() => _consultingDNI = true);
    final provider = context.read<CustomerProvider>();
    final result = await provider.searchByDNI(dni);

    if (!mounted) return;
    setState(() => _consultingDNI = false);

    if (result.isSuccess && result.data != null) {
      widget.onSelected(result.data!);
    } else {
      final msg = result.error ?? 'No se encontró el DNI';
      final isConfig = msg.contains('no configurada');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isConfig
              ? 'API Inti no configurada. Vaya a Configuración para agregar su token.'
              : msg),
          duration: const Duration(seconds: 4),
          action: isConfig
              ? SnackBarAction(
                  label: 'Configurar',
                  onPressed: () =>
                      Navigator.pushNamed(context, '/settings'),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _consultRUC() async {
    final ruc = _rucController.text.trim();
    if (ruc.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un RUC válido (11 dígitos)')),
      );
      return;
    }

    setState(() => _consultingRUC = true);
    final provider = context.read<CustomerProvider>();
    final result = await provider.searchByRUC(ruc);

    if (!mounted) return;
    setState(() => _consultingRUC = false);

    if (result.isSuccess && result.data != null) {
      widget.onSelected(result.data!);
    } else {
      final msg = result.error ?? 'No se encontró el RUC';
      final isConfig = msg.contains('no configurada');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isConfig
              ? 'API Inti no configurada. Vaya a Configuración para agregar su token.'
              : msg),
          duration: const Duration(seconds: 4),
          action: isConfig
              ? SnackBarAction(
                  label: 'Configurar',
                  onPressed: () =>
                      Navigator.pushNamed(context, '/settings'),
                )
              : null,
        ),
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
                      hintText: '8 dígitos',
                      prefixIcon: const Icon(Icons.person),
                      suffixIcon: _consultingDNI
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.cloud_download),
                              onPressed: _dniController.text.length == 8
                                  ? _consultDNI
                                  : null,
                              tooltip: 'Consultar DNI',
                            ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rucController,
                    decoration: InputDecoration(
                      labelText: 'Consultar RUC',
                      hintText: '11 dígitos',
                      prefixIcon: const Icon(Icons.business),
                      suffixIcon: _consultingRUC
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.cloud_download),
                              onPressed: _rucController.text.length == 11
                                  ? _consultRUC
                                  : null,
                              tooltip: 'Consultar RUC',
                            ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 11,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('o buscar por nombre', style: TextStyle(fontSize: 12)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                        child: Text(c.displayName.isNotEmpty ? c.displayName[0] : '?'),
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
                          child: Text(p.code.isNotEmpty ? p.code[0] : 'P')),
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
