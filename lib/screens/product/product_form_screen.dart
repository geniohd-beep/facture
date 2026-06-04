import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _unitTypeController = TextEditingController(text: 'UNIDAD');
  String _selectedCategory = '';
  bool _customCategory = false;
  bool _isEditing = false;
  bool _isSaving = false;
  int? _editingId;

  static const _categoryOptions = [
    'ABARROTES',
    'BEBIDAS',
    'LÁCTEOS',
    'PANADERÍA',
    'CARNES',
    'FRUTAS Y VERDURAS',
    'LIMPIEZA',
    'HIGIENE',
    'ELECTRÓNICA',
    'ROPA',
    'CALZADO',
    'HERRAMIENTAS',
    'OFICINA',
    'OTROS',
  ];

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments as Product?;
    if (args != null) {
      _isEditing = true;
      _editingId = args.id;
      _codeController.text = args.code;
      _nameController.text = args.name;
      _descriptionController.text = args.description;
      _categoryController.text = args.category;
      _purchasePriceController.text = args.purchasePrice.toStringAsFixed(2);
      _salePriceController.text = args.salePrice.toStringAsFixed(2);
      _stockController.text = args.stock.toString();
      _unitTypeController.text = args.unitType;
      if (_categoryOptions.contains(args.category.toUpperCase())) {
        _selectedCategory = args.category.toUpperCase();
      } else if (args.category.isNotEmpty) {
        _customCategory = true;
        _selectedCategory = 'OTROS';
        _categoryController.text = args.category;
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _unitTypeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final product = Product(
      id: _editingId,
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim().toUpperCase(),
      description: _descriptionController.text.trim(),
      category: _customCategory
          ? _categoryController.text.trim().toUpperCase()
          : _selectedCategory,
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
      salePrice: double.tryParse(_salePriceController.text) ?? 0,
      stock: int.tryParse(_stockController.text) ?? 0,
      unitType: _unitTypeController.text.trim().toUpperCase(),
    );

    final result = await context.read<ProductProvider>().saveProduct(product);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result == 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Producto actualizado' : 'Producto registrado')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $result')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Código'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Ingrese el código' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration:
                          const InputDecoration(labelText: 'Precio Compra'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceController,
                      decoration:
                          const InputDecoration(labelText: 'Precio Venta'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final price = double.tryParse(v ?? '');
                        if (price == null || price <= 0) {
                          return 'Ingrese un precio válido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitTypeController,
                      decoration:
                          const InputDecoration(labelText: 'Unidad'),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: _categoryOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCategory = v!;
                    _customCategory = v == 'OTROS';
                    if (!_customCategory) _categoryController.clear();
                  });
                },
              ),
              if (_customCategory) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Especifique categoría',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
