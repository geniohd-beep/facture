class Customer {
  final int? id;
  final String documentType;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String fullName;
  final String address;
  final String phone;
  final String email;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.documentType,
    required this.documentNumber,
    this.firstName = '',
    this.lastName = '',
    this.fullName = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName =>
      fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim();

  Map<String, dynamic> toMap() => {
        'id': id,
        'document_type': documentType,
        'document_number': documentNumber,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'address': address,
        'phone': phone,
        'email': email,
        'created_at': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        documentType: map['document_type'],
        documentNumber: map['document_number'],
        firstName: map['first_name'] ?? '',
        lastName: map['last_name'] ?? '',
        fullName: map['full_name'] ?? '',
        address: map['address'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'])
            : DateTime.now(),
      );

  Customer copyWith({
    int? id,
    String? documentType,
    String? documentNumber,
    String? firstName,
    String? lastName,
    String? fullName,
    String? address,
    String? phone,
    String? email,
  }) =>
      Customer(
        id: id ?? this.id,
        documentType: documentType ?? this.documentType,
        documentNumber: documentNumber ?? this.documentNumber,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        fullName: fullName ?? this.fullName,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        createdAt: createdAt,
      );
}
