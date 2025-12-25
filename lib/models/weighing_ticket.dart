class WeighingTicket {
  final int? id;
  final String ticketNumber;        
  final DateTime weighingDate;
  final String operatorCode;
  final String operatorName;
  
  final String materialCode;
  final String materialName;
  final String category;
  final String? batchNumber;
  final String? grade;              
  
  final String? supplierCode;
  final String? supplierName;
  
  final String? vehicleNumber;
  final String? driverName;
  final String? driverPhone;
  
  final double? firstWeight;        // Berat pertama (gross)
  final double? secondWeight;       // Berat kedua (kosong)
  final double netWeight;           // Berat netto
  final double? tareWeight;         // Berat tara
  final String unit;                // KG, TON, LBS
  
  // Additional Info
  final String? poNumber;           // Purchase Order Number
  final String? doNumber;           // Delivery Order Number
  final String? remarks;            // Catatan tambahan
  final String status;              // Completed, Pending, Cancelled
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  WeighingTicket({
    this.id,
    required this.ticketNumber,
    required this.weighingDate,
    required this.operatorCode,
    required this.operatorName,
    required this.materialCode,
    required this.materialName,
    required this.category,
    this.batchNumber,
    this.grade,                     // ✅ NEW
    this.supplierCode,
    this.supplierName,
    this.vehicleNumber,
    this.driverName,
    this.driverPhone,
    this.firstWeight,
    this.secondWeight,
    required this.netWeight,
    this.tareWeight,
    this.unit = 'KG',
    this.poNumber,
    this.doNumber,
    this.remarks,
    this.status = 'Completed',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'weighing_date': weighingDate.toIso8601String(),
      'operator_code': operatorCode,
      'operator_name': operatorName,
      'material_code': materialCode,
      'material_name': materialName,
      'category': category,
      'batch_number': batchNumber,
      'grade': grade,               // ✅ NEW
      'supplier_code': supplierCode,
      'supplier_name': supplierName,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'first_weight': firstWeight,
      'second_weight': secondWeight,
      'net_weight': netWeight,
      'tare_weight': tareWeight,
      'unit': unit,
      'po_number': poNumber,
      'do_number': doNumber,
      'remarks': remarks,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory WeighingTicket.fromMap(Map<String, dynamic> map) {
    return WeighingTicket(
      id: map['id'],
      ticketNumber: map['ticket_number'] ?? '',
      weighingDate: DateTime.parse(map['weighing_date']),
      operatorCode: map['operator_code'] ?? '',
      operatorName: map['operator_name'] ?? '',
      materialCode: map['material_code'] ?? '',
      materialName: map['material_name'] ?? '',
      category: map['category'] ?? '',
      batchNumber: map['batch_number'],
      grade: map['grade'],          // ✅ NEW
      supplierCode: map['supplier_code'],
      supplierName: map['supplier_name'],
      vehicleNumber: map['vehicle_number'],
      driverName: map['driver_name'],
      driverPhone: map['driver_phone'],
      firstWeight: map['first_weight']?.toDouble(),
      secondWeight: map['second_weight']?.toDouble(),
      netWeight: map['net_weight']?.toDouble() ?? 0.0,
      tareWeight: map['tare_weight']?.toDouble(),
      unit: map['unit'] ?? 'KG',
      poNumber: map['po_number'],
      doNumber: map['do_number'],
      remarks: map['remarks'],
      status: map['status'] ?? 'Completed',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  WeighingTicket copyWith({
    int? id,
    String? ticketNumber,
    DateTime? weighingDate,
    String? operatorCode,
    String? operatorName,
    String? materialCode,
    String? materialName,
    String? category,
    String? batchNumber,
    String? grade,                  // ✅ NEW
    String? supplierCode,
    String? supplierName,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    double? firstWeight,
    double? secondWeight,
    double? netWeight,
    double? tareWeight,
    String? unit,
    String? poNumber,
    String? doNumber,
    String? remarks,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeighingTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      weighingDate: weighingDate ?? this.weighingDate,
      operatorCode: operatorCode ?? this.operatorCode,
      operatorName: operatorName ?? this.operatorName,
      materialCode: materialCode ?? this.materialCode,
      materialName: materialName ?? this.materialName,
      category: category ?? this.category,
      batchNumber: batchNumber ?? this.batchNumber,
      grade: grade ?? this.grade,   // ✅ NEW
      supplierCode: supplierCode ?? this.supplierCode,
      supplierName: supplierName ?? this.supplierName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      firstWeight: firstWeight ?? this.firstWeight,
      secondWeight: secondWeight ?? this.secondWeight,
      netWeight: netWeight ?? this.netWeight,
      tareWeight: tareWeight ?? this.tareWeight,
      unit: unit ?? this.unit,
      poNumber: poNumber ?? this.poNumber,
      doNumber: doNumber ?? this.doNumber,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ Generate ticket number otomatis
  static String generateTicketNumber() {
    DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString().padLeft(2, '0');
    int sequence = now.millisecondsSinceEpoch % 10000;
    return 'WT-$year-$month-${sequence.toString().padLeft(4, '0')}';
  }

  // ✅ Generate batch number otomatis (auto-increment)
  static String generateBatchNumber() {
    DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString().padLeft(2, '0');
    String day = now.day.toString().padLeft(2, '0');
    int sequence = now.millisecondsSinceEpoch % 10000;
    return 'BATCH-$year$month$day-${sequence.toString().padLeft(4, '0')}';
  }

  // ✅ Helper getters
  bool get hasVehicleInfo => vehicleNumber != null && vehicleNumber!.isNotEmpty;
  bool get hasSupplierInfo => supplierCode != null && supplierCode!.isNotEmpty;
  bool get hasBatchNumber => batchNumber != null && batchNumber!.isNotEmpty;
  bool get hasGrade => grade != null && grade!.isNotEmpty;  // ✅ NEW
  bool get isCompleted => status.toLowerCase() == 'completed';
  
  // ✅ NEW: Get calculated weights (for QC report)
  double get grossWeight => firstWeight ?? netWeight;
  double get actualTareWeight => tareWeight ?? 0.0;
  
  // ✅ NEW: Format untuk QC report
  String getQCReport() {
    return '''
================================
       T-CONNECT
     Quality Control
================================
Material: $materialName
Grade   : ${grade ?? '-'}
Batch   : ${batchNumber ?? ticketNumber}
--------------------------------
GROSS WT : ${grossWeight.toStringAsFixed(2)} $unit
TARE WT  : ${actualTareWeight.toStringAsFixed(2)} $unit
NET WT   : ${netWeight.toStringAsFixed(2)} $unit
--------------------------------
Date: ${_formatDate(weighingDate)} ${_formatTime(weighingDate)}
Operator: $operatorName
================================
''';
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}