// lib/models/receipt_field.dart

enum FieldType {
  text,
  number,
  datetime,
  barcode,
  qrcode,
  image,
  divider, // untuk garis pemisah
}

enum FieldAlignment {
  left,
  center,
  right,
}

class ReceiptField {
  String fieldKey; // unique identifier: 'weight', 'operator', 'timestamp', etc.
  String displayLabel; // label yang tampil di resi: "Berat:", "Operator:", etc.
  bool isEnabled; // field ini ditampilkan atau tidak
  int order; // urutan field (0, 1, 2, ...)
  FieldType type; // tipe data field
  String? format; // format khusus (untuk datetime: "dd/MM/yyyy HH:mm", untuk number: "#,##0.00")
  bool isEditable; // bisa diedit sebelum print atau tidak
  FieldAlignment alignment; // alignment text
  bool isBold; // text bold atau tidak
  int fontSize; // ukuran font (relatif: 0=small, 1=normal, 2=large)
  
  ReceiptField({
    required this.fieldKey,
    required this.displayLabel,
    this.isEnabled = true,
    required this.order,
    required this.type,
    this.format,
    this.isEditable = true,
    this.alignment = FieldAlignment.left,
    this.isBold = false,
    this.fontSize = 1, // normal
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'fieldKey': fieldKey,
      'displayLabel': displayLabel,
      'isEnabled': isEnabled ? 1 : 0,
      'order': order,
      'type': type.name,
      'format': format,
      'isEditable': isEditable ? 1 : 0,
      'alignment': alignment.name,
      'isBold': isBold ? 1 : 0,
      'fontSize': fontSize,
    };
  }

  // Create from Map (from database)
  factory ReceiptField.fromMap(Map<String, dynamic> map) {
    return ReceiptField(
      fieldKey: map['fieldKey'] ?? '',
      displayLabel: map['displayLabel'] ?? '',
      isEnabled: map['isEnabled'] == 1,
      order: map['order'] ?? 0,
      type: FieldType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FieldType.text,
      ),
      format: map['format'],
      isEditable: map['isEditable'] == 1,
      alignment: FieldAlignment.values.firstWhere(
        (e) => e.name == map['alignment'],
        orElse: () => FieldAlignment.left,
      ),
      isBold: map['isBold'] == 1,
      fontSize: map['fontSize'] ?? 1,
    );
  }

  // Copy with method untuk update field
  ReceiptField copyWith({
    String? fieldKey,
    String? displayLabel,
    bool? isEnabled,
    int? order,
    FieldType? type,
    String? format,
    bool? isEditable,
    FieldAlignment? alignment,
    bool? isBold,
    int? fontSize,
  }) {
    return ReceiptField(
      fieldKey: fieldKey ?? this.fieldKey,
      displayLabel: displayLabel ?? this.displayLabel,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
      type: type ?? this.type,
      format: format ?? this.format,
      isEditable: isEditable ?? this.isEditable,
      alignment: alignment ?? this.alignment,
      isBold: isBold ?? this.isBold,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  String toString() {
    return 'ReceiptField(key: $fieldKey, label: $displayLabel, enabled: $isEnabled, order: $order)';
  }
}

// Predefined field keys untuk standar industri timbangan
class ReceiptFieldKeys {
  static const String companyName = 'company_name';
  static const String companyAddress = 'company_address';
  static const String companyPhone = 'company_phone';
  static const String receiptNumber = 'receipt_number';
  static const String timestamp = 'timestamp';
  static const String operator = 'operator';
  static const String vehicleNumber = 'vehicle_number';
  static const String driverName = 'driver_name';
  static const String materialType = 'material_type';
  static const String supplier = 'supplier';
  static const String grossWeight = 'gross_weight';
  static const String tareWeight = 'tare_weight';
  static const String netWeight = 'net_weight';
  static const String barcode = 'barcode';
  static const String qrcode = 'qrcode';
  static const String notes = 'notes';
  static const String divider = 'divider';
  
  // Helper untuk create default fields
  static List<ReceiptField> getDefaultFields() {
    return [
      ReceiptField(
        fieldKey: companyName,
        displayLabel: 'NAMA PERUSAHAAN',
        order: 0,
        type: FieldType.text,
        isEditable: false,
        alignment: FieldAlignment.center,
        isBold: true,
        fontSize: 2,
      ),
      ReceiptField(
        fieldKey: companyAddress,
        displayLabel: 'Alamat',
        order: 1,
        type: FieldType.text,
        isEditable: false,
        alignment: FieldAlignment.center,
        fontSize: 0,
      ),
      ReceiptField(
        fieldKey: companyPhone,
        displayLabel: 'Telp',
        order: 2,
        type: FieldType.text,
        isEditable: false,
        alignment: FieldAlignment.center,
        fontSize: 0,
      ),
      ReceiptField(
        fieldKey: divider,
        displayLabel: '================================',
        order: 3,
        type: FieldType.divider,
        isEditable: false,
        alignment: FieldAlignment.center,
      ),
      ReceiptField(
        fieldKey: receiptNumber,
        displayLabel: 'No. Transaksi',
        order: 4,
        type: FieldType.text,
        isEditable: true,
      ),
      ReceiptField(
        fieldKey: timestamp,
        displayLabel: 'Tanggal/Waktu',
        order: 5,
        type: FieldType.datetime,
        format: 'dd/MM/yyyy HH:mm',
        isEditable: true,
      ),
      ReceiptField(
        fieldKey: operator,
        displayLabel: 'Operator',
        order: 6,
        type: FieldType.text,
        isEditable: true,
      ),
      ReceiptField(
        fieldKey: vehicleNumber,
        displayLabel: 'No. Kendaraan',
        order: 7,
        type: FieldType.text,
        isEditable: true,
      ),
      ReceiptField(
        fieldKey: driverName,
        displayLabel: 'Nama Supir',
        order: 8,
        type: FieldType.text,
        isEditable: true,
      ),
      ReceiptField(
        fieldKey: materialType,
        displayLabel: 'Jenis Material',
        order: 9,
        type: FieldType.text,
        isEditable: true,
      ),
      ReceiptField(
        fieldKey: supplier,
        displayLabel: 'Supplier',
        order: 10,
        type: FieldType.text,
        isEditable: true,
      ),
      ReceiptField(
        fieldKey: divider,
        displayLabel: '--------------------------------',
        order: 11,
        type: FieldType.divider,
        isEditable: false,
        alignment: FieldAlignment.center,
      ),
      ReceiptField(
        fieldKey: grossWeight,
        displayLabel: 'Berat Kotor',
        order: 12,
        type: FieldType.number,
        format: '#,##0.00 kg',
        isEditable: true,
        isBold: true,
      ),
      ReceiptField(
        fieldKey: tareWeight,
        displayLabel: 'Berat Tara',
        order: 13,
        type: FieldType.number,
        format: '#,##0.00 kg',
        isEditable: true,
      ),
      ReceiptField(
        fieldKey: netWeight,
        displayLabel: 'Berat Netto',
        order: 14,
        type: FieldType.number,
        format: '#,##0.00 kg',
        isEditable: true,
        isBold: true,
        fontSize: 2,
      ),
      ReceiptField(
        fieldKey: divider,
        displayLabel: '================================',
        order: 15,
        type: FieldType.divider,
        isEditable: false,
        alignment: FieldAlignment.center,
      ),
      ReceiptField(
        fieldKey: barcode,
        displayLabel: 'Barcode',
        order: 16,
        type: FieldType.barcode,
        isEditable: true,
        alignment: FieldAlignment.center,
      ),
      ReceiptField(
        fieldKey: notes,
        displayLabel: 'Catatan',
        order: 17,
        type: FieldType.text,
        isEditable: true,
        fontSize: 0,
      ),
    ];
  }
}