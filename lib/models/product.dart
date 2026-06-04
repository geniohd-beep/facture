class Product {
  final int? id;
  final String code;
  final String name;
  final String description;
  final String category;
  final double purchasePrice;
  final double salePrice;
  final int stock;
  final String unitType;
  final bool isActive;

  Product({
    this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.category = '',
    required this.purchasePrice,
    required this.salePrice,
    this.stock = 0,
    this.unitType = 'UNIDAD',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
        'category': category,
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'stock': stock,
        'unit_type': unitType,
        'is_active': isActive ? 1 : 0,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        code: map['code'],
        name: map['name'],
        description: map['description'] ?? '',
        category: map['category'] ?? '',
        purchasePrice: (map['purchase_price'] ?? 0).toDouble(),
        salePrice: (map['sale_price'] ?? 0).toDouble(),
        stock: map['stock'] ?? 0,
        unitType: map['unit_type'] ?? 'UNIDAD',
        isActive: map['is_active'] == 1,
      );

  Product copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? stock,
    String? unitType,
    bool? isActive,
  }) =>
      Product(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        salePrice: salePrice ?? this.salePrice,
        stock: stock ?? this.stock,
        unitType: unitType ?? this.unitType,
        isActive: isActive ?? this.isActive,
      );
}
