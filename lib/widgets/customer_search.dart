import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentTypeSelector extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const DocumentTypeSelector({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: const InputDecoration(labelText: 'Tipo Documento'),
      items: const [
        DropdownMenuItem(value: 'DNI', child: Text('DNI')),
        DropdownMenuItem(value: 'RUC', child: Text('RUC')),
        DropdownMenuItem(value: 'CE', child: Text('Carné Extranjería')),
      ],
      onChanged: onChanged,
    );
  }
}

class DocumentNumberField extends StatelessWidget {
  final String? docType;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback? onConsult;
  final bool readOnly;

  const DocumentNumberField({
    super.key,
    required this.docType,
    required this.controller,
    this.isLoading = false,
    this.onConsult,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: 'N° Documento',
        suffixIcon: readOnly
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: docType != null && controller.text.length >= 8
                          ? onConsult
                          : null,
                      tooltip: 'Consultar RENIEC/SUNAT',
                    ),
                ],
              ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(docType == 'RUC' ? 11 : 8),
      ],
      onChanged: (_) {},
    );
  }
}
