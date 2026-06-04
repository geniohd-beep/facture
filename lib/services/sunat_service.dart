import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/constants.dart';
import '../models/company.dart';
import '../models/document.dart';
import '../utils/api_result.dart';

class SunatService {
  String? _apiToken;

  void configure({String? apiToken}) {
    _apiToken = apiToken;
  }

  bool get isConfigured => _apiToken != null;

  Future<ApiResult<Map<String, dynamic>>> sendDocument(
      InvoiceDocument document, List<DocumentItem> items, Company company) async {
    if (_apiToken == null) {
      return ApiResult.failure('API SUNAT no configurada');
    }

    try {
      final body = jsonEncode({
        'rucEmisor': company.ruc,
        'tipoDoc': _getSunatDocType(document.documentType),
        'serie': document.series,
        'correlativo': document.number,
        'fechaEmision': document.issueDate.toIso8601String(),
        'tipoDocCliente': document.customerDocType == 'DNI' ? '1' : '6',
        'numDocCliente': document.customerDocNumber,
        'razonSocialCliente': document.customerName,
        'direccionCliente': document.customerAddress,
        'totalOperacionesGravadas': document.subtotal,
        'totalIGV': document.igv,
        'total': document.total,
        'items': items
            .map((item) => {
                  'codigo': item.productCode,
                  'descripcion': item.productName,
                  'cantidad': item.quantity,
                  'unidadMedida': item.unitType,
                  'precioUnitario': item.unitPrice,
                  'subtotal': item.subtotal,
                  'igv': item.igv,
                  'total': item.total,
                })
            .toList(),
      });

      final response = await http.post(
        Uri.parse('${AppConstants.sunatApiUrl}/enviar'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResult.success({
          'ticket': data['ticket'],
          'cdr': data['cdr'],
          'message': 'Documento enviado correctamente',
        });
      }

      return ApiResult.failure('Error al enviar a SUNAT: ${response.statusCode} - ${response.body}');
    } catch (e) {
      return ApiResult.failure('Error de conexión con SUNAT: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> consultStatus(String ticket) async {
    if (_apiToken == null) {
      return ApiResult.failure('API SUNAT no configurada');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.sunatApiUrl}/consultar/$ticket'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResult.success({
          'estado': data['estado'],
          'cdr': data['cdr'],
        });
      }

      return ApiResult.failure('Error al consultar ticket SUNAT: ${response.statusCode}');
    } catch (e) {
      return ApiResult.failure('Error de conexión con SUNAT: $e');
    }
  }

  String _getSunatDocType(String docType) {
    switch (docType) {
      case 'Factura Electrónica':
        return '01';
      case 'Boleta Electrónica':
        return '03';
      case 'Nota de Crédito':
        return '07';
      case 'Nota de Débito':
        return '08';
      case 'Guía de Remisión':
        return '09';
      default:
        return '00';
    }
  }

  Future<void> generateAndPrintDocument(
    InvoiceDocument document,
    List<DocumentItem> items,
    Company company,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(company, document),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(document),
          pw.SizedBox(height: 20),
          _buildItemsTable(items),
          pw.SizedBox(height: 16),
          _buildTotals(document),
          pw.SizedBox(height: 30),
          _buildFooter(document),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          '${document.documentType.replaceAll(' ', '_')}_${document.documentNumber}.pdf',
    );
  }

  pw.Widget _buildHeader(Company company, InvoiceDocument document) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(company.businessName,
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(company.tradeName,
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text(company.address, style: const pw.TextStyle(fontSize: 10)),
            pw.Text('RUC: ${company.ruc}',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(document.documentType.toUpperCase(),
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('R.U.C.: ${company.ruc}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text(document.documentNumber,
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(InvoiceDocument document) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text('Cliente: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(document.customerName),
            ],
          ),
          pw.Row(
            children: [
              pw.Text('${document.customerDocType}: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(document.customerDocNumber),
            ],
          ),
          if (document.customerAddress.isNotEmpty)
            pw.Row(
              children: [
                pw.Text('Dirección: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(document.customerAddress),
              ],
            ),
          pw.Row(
            children: [
              pw.Text('Fecha Emisión: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  '${document.issueDate.day}/${document.issueDate.month}/${document.issueDate.year}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<DocumentItem> items) {
    const tableHeaders = ['Cant.', 'Descripción', 'P.Unit', 'Importe'];

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FixedColumnWidth(50),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(80),
      },
      children: [
         pw.TableRow(
           decoration: pw.BoxDecoration(color: PdfColors.grey300),
           children: tableHeaders
               .map((h) => pw.Padding(
                     padding: const pw.EdgeInsets.all(4),
                     child: pw.Text(h,
                         style: pw.TextStyle(
                             fontWeight: pw.FontWeight.bold, fontSize: 10)),
                   ))
               .toList(),
         ),
         ...items.map((item) => pw.TableRow(
               children: [
                 pw.Padding(
                   padding: const pw.EdgeInsets.all(4),
                   child: pw.Text(item.quantity.toStringAsFixed(2),
                       style: const pw.TextStyle(fontSize: 10)),
                 ),
                 pw.Padding(
                   padding: const pw.EdgeInsets.all(4),
                   child: pw.Text(item.productName,
                       style: const pw.TextStyle(fontSize: 10)),
                 ),
                 pw.Padding(
                   padding: const pw.EdgeInsets.all(4),
                   child: pw.Text('S/ ${item.unitPrice.toStringAsFixed(2)}',
                       style: const pw.TextStyle(fontSize: 10)),
                 ),
                 pw.Padding(
                   padding: const pw.EdgeInsets.all(4),
                   child: pw.Text('S/ ${item.total.toStringAsFixed(2)}',
                       style: const pw.TextStyle(fontSize: 10)),
                 ),
               ],
             )),
      ],
    );
  }

  pw.Widget _buildTotals(InvoiceDocument document) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('Op. Gravadas: S/ ${document.subtotal.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10)),
          pw.Text('IGV: S/ ${document.igv.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10)),
          pw.Text('Total: S/ ${document.total.toStringAsFixed(2)}',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(InvoiceDocument document) {
    return pw.Column(
      children: [
        pw.Divider(),
          pw.Text(
            'Representación impresa de la factura electrónica',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Consulte en www.sunat.gob.pe',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
      ],
    );
  }
}
