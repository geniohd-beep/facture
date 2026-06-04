import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/company.dart';
import '../../providers/company_provider.dart';

class CompanyFormScreen extends StatefulWidget {
  const CompanyFormScreen({super.key});

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rucController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments as Company?;
      if (args != null) {
        _isEditing = true;
        _rucController.text = args.ruc;
        _businessNameController.text = args.businessName;
        _tradeNameController.text = args.tradeName;
        _addressController.text = args.address;
        _phoneController.text = args.phone;
        _emailController.text = args.email;
      }
    }
  }

  @override
  void dispose() {
    _rucController.dispose();
    _businessNameController.dispose();
    _tradeNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final company = Company(
      ruc: _rucController.text.trim(),
      businessName: _businessNameController.text.trim().toUpperCase(),
      tradeName: _tradeNameController.text.trim().toUpperCase(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    final result = await context.read<CompanyProvider>().saveCompany(company);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result == 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Empresa actualizada' : 'Empresa registrada')),
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
        title: Text(_isEditing ? 'Editar Empresa' : 'Nueva Empresa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _rucController,
                decoration: const InputDecoration(labelText: 'RUC'),
                maxLength: 11,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v?.length ?? 0) < 11 ? 'Ingrese RUC válido (11 dígitos)' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Razón Social'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Ingrese la razón social' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tradeNameController,
                decoration: const InputDecoration(labelText: 'Nombre Comercial'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Ingrese el nombre comercial' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                maxLines: 2,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Ingrese la dirección' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
