class ApiConsultationStats {
  final int? id;
  final String provider;
  final String documentType;
  final String documentNumber;
  final bool success;
  final DateTime createdAt;

  ApiConsultationStats({
    this.id,
    required this.provider,
    required this.documentType,
    required this.documentNumber,
    required this.success,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const String tableName = 'api_consultation_stats';

  Map<String, dynamic> toMap() => {
        'id': id,
        'provider': provider,
        'document_type': documentType,
        'document_number': documentNumber,
        'success': success ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory ApiConsultationStats.fromMap(Map<String, dynamic> map) =>
      ApiConsultationStats(
        id: map['id'],
        provider: map['provider'],
        documentType: map['document_type'],
        documentNumber: map['document_number'],
        success: map['success'] == 1,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'])
            : DateTime.now(),
      );

  factory ApiConsultationStats.summary(
      Map<String, dynamic> map) {
    return ApiConsultationStats(
      provider: map['provider'],
      documentType: '',
      documentNumber: '',
      success: true,
      createdAt: DateTime.now(),
    );
  }
}
