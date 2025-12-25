import 'dart:math';
class QCReport {
  final int? id;
  final String reportNumber;
  final DateTime inspectionDate;
  final String inspectorCode;
  final String inspectorName;
  final String? supervisorName;
  
  final String productCode;
  final String productName;
  final String category;
  final String grade;
  final String? batchNumber;
  final String? lotNumber;
  final DateTime? productionDate;
  final DateTime? expiryDate;
  
  final double targetWeight;
  final String unit;
  final double tolerance; 
  final double toleranceMin;
  final double toleranceMax;
  
  final double sample1Weight;
  final double? sample2Weight;
  final double? sample3Weight;
  final double averageWeight;
  final double? standardDeviation;
  
  final String result;
  final String? remarks;
  final bool isApproved;
  final DateTime? approvedDate;
  final String? approvedBy;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  QCReport({
    this.id,
    required this.reportNumber,
    required this.inspectionDate,
    required this.inspectorCode,
    required this.inspectorName,
    this.supervisorName,
    required this.productCode,
    required this.productName,
    required this.category,
    this.grade = 'Standard',
    this.batchNumber,
    this.lotNumber,
    this.productionDate,
    this.expiryDate,
    required this.targetWeight,
    this.unit = 'KG',
    this.tolerance = 0.5,
    required this.toleranceMin,
    required this.toleranceMax,
    required this.sample1Weight,
    this.sample2Weight,
    this.sample3Weight,
    required this.averageWeight,
    this.standardDeviation,
    required this.result,
    this.remarks,
    this.isApproved = false,
    this.approvedDate,
    this.approvedBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_number': reportNumber,
      'inspection_date': inspectionDate.toIso8601String(),
      'inspector_code': inspectorCode,
      'inspector_name': inspectorName,
      'supervisor_name': supervisorName,
      'product_code': productCode,
      'product_name': productName,
      'category': category,
      'grade': grade,
      'batch_number': batchNumber,
      'lot_number': lotNumber,
      'production_date': productionDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'target_weight': targetWeight,
      'unit': unit,
      'tolerance': tolerance,
      'tolerance_min': toleranceMin,
      'tolerance_max': toleranceMax,
      'sample1_weight': sample1Weight,
      'sample2_weight': sample2Weight,
      'sample3_weight': sample3Weight,
      'average_weight': averageWeight,
      'standard_deviation': standardDeviation,
      'result': result,
      'remarks': remarks,
      'is_approved': isApproved ? 1 : 0,
      'approved_date': approvedDate?.toIso8601String(),
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory QCReport.fromMap(Map<String, dynamic> map) {
    return QCReport(
      id: map['id'],
      reportNumber: map['report_number'] ?? '',
      inspectionDate: DateTime.parse(map['inspection_date']),
      inspectorCode: map['inspector_code'] ?? '',
      inspectorName: map['inspector_name'] ?? '',
      supervisorName: map['supervisor_name'],
      productCode: map['product_code'] ?? '',
      productName: map['product_name'] ?? '',
      category: map['category'] ?? '',
      grade: map['grade'] ?? 'Standard',
      batchNumber: map['batch_number'],
      lotNumber: map['lot_number'],
      productionDate: map['production_date'] != null ? DateTime.parse(map['production_date']) : null,
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
      targetWeight: map['target_weight']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'KG',
      tolerance: map['tolerance']?.toDouble() ?? 0.5,
      toleranceMin: map['tolerance_min']?.toDouble() ?? 0.0,
      toleranceMax: map['tolerance_max']?.toDouble() ?? 0.0,
      sample1Weight: map['sample1_weight']?.toDouble() ?? 0.0,
      sample2Weight: map['sample2_weight']?.toDouble(),
      sample3Weight: map['sample3_weight']?.toDouble(),
      averageWeight: map['average_weight']?.toDouble() ?? 0.0,
      standardDeviation: map['standard_deviation']?.toDouble(),
      result: map['result'] ?? 'PENDING',
      remarks: map['remarks'],
      isApproved: map['is_approved'] == 1,
      approvedDate: map['approved_date'] != null ? DateTime.parse(map['approved_date']) : null,
      approvedBy: map['approved_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  static String generateReportNumber() {
    DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString().padLeft(2, '0');
    int sequence = now.millisecondsSinceEpoch % 10000;
    return 'QC-$year-$month-${sequence.toString().padLeft(4, '0')}';
  }

  static double calculateAverage(double s1, double? s2, double? s3) {
    List<double> samples = [s1];
    if (s2 != null) samples.add(s2);
    if (s3 != null) samples.add(s3);
    return samples.reduce((a, b) => a + b) / samples.length;
  }

static double calculateStdDev(double avg, double s1, double? s2, double? s3) {
  List<double> samples = [s1];
  if (s2 != null) samples.add(s2);
  if (s3 != null) samples.add(s3);
  
  double sumSquaredDiff = samples.map((x) => (x - avg) * (x - avg)).fold(0.0, (a, b) => a + b);
  return sqrt(sumSquaredDiff / samples.length);
}

  static bool isWithinTolerance(double actualWeight, double min, double max) {
    return actualWeight >= min && actualWeight <= max;
  }

  bool get isPassed => result.toUpperCase() == 'PASSED';
  bool get isFailed => result.toUpperCase() == 'FAILED';
  bool get hasMultipleSamples => sample2Weight != null || sample3Weight != null;
  bool get hasBatchInfo => batchNumber != null && batchNumber!.isNotEmpty;
}