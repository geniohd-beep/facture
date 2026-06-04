import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/customer_search.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final List<TextEditingController> _addressControllers = [TextEditingController()];
  final List<TextEditingController> _phoneControllers = [TextEditingController()];
  final List<TextEditingController> _emailControllers = [TextEditingController()];
  String _docType = 'DNI';
  bool _isConsulting = false;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _initialized = false;
  bool _fromApi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments as Customer?;
      if (args != null) {
        _isEditing = true;
        _fromApi = args.fromApi;
        _docType = args.documentType;
        _docNumberController.text = args.documentNumber;
        _firstNameController.text = args.firstName;
        _lastNameController.text = args.lastName;
        _initMultiControllers(_addressControllers, args.address);
        _initMultiControllers(_phoneControllers, args.phone);
        _initMultiControllers(_emailControllers, args.email);
      }
    }
  }

  void _initMultiControllers(List<TextEditingController> controllers, String value) {
    final parts = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    controllers.clear();
    if (parts.isEmpty) {
      controllers.add(TextEditingController());
    } else {
      for (final part in parts) {
        controllers.add(TextEditingController(text: part));
      }
    }
  }

  @override
  void dispose() {
    _docNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    for (final c in _addressControllers) { c.dispose(); }
    for (final c in _phoneControllers) { c.dispose(); }
    for (final c in _emailControllers) { c.dispose(); }
    super.dispose();
  }

  void _addController(List<TextEditingController> list) {
    setState(() => list.add(TextEditingController()));
  }

  void _removeController(List<TextEditingController> list, int index) {
    if (list.length <= 1) return;
    setState(() {
      list[index].dispose();
      list.removeAt(index);
    });
  }

  Future<void> _consultDocument() async {
    final number = _docNumberController.text.trim();
    if (number.length < 8) return;

    setState(() => _isConsulting = true);

    final provider = context.read<CustomerProvider>();
    final result = _docType == 'DNI'
        ? await provider.searchByDNI(number)
        : await provider.searchByRUC(number);

    if (!mounted) return;
    setState(() => _isConsulting = false);

    if (result.isSuccess && result.data != null) {
      final customer = result.data!;
      _fromApi = customer.fromApi;
      _firstNameController.text = customer.firstName;
      _lastNameController.text = customer.lastName;
      _initMultiControllers(_addressControllers, customer.address);
      _initMultiControllers(_phoneControllers, customer.phone);
      _initMultiControllers(_emailControllers, customer.email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'No se encontraron datos')),
      );
    }
  }

  String _joinControllers(List<TextEditingController> list) {
    return list.map((c) => c.text.trim()).where((s) => s.isNotEmpty).join(', ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final customer = Customer(
      documentType: _docType,
      documentNumber: _docNumberController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      fullName:
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim(),
      address: _joinControllers(_addressControllers),
      phone: _joinControllers(_phoneControllers),
      email: _joinControllers(_emailControllers),
      fromApi: _fromApi,
    );

    final result = await context.read<CustomerProvider>().saveCustomer(customer);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result == 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente guardado')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $result')),
      );
    }
  }

  Widget _buildMultiField({
    required String label,
    required List<TextEditingController> controllers,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < controllers.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: i == 0 ? label : '$label ${i + 1}',
                    prefixIcon: Icon(icon, size: 18),
                  ),
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                ),
              ),
              if (!readOnly) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: controllers.length > 1
                      ? () => _removeController(controllers, i)
                      : null,
                  color: Colors.red,
                  tooltip: 'Eliminar',
                ),
                if (i == controllers.length - 1)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => _addController(controllers),
                    color: Colors.green,
                    tooltip: 'Agregar otro',
                  ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Cliente' : 'Nuevo Cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _fromApi
                        ? TextFormField(
                            initialValue: _docType,
                            decoration: const InputDecoration(labelText: 'Tipo Doc.'),
                            readOnly: true,
                          )
                        : DocumentTypeSelector(
                            initialValue: _docType,
                            onChanged: (v) => setState(() => _docType = v!),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DocumentNumberField(
                      docType: _docType,
                      controller: _docNumberController,
                      isLoading: _isConsulting,
                      onConsult: _fromApi ? null : _consultDocument,
                      readOnly: _fromApi,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Nombres'),
                textCapitalization: TextCapitalization.words,
                readOnly: _fromApi,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                textCapitalization: TextCapitalization.words,
                readOnly: _fromApi,
              ),
              const SizedBox(height: 16),
              _buildMultiField(
                label: 'Dirección',
                controllers: _addressControllers,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildMultiField(
                label: 'Teléfono',
                controllers: _phoneControllers,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildMultiField(
                label: 'Email',
                controllers: _emailControllers,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
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
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
