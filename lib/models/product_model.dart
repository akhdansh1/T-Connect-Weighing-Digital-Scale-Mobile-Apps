class ProductModel {
  final int? id;
  final String number;
  final String productCode;
  final String productName;
  final String materialCode;
  final double unitWeight;
  final double preTare;
  final double hiLimit;
  final double targetValue;
  final double lowLimit;
  final double minimumLimit;
  final double looses;
  final String killDate;
  final String packingDate;
  final String useByDate;
  final String labelFormat;
  final int labelTotal;
  final String traceGroups;
  final String groupSelected;
  final String inputSet;
  final String description;
  final String createdAt;

  ProductModel({
    this.id,
    required this.number,
    required this.productCode,
    required this.productName,
    this.materialCode = '',
    required this.unitWeight,
    required this.preTare,
    required this.hiLimit,
    required this.targetValue,
    required this.lowLimit,
    required this.minimumLimit,
    required this.looses,
    required this.killDate,
    required this.packingDate,
    required this.useByDate,
    required this.labelFormat,
    required this.labelTotal,
    required this.traceGroups,
    required this.groupSelected,
    required this.inputSet,
    required this.description,
    required this.createdAt,
  });

  bool get isReadyForBasicCountingMode {
    return unitWeight > 0;
  }

  bool get isReadyForFullCountingMode {
    return unitWeight > 0 && 
           targetValue > 0 && 
           lowLimit > 0 && 
           hiLimit > 0;
  }

  bool get isReadyForCountingMode {
    return isReadyForBasicCountingMode;
  }

  String get countingModeInfo {
    if (isReadyForFullCountingMode) {
      return 'UW: ${(unitWeight * 1000).toStringAsFixed(1)} g/pcs | '
             'Target: $targetValue kg | '
             'Range: $lowLimit - $hiLimit kg';
    } else if (isReadyForBasicCountingMode) {
      return 'UW: ${(unitWeight * 1000).toStringAsFixed(1)} g/pcs | '
             'Mode: Basic Counting (No threshold)';
    }
    return 'Incomplete data for Counting Mode';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'product_code': productCode,
      'product_name': productName,
      'material_code': materialCode,
      'unit_weight': unitWeight,
      'pre_tare': preTare,
      'hi_limit': hiLimit,
      'target_value': targetValue,
      'low_limit': lowLimit,
      'minimum_limit': minimumLimit,
      'looses': looses,
      'kill_date': killDate,
      'packing_date': packingDate,
      'use_by_date': useByDate,
      'label_format': labelFormat,
      'label_total': labelTotal,
      'trace_groups': traceGroups,
      'group_selected': groupSelected,
      'input_set': inputSet,
      'description': description,
      'created_at': createdAt,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      number: map['number'] ?? '',
      productCode: map['product_code'] ?? '',
      productName: map['product_name'] ?? '',
      materialCode: map['material_code'] ?? '',
      unitWeight: (map['unit_weight'] ?? 0.0).toDouble(),
      preTare: (map['pre_tare'] ?? 0.0).toDouble(),
      hiLimit: (map['hi_limit'] ?? 0.0).toDouble(),
      targetValue: (map['target_value'] ?? 0.0).toDouble(),
      lowLimit: (map['low_limit'] ?? 0.0).toDouble(),
      minimumLimit: (map['minimum_limit'] ?? 0.0).toDouble(),
      looses: (map['looses'] ?? 0.0).toDouble(),
      killDate: map['kill_date'] ?? '',
      packingDate: map['packing_date'] ?? '',
      useByDate: map['use_by_date'] ?? '',
      labelFormat: map['label_format'] ?? '',
      labelTotal: map['label_total'] ?? 1,
      traceGroups: map['trace_groups'] ?? '',
      groupSelected: map['group_selected'] ?? '',
      inputSet: map['input_set'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}