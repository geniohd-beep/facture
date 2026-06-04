class KardexEntry {
  final int? id;
  final int productId;
  final String productCode;
  final String productName;
  final DateTime date;
  final String documentType;
  final String? documentNumber;
  final String reference;
  final double quantityIn;
  final double quantityOut;
  final int stockBalance;
  final double unitPrice;
  final double totalValue;

  KardexEntry({
    this.id,
    required this.productId,
    required this.productCode,
    required this.productName,
    DateTime? date,
    required this.documentType,
    this.documentNumber,
    this.reference = '',
    this.quantityIn = 0,
    this.quantityOut = 0,
    required this.stockBalance,
    this.unitPrice = 0,
    this.totalValue = 0,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'product_code': productCode,
        'product_name': productName,
        'date': date.toIso8601String(),
        'document_type': documentType,
        'document_number': documentNumber,
        'reference': reference,
        'quantity_in': quantityIn,
        'quantity_out': quantityOut,
        'stock_balance': stockBalance,
        'unit_price': unitPrice,
        'total_value': totalValue,
      };

  factory KardexEntry.fromMap(Map<String, dynamic> map) => KardexEntry(
        id: map['id'],
        productId: map['product_id'],
        productCode: map['product_code'],
        productName: map['product_name'],
        date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
        documentType: map['document_type'],
        documentNumber: map['document_number'],
        reference: map['reference'] ?? '',
        quantityIn: (map['quantity_in'] ?? 0).toDouble(),
        quantityOut: (map['quantity_out'] ?? 0).toDouble(),
        stockBalance: map['stock_balance'] ?? 0,
        unitPrice: (map['unit_price'] ?? 0).toDouble(),
        totalValue: (map['total_value'] ?? 0).toDouble(),
      );
}
