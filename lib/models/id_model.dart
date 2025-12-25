class IdModel {
  final int? id;
  final String name;
  final String barcode;
  final String remarks;
  final String createdAt;
  final String? updatedAt;

  IdModel({
    this.id,
    required this.name,
    required this.barcode,
    required this.remarks,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory IdModel.fromMap(Map<String, dynamic> map) {
    return IdModel(
      id: map['id'],
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      remarks: map['remarks'] ?? '',
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'],
    );
  }

  String get displayName => name.isNotEmpty ? name : barcode;
  String get displayFull => '$name${barcode.isNotEmpty ? " ($barcode)" : ""}';
}