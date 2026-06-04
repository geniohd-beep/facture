class Company {
  final int? id;
  final String ruc;
  final String businessName;
  final String tradeName;
  final String address;
  final String phone;
  final String email;
  final String logoPath;
  final bool isActive;

  Company({
    this.id,
    required this.ruc,
    required this.businessName,
    required this.tradeName,
    required this.address,
    this.phone = '',
    this.email = '',
    this.logoPath = '',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ruc': ruc,
        'business_name': businessName,
        'trade_name': tradeName,
        'address': address,
        'phone': phone,
        'email': email,
        'logo_path': logoPath,
        'is_active': isActive ? 1 : 0,
      };

  factory Company.fromMap(Map<String, dynamic> map) => Company(
        id: map['id'],
        ruc: map['ruc'],
        businessName: map['business_name'],
        tradeName: map['trade_name'],
        address: map['address'],
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        logoPath: map['logo_path'] ?? '',
        isActive: map['is_active'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'ruc': ruc,
        'businessName': businessName,
        'tradeName': tradeName,
        'address': address,
      };

  Company copyWith({
    int? id,
    String? ruc,
    String? businessName,
    String? tradeName,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
    bool? isActive,
  }) =>
      Company(
        id: id ?? this.id,
        ruc: ruc ?? this.ruc,
        businessName: businessName ?? this.businessName,
        tradeName: tradeName ?? this.tradeName,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        logoPath: logoPath ?? this.logoPath,
        isActive: isActive ?? this.isActive,
      );
}
