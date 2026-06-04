class DocumentItem {
  final int? id;
  final int documentId;
  final int productId;
  final String productCode;
  final String productName;
  final double quantity;
  final String unitType;
  final double unitPrice;
  final double subtotal;
  final double igv;
  final double total;

  DocumentItem({
    this.id,
    required this.documentId,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.quantity,
    this.unitType = 'UNIDAD',
    required this.unitPrice,
    required this.subtotal,
    required this.igv,
    required this.total,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'document_id': documentId,
        'product_id': productId,
        'product_code': productCode,
        'product_name': productName,
        'quantity': quantity,
        'unit_type': unitType,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'igv': igv,
        'total': total,
      };

  DocumentItem copyWith({
    int? id,
    int? documentId,
    int? productId,
    String? productCode,
    String? productName,
    double? quantity,
    String? unitType,
    double? unitPrice,
    double? subtotal,
    double? igv,
    double? total,
  }) =>
      DocumentItem(
        id: id ?? this.id,
        documentId: documentId ?? this.documentId,
        productId: productId ?? this.productId,
        productCode: productCode ?? this.productCode,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitType: unitType ?? this.unitType,
        unitPrice: unitPrice ?? this.unitPrice,
        subtotal: subtotal ?? this.subtotal,
        igv: igv ?? this.igv,
        total: total ?? this.total,
      );

  factory DocumentItem.fromMap(Map<String, dynamic> map) => DocumentItem(
        id: map['id'],
        documentId: map['document_id'],
        productId: map['product_id'],
        productCode: map['product_code'],
        productName: map['product_name'],
        quantity: (map['quantity'] ?? 0).toDouble(),
        unitType: map['unit_type'] ?? 'UNIDAD',
        unitPrice: (map['unit_price'] ?? 0).toDouble(),
        subtotal: (map['subtotal'] ?? 0).toDouble(),
        igv: (map['igv'] ?? 0).toDouble(),
        total: (map['total'] ?? 0).toDouble(),
      );
}

class InvoiceDocument {
  final int? id;
  final int companyId;
  final int? customerId;
  final String documentType;
  final String series;
  final int number;
  final String customerDocType;
  final String customerDocNumber;
  final String customerName;
  final String customerAddress;
  final DateTime issueDate;
  final double subtotal;
  final double igv;
  final double total;
  final String paymentMethod;
  final String status;
  final String? sunatTicket;
  final String? sunatCdr;
  final String? notes;
  final String taxRegime;
  final DateTime? deliveryDate;
  final String deliveryAddress;

  InvoiceDocument({
    this.id,
    required this.companyId,
    this.customerId,
    required this.documentType,
    required this.series,
    required this.number,
    required this.customerDocType,
    required this.customerDocNumber,
    required this.customerName,
    this.customerAddress = '',
    DateTime? issueDate,
    this.subtotal = 0,
    this.igv = 0,
    this.total = 0,
    this.paymentMethod = 'Efectivo',
    this.status = 'EMITIDO',
    this.sunatTicket,
    this.sunatCdr,
    this.notes,
    this.taxRegime = 'GENERAL',
    this.deliveryDate,
    this.deliveryAddress = '',
  }) : issueDate = issueDate ?? DateTime.now();

  String get documentNumber => '$series-$number';

  String get statusLabel {
    switch (status) {
      case 'BORRADOR':
        return 'Borrador';
      case 'PEDIDO':
        return 'Pedido';
      case 'EMITIDO':
        return 'Emitido';
      case 'ENVIADO':
        return 'Enviado a SUNAT';
      case 'ACEPTADO':
        return 'Aceptado por SUNAT';
      case 'RECHAZADO':
        return 'Rechazado por SUNAT';
      default:
        return status;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'customer_id': customerId,
        'document_type': documentType,
        'series': series,
        'number': number,
        'customer_doc_type': customerDocType,
        'customer_doc_number': customerDocNumber,
        'customer_name': customerName,
        'customer_address': customerAddress,
        'issue_date': issueDate.toIso8601String(),
        'subtotal': subtotal,
        'igv': igv,
        'total': total,
        'payment_method': paymentMethod,
        'status': status,
        'sunat_ticket': sunatTicket,
        'sunat_cdr': sunatCdr,
        'notes': notes,
        'tax_regime': taxRegime,
        'delivery_date': deliveryDate?.toIso8601String(),
        'delivery_address': deliveryAddress,
      };

  factory InvoiceDocument.fromMap(Map<String, dynamic> map) => InvoiceDocument(
        id: map['id'],
        companyId: map['company_id'],
        customerId: map['customer_id'],
        documentType: map['document_type'],
        series: map['series'],
        number: map['number'],
        customerDocType: map['customer_doc_type'],
        customerDocNumber: map['customer_doc_number'],
        customerName: map['customer_name'],
        customerAddress: map['customer_address'] ?? '',
        issueDate: map['issue_date'] != null
            ? DateTime.parse(map['issue_date'])
            : DateTime.now(),
        subtotal: (map['subtotal'] ?? 0).toDouble(),
        igv: (map['igv'] ?? 0).toDouble(),
        total: (map['total'] ?? 0).toDouble(),
        paymentMethod: map['payment_method'] ?? 'Efectivo',
        status: map['status'] ?? 'EMITIDO',
        sunatTicket: map['sunat_ticket'],
        sunatCdr: map['sunat_cdr'],
        notes: map['notes'],
        taxRegime: map['tax_regime'] ?? 'GENERAL',
        deliveryDate: map['delivery_date'] != null
            ? DateTime.tryParse(map['delivery_date'])
            : null,
        deliveryAddress: map['delivery_address'] ?? '',
      );

  InvoiceDocument copyWith({
    int? id,
    int? companyId,
    int? customerId,
    String? documentType,
    String? series,
    int? number,
    String? customerDocType,
    String? customerDocNumber,
    String? customerName,
    String? customerAddress,
    DateTime? issueDate,
    double? subtotal,
    double? igv,
    double? total,
    String? paymentMethod,
    String? status,
    String? sunatTicket,
    String? sunatCdr,
    String? notes,
    String? taxRegime,
    DateTime? deliveryDate,
    String? deliveryAddress,
  }) =>
      InvoiceDocument(
        id: id ?? this.id,
        companyId: companyId ?? this.companyId,
        customerId: customerId ?? this.customerId,
        documentType: documentType ?? this.documentType,
        series: series ?? this.series,
        number: number ?? this.number,
        customerDocType: customerDocType ?? this.customerDocType,
        customerDocNumber: customerDocNumber ?? this.customerDocNumber,
        customerName: customerName ?? this.customerName,
        customerAddress: customerAddress ?? this.customerAddress,
        issueDate: issueDate ?? this.issueDate,
        subtotal: subtotal ?? this.subtotal,
        igv: igv ?? this.igv,
        total: total ?? this.total,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        status: status ?? this.status,
        sunatTicket: sunatTicket ?? this.sunatTicket,
        sunatCdr: sunatCdr ?? this.sunatCdr,
        notes: notes ?? this.notes,
        taxRegime: taxRegime ?? this.taxRegime,
        deliveryDate: deliveryDate ?? this.deliveryDate,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      );
}
