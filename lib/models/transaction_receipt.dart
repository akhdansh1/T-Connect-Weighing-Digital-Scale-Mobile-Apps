/// Model untuk Transaction Receipt (Resi Transaksi)
/// Digunakan untuk transaksi jual-beli dengan harga
class TransactionReceipt {
  final int? id;
  final String receiptNumber;       // TR-2025-10-001
  final DateTime transactionDate;
  final String operatorCode;
  final String operatorName;
  
  // Customer Info
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  
  // Material Info
  final String materialCode;
  final String materialName;
  final String category;
  final String grade;
  
  // Weight Data
  final double grossWeight;
  final double tareWeight;
  final double netWeight;
  final String unit;
  
  // Price & Payment
  final int pricePerKg;
  final int subtotal;
  final double taxRate;              // % (e.g., 11 untuk 11%)
  final int taxAmount;
  final int totalAmount;
  final String paymentMethod;        // CASH, TRANSFER, CREDIT
  final int? paidAmount;
  final int? changeAmount;
  
  // Additional Info
  final String? poNumber;            // Purchase Order
  final String? invoiceNumber;
  final String? remarks;
  final String status;               // Paid, Pending, Cancelled
  
  // ✅ FIELD BARU UNTUK DETAIL LENGKAP
  final String? batchNumber;         // Nomor Batch
  final String? supplierCode;        // Kode Supplier
  final String? supplierName;        // Nama Supplier
  final String? vehicleNumber;       // Nomor Kendaraan
  final String? driverName;          // Nama Sopir
  final String? driverPhone;         // Telepon Sopir
  final String? doNumber;            // Delivery Order Number
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  TransactionReceipt({
    this.id,
    required this.receiptNumber,
    required this.transactionDate,
    required this.operatorCode,
    required this.operatorName,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.materialCode,
    required this.materialName,
    required this.category,
    this.grade = 'Standard',
    required this.grossWeight,
    this.tareWeight = 0.0,
    required this.netWeight,
    this.unit = 'KG',
    required this.pricePerKg,
    required this.subtotal,
    this.taxRate = 0.0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.paymentMethod = 'CASH',
    this.paidAmount,
    this.changeAmount,
    this.poNumber,
    this.invoiceNumber,
    this.remarks,
    this.status = 'Paid',
    
    // ✅ PARAMETER BARU
    this.batchNumber,
    this.supplierCode,
    this.supplierName,
    this.vehicleNumber,
    this.driverName,
    this.driverPhone,
    this.doNumber,
    
    required this.createdAt,
    this.updatedAt,
  });

  // ✅ UPDATE: copyWith method dengan field baru
  TransactionReceipt copyWith({
    int? id,
    String? receiptNumber,
    DateTime? transactionDate,
    String? operatorCode,
    String? operatorName,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? materialCode,
    String? materialName,
    String? category,
    String? grade,
    double? grossWeight,
    double? tareWeight,
    double? netWeight,
    String? unit,
    int? pricePerKg,
    int? subtotal,
    double? taxRate,
    int? taxAmount,
    int? totalAmount,
    String? paymentMethod,
    int? paidAmount,
    int? changeAmount,
    String? poNumber,
    String? invoiceNumber,
    String? remarks,
    String? status,
    
    // ✅ PARAMETER BARU
    String? batchNumber,
    String? supplierCode,
    String? supplierName,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    String? doNumber,
    
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionReceipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      operatorCode: operatorCode ?? this.operatorCode,
      operatorName: operatorName ?? this.operatorName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      materialCode: materialCode ?? this.materialCode,
      materialName: materialName ?? this.materialName,
      category: category ?? this.category,
      grade: grade ?? this.grade,
      grossWeight: grossWeight ?? this.grossWeight,
      tareWeight: tareWeight ?? this.tareWeight,
      netWeight: netWeight ?? this.netWeight,
      unit: unit ?? this.unit,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      poNumber: poNumber ?? this.poNumber,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      
      // ✅ FIELD BARU
      batchNumber: batchNumber ?? this.batchNumber,
      supplierCode: supplierCode ?? this.supplierCode,
      supplierName: supplierName ?? this.supplierName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      doNumber: doNumber ?? this.doNumber,
      
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ UPDATE: toMap dengan field baru
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'transaction_date': transactionDate.toIso8601String(),
      'operator_code': operatorCode,
      'operator_name': operatorName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'material_code': materialCode,
      'material_name': materialName,
      'category': category,
      'grade': grade,
      'gross_weight': grossWeight,
      'tare_weight': tareWeight,
      'net_weight': netWeight,
      'unit': unit,
      'price_per_kg': pricePerKg,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'po_number': poNumber,
      'invoice_number': invoiceNumber,
      'remarks': remarks,
      'status': status,
      
      // ✅ FIELD BARU
      'batch_number': batchNumber,
      'supplier_code': supplierCode,
      'supplier_name': supplierName,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'do_number': doNumber,
      
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ✅ UPDATE: fromMap dengan field baru
  factory TransactionReceipt.fromMap(Map<String, dynamic> map) {
    return TransactionReceipt(
      id: map['id'],
      receiptNumber: map['receipt_number'] ?? '',
      transactionDate: DateTime.parse(map['transaction_date']),
      operatorCode: map['operator_code'] ?? '',
      operatorName: map['operator_name'] ?? '',
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      customerAddress: map['customer_address'],
      materialCode: map['material_code'] ?? '',
      materialName: map['material_name'] ?? '',
      category: map['category'] ?? '',
      grade: map['grade'] ?? 'Standard',
      grossWeight: map['gross_weight']?.toDouble() ?? 0.0,
      tareWeight: map['tare_weight']?.toDouble() ?? 0.0,
      netWeight: map['net_weight']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'KG',
      pricePerKg: map['price_per_kg'] ?? 0,
      subtotal: map['subtotal'] ?? 0,
      taxRate: map['tax_rate']?.toDouble() ?? 0.0,
      taxAmount: map['tax_amount'] ?? 0,
      totalAmount: map['total_amount'] ?? 0,
      paymentMethod: map['payment_method'] ?? 'CASH',
      paidAmount: map['paid_amount'],
      changeAmount: map['change_amount'],
      poNumber: map['po_number'],
      invoiceNumber: map['invoice_number'],
      remarks: map['remarks'],
      status: map['status'] ?? 'Paid',
      
      // ✅ FIELD BARU
      batchNumber: map['batch_number'],
      supplierCode: map['supplier_code'],
      supplierName: map['supplier_name'],
      vehicleNumber: map['vehicle_number'],
      driverName: map['driver_name'],
      driverPhone: map['driver_phone'],
      doNumber: map['do_number'],
      
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Generate receipt number
  static String generateReceiptNumber() {
    DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString().padLeft(2, '0');
    int sequence = now.millisecondsSinceEpoch % 10000;
    return 'TR-$year-$month-${sequence.toString().padLeft(4, '0')}';
  }

  // Calculate subtotal from weight and price
  static int calculateSubtotal(double netWeightKg, int pricePerKg) {
    return (netWeightKg * pricePerKg).round();
  }

  // Calculate tax amount
  static int calculateTax(int subtotal, double taxRate) {
    return (subtotal * (taxRate / 100)).round();
  }

  // Calculate total
  static int calculateTotal(int subtotal, int taxAmount) {
    return subtotal + taxAmount;
  }

  // Getters
  bool get hasCustomer => customerName != null && customerName!.isNotEmpty;
  bool get hasTax => taxRate > 0;
  bool get isPaid => status.toLowerCase() == 'paid';
  bool get hasChange => changeAmount != null && changeAmount! > 0;
  
  // ✅ GETTER BARU untuk field tambahan
  bool get hasSupplier => supplierName != null && supplierName!.isNotEmpty;
  bool get hasVehicle => vehicleNumber != null && vehicleNumber!.isNotEmpty;
  bool get hasDriver => driverName != null && driverName!.isNotEmpty;
  bool get hasBatch => batchNumber != null && batchNumber!.isNotEmpty;
}