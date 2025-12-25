class Material {
  final int? id;
  final String materialCode;
  final String materialName;
  final String category;
  final String grade;
  final String unit;
  final double? standardWeight;
  final double? tolerance;
  final int pricePerKg;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Material({
    this.id,
    required this.materialCode,
    required this.materialName,
    required this.category,
    this.grade = 'Standard',
    this.unit = 'KG',
    this.standardWeight,
    this.tolerance = 0.5,
    this.pricePerKg = 0,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'material_code': materialCode,
      'material_name': materialName,
      'category': category,
      'grade': grade,
      'unit': unit,
      'standard_weight': standardWeight,
      'tolerance': tolerance,
      'price_per_kg': pricePerKg,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Material.fromMap(Map<String, dynamic> map) {
    return Material(
      id: map['id'],
      materialCode: map['material_code'] ?? '',
      materialName: map['material_name'] ?? '',
      category: map['category'] ?? 'General',
      grade: map['grade'] ?? 'Standard',
      unit: map['unit'] ?? 'KG',
      standardWeight: map['standard_weight']?.toDouble(),
      tolerance: map['tolerance']?.toDouble() ?? 0.5,
      pricePerKg: map['price_per_kg'] ?? 0,
      description: map['description'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Material copyWith({
    int? id,
    String? materialCode,
    String? materialName,
    String? category,
    String? grade,
    String? unit,
    double? standardWeight,
    double? tolerance,
    int? pricePerKg,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Material(
      id: id ?? this.id,
      materialCode: materialCode ?? this.materialCode,
      materialName: materialName ?? this.materialName,
      category: category ?? this.category,
      grade: grade ?? this.grade,
      unit: unit ?? this.unit,
      standardWeight: standardWeight ?? this.standardWeight,
      tolerance: tolerance ?? this.tolerance,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getFullName() => '$materialCode - $materialName';
  String getDisplayName() => '$materialName (Grade $grade)';
  bool get hasPrice => pricePerKg > 0;
  bool get hasStandardWeight => standardWeight != null && standardWeight! > 0;

  Map<String, double> getToleranceRange() {
    if (!hasStandardWeight) return {'min': 0, 'max': 0};
    double toleranceValue = standardWeight! * (tolerance! / 100);
    return {
      'min': standardWeight! - toleranceValue,
      'max': standardWeight! + toleranceValue,
    };
  }

  bool isWeightInTolerance(double actualWeight) {
    if (!hasStandardWeight) return true;
    var range = getToleranceRange();
    return actualWeight >= range['min']! && actualWeight <= range['max']!;
  }

  static const List<String> categories = [
    'Raw Material',
    'Semi Finished',
    'Finished Goods',
    'Packaging Material',
    'Waste Material',
    'Scrap',
    'Food Grade',
    'Chemical',
    'Other',
  ];

  static const List<String> grades = [
    'A', 'B', 'C',
    'Premium', 'Standard',
    'Food Grade', 'Industrial Grade', 'Export Quality',
  ];

  static const List<String> units = ['KG', 'GRAM', 'TON', 'LBS', 'OZ'];
}