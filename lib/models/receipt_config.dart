/// Model untuk konfigurasi template resi
class ReceiptConfig {
  final String paperSize;              // '58mm', '80mm', atau custom
  final ReceiptTemplateFields receiptFields;
  final StatisticsTemplateFields statisticsFields;
  final DateTime savedAt;

  ReceiptConfig({
    required this.paperSize,
    required this.receiptFields,
    required this.statisticsFields,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paper_size': paperSize,
      'receipt_fields': receiptFields.toMap(),
      'statistics_fields': statisticsFields.toMap(),
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory ReceiptConfig.fromMap(Map<String, dynamic> map) {
    return ReceiptConfig(
      paperSize: map['paper_size'] ?? '80mm',
      receiptFields: ReceiptTemplateFields.fromMap(map['receipt_fields'] ?? {}),
      statisticsFields: StatisticsTemplateFields.fromMap(map['statistics_fields'] ?? {}),
      savedAt: map['saved_at'] != null 
          ? DateTime.parse(map['saved_at']) 
          : DateTime.now(),
    );
  }

  // Default configuration
  factory ReceiptConfig.defaultConfig() {
    return ReceiptConfig(
      paperSize: '80mm',
      receiptFields: ReceiptTemplateFields.defaultFields(),
      statisticsFields: StatisticsTemplateFields.defaultFields(),
      savedAt: DateTime.now(),
    );
  }

  // Get paper width in characters (untuk thermal printer)
  int get paperWidthChars {
    switch (paperSize) {
      case '58mm':
        return 32;  // 58mm = ~32 characters
      case '80mm':
        return 48;  // 80mm = ~48 characters
      default:
        // Parse custom size
        final width = int.tryParse(paperSize.replaceAll('mm', '')) ?? 80;
        return (width * 0.6).round(); // estimasi characters
    }
  }
}

/// Fields untuk template resi timbangan
class ReceiptTemplateFields {
  // Header
  final bool companyName;
  final bool companyAddress;
  final bool companyPhone;
  
  // Transaction Info
  final bool receiptNumber;
  final bool transactionDate;
  final bool operatorName;
  
  // Customer/Supplier
  final bool customerName;
  final bool supplierName;
  final bool vehicleNumber;
  final bool driverName;
  
  // Material
  final bool materialName;
  final bool category;
  final bool batchNumber;
  
  // Weight (wajib)
  final bool grossWeight;
  final bool tareWeight;
  final bool netWeight;
  final bool unit;
  
  // Additional
  final bool poNumber;
  final bool doNumber;
  final bool remarks;
  
  // Price (opsional - untuk TransactionReceipt)
  final bool pricePerKg;
  final bool subtotal;
  final bool taxAmount;
  final bool totalAmount;

  ReceiptTemplateFields({
    this.companyName = true,
    this.companyAddress = true,
    this.companyPhone = true,
    this.receiptNumber = true,
    this.transactionDate = true,
    this.operatorName = true,
    this.customerName = true,
    this.supplierName = true,
    this.vehicleNumber = true,
    this.driverName = true,
    this.materialName = true,
    this.category = true,
    this.batchNumber = true,
    this.grossWeight = true,
    this.tareWeight = true,
    this.netWeight = true,
    this.unit = true,
    this.poNumber = true,
    this.doNumber = true,
    this.remarks = true,
    this.pricePerKg = false,
    this.subtotal = false,
    this.taxAmount = false,
    this.totalAmount = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'company_name': companyName,
      'company_address': companyAddress,
      'company_phone': companyPhone,
      'receipt_number': receiptNumber,
      'transaction_date': transactionDate,
      'operator_name': operatorName,
      'customer_name': customerName,
      'supplier_name': supplierName,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'material_name': materialName,
      'category': category,
      'batch_number': batchNumber,
      'gross_weight': grossWeight,
      'tare_weight': tareWeight,
      'net_weight': netWeight,
      'unit': unit,
      'po_number': poNumber,
      'do_number': doNumber,
      'remarks': remarks,
      'price_per_kg': pricePerKg,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
    };
  }

  factory ReceiptTemplateFields.fromMap(Map<String, dynamic> map) {
    return ReceiptTemplateFields(
      companyName: map['company_name'] ?? true,
      companyAddress: map['company_address'] ?? true,
      companyPhone: map['company_phone'] ?? true,
      receiptNumber: map['receipt_number'] ?? true,
      transactionDate: map['transaction_date'] ?? true,
      operatorName: map['operator_name'] ?? true,
      customerName: map['customer_name'] ?? true,
      supplierName: map['supplier_name'] ?? true,
      vehicleNumber: map['vehicle_number'] ?? true,
      driverName: map['driver_name'] ?? true,
      materialName: map['material_name'] ?? true,
      category: map['category'] ?? true,
      batchNumber: map['batch_number'] ?? true,
      grossWeight: map['gross_weight'] ?? true,
      tareWeight: map['tare_weight'] ?? true,
      netWeight: map['net_weight'] ?? true,
      unit: map['unit'] ?? true,
      poNumber: map['po_number'] ?? true,
      doNumber: map['do_number'] ?? true,
      remarks: map['remarks'] ?? true,
      pricePerKg: map['price_per_kg'] ?? false,
      subtotal: map['subtotal'] ?? false,
      taxAmount: map['tax_amount'] ?? false,
      totalAmount: map['total_amount'] ?? false,
    );
  }

  factory ReceiptTemplateFields.defaultFields() {
    return ReceiptTemplateFields();
  }
}

/// Fields untuk template statistik timbangan
class StatisticsTemplateFields {
  // Statistik Umum
  final bool totalTransactions;
  final bool totalWeight;
  final bool averageWeight;
  
  // Breakdown
  final bool byMaterial;
  final bool bySupplier;
  final bool byVehicle;
  final bool byOperator;
  final bool byDate;
  
  // Financial (opsional)
  final bool totalRevenue;

  StatisticsTemplateFields({
    this.totalTransactions = true,
    this.totalWeight = true,
    this.averageWeight = true,
    this.byMaterial = true,
    this.bySupplier = true,
    this.byVehicle = true,
    this.byOperator = true,
    this.byDate = true,
    this.totalRevenue = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'total_transactions': totalTransactions,
      'total_weight': totalWeight,
      'average_weight': averageWeight,
      'by_material': byMaterial,
      'by_supplier': bySupplier,
      'by_vehicle': byVehicle,
      'by_operator': byOperator,
      'by_date': byDate,
      'total_revenue': totalRevenue,
    };
  }

  factory StatisticsTemplateFields.fromMap(Map<String, dynamic> map) {
    return StatisticsTemplateFields(
      totalTransactions: map['total_transactions'] ?? true,
      totalWeight: map['total_weight'] ?? true,
      averageWeight: map['average_weight'] ?? true,
      byMaterial: map['by_material'] ?? true,
      bySupplier: map['by_supplier'] ?? true,
      byVehicle: map['by_vehicle'] ?? true,
      byOperator: map['by_operator'] ?? true,
      byDate: map['by_date'] ?? true,
      totalRevenue: map['total_revenue'] ?? false,
    );
  }

  factory StatisticsTemplateFields.defaultFields() {
    return StatisticsTemplateFields();
  }
}