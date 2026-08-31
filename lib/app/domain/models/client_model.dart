class ClientModel {
  final String id;
  final String name;
  final String city;
  final String cpf;
  final String rg;
  final int totalDocuments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClientModel({
    required this.id,
    required this.name,
    required this.city,
    required this.cpf,
    required this.rg,
    this.totalDocuments = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      rg: json['rg']?.toString() ?? '',
      totalDocuments: json['total_documents'] is int
          ? json['total_documents'] as int
          : int.tryParse(json['total_documents']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'cpf': cpf,
      'rg': rg,
      'total_documents': totalDocuments,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? city,
    String? cpf,
    String? rg,
    int? totalDocuments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
