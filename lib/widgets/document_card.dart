import 'package:flutter/material.dart';
import '../models/document.dart';

class DocumentCard extends StatelessWidget {
  final InvoiceDocument document;
  final VoidCallback onTap;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: _buildTypeIcon(theme),
        title: Text(
          document.documentNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.customerName,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${document.issueDate.day}/${document.issueDate.month}/${document.issueDate.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'S/ ${document.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(theme).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                document.statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: _statusColor(theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ThemeData theme) {
    IconData icon;
    Color color;

    switch (document.documentType) {
      case 'Factura Electrónica':
        icon = Icons.receipt_long;
        color = Colors.blue;
        break;
      case 'Boleta Electrónica':
        icon = Icons.receipt;
        color = Colors.green;
        break;
      case 'Nota de Crédito':
        icon = Icons.assignment_return;
        color = Colors.orange;
        break;
      case 'Nota de Débito':
        icon = Icons.assignment_late;
        color = Colors.red;
        break;
      case 'Nota de Venta':
        icon = Icons.shopping_cart;
        color = Colors.teal;
        break;
      default:
        icon = Icons.description;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  Color _statusColor(ThemeData theme) {
    switch (document.status) {
      case 'BORRADOR':
        return Colors.grey;
      case 'PEDIDO':
        return Colors.purple;
      case 'EMITIDO':
        return Colors.orange;
      case 'ENVIADO':
        return Colors.blue;
      case 'ACEPTADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }
}
