// lib/models/receipt_template.dart

import 'dart:convert';
import 'receipt_field.dart';

enum PaperSize {
  mm58, // 58mm thermal paper
  mm80, // 80mm thermal paper
}

enum PrintAlignment {
  left,
  center,
  right,
}

class ReceiptTemplate {
  String id;
  String templateName;
  List<ReceiptField> fields;
  bool isActive; // hanya 1 template yang bisa active
  DateTime createdAt;
  DateTime? updatedAt;
  
  // Paper & Print Settings
  PaperSize paperSize;
  PrintAlignment headerAlignment;
  bool enableLogo; // tampilkan logo perusahaan atau tidak
  String? logoPath; // path ke logo image
  int paperWidth; // dalam karakter (untuk 58mm = 32 char, 80mm = 48 char)
  
  ReceiptTemplate({
    required this.id,
    required this.templateName,
    required this.fields,
    this.isActive = false,
    required this.createdAt,
    this.updatedAt,
    this.paperSize = PaperSize.mm80,
    this.headerAlignment = PrintAlignment.center,
    this.enableLogo = false,
    this.logoPath,
    int? paperWidth,
  }) : paperWidth = paperWidth ?? (paperSize == PaperSize.mm58 ? 32 : 48);

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'template_name': templateName,        // ✅ snake_case
    'fields': jsonEncode(fields.map((f) => f.toMap()).toList()),
    'is_active': isActive ? 1 : 0,       // ✅ snake_case
    'created_at': createdAt.toIso8601String(),  // ✅ snake_case
    'updated_at': updatedAt?.toIso8601String(), // ✅ snake_case
    'paper_size': paperSize.name,        // ✅ snake_case
    'header_alignment': headerAlignment.name,    // ✅ snake_case
    'enable_logo': enableLogo ? 1 : 0,   // ✅ snake_case
    'logo_path': logoPath,               // ✅ snake_case
    'paper_width': paperWidth,           // ✅ snake_case
  };
}

  // Create from Map (from database)
  factory ReceiptTemplate.fromMap(Map<String, dynamic> map) {
  List<dynamic> fieldsJson = jsonDecode(map['fields']);
  List<ReceiptField> fieldsList = fieldsJson
      .map((fieldMap) => ReceiptField.fromMap(fieldMap))
      .toList();

  return ReceiptTemplate(
    id: map['id'] ?? '',
    // Support both snake_case and camelCase
    templateName: map['template_name'] ?? map['templateName'] ?? 'Unknown Template',
    fields: fieldsList,
    isActive: (map['is_active'] ?? map['isActive'] ?? 0) == 1,
    createdAt: DateTime.parse(
      map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()
    ),
    updatedAt: (map['updated_at'] ?? map['updatedAt']) != null 
        ? DateTime.parse(map['updated_at'] ?? map['updatedAt']) 
        : null,
    paperSize: PaperSize.values.firstWhere(
      (e) => e.name == (map['paper_size'] ?? map['paperSize'] ?? 'mm80'),
      orElse: () => PaperSize.mm80,
    ),
    headerAlignment: PrintAlignment.values.firstWhere(
      (e) => e.name == (map['header_alignment'] ?? map['headerAlignment'] ?? 'center'),
      orElse: () => PrintAlignment.center,
    ),
    enableLogo: (map['enable_logo'] ?? map['enableLogo'] ?? 0) == 1,
    logoPath: map['logo_path'] ?? map['logoPath'],
    paperWidth: map['paper_width'] ?? map['paperWidth'] ?? 48,
  );
}

  // Copy with method untuk update template
  ReceiptTemplate copyWith({
    String? id,
    String? templateName,
    List<ReceiptField>? fields,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    PaperSize? paperSize,
    PrintAlignment? headerAlignment,
    bool? enableLogo,
    String? logoPath,
    int? paperWidth,
  }) {
    return ReceiptTemplate(
      id: id ?? this.id,
      templateName: templateName ?? this.templateName,
      fields: fields ?? this.fields,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paperSize: paperSize ?? this.paperSize,
      headerAlignment: headerAlignment ?? this.headerAlignment,
      enableLogo: enableLogo ?? this.enableLogo,
      logoPath: logoPath ?? this.logoPath,
      paperWidth: paperWidth ?? this.paperWidth,
    );
  }

  // Helper methods
  List<ReceiptField> getEnabledFields() {
    return fields.where((field) => field.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<ReceiptField> getEditableFields() {
    return getEnabledFields().where((field) => field.isEditable).toList();
  }

  ReceiptField? getFieldByKey(String key) {
    try {
      return fields.firstWhere((field) => field.fieldKey == key);
    } catch (e) {
      return null;
    }
  }

  // Update field di dalam template
  void updateField(String fieldKey, ReceiptField updatedField) {
    int index = fields.indexWhere((f) => f.fieldKey == fieldKey);
    if (index != -1) {
      fields[index] = updatedField;
      updatedAt = DateTime.now();
    }
  }

  // Add new field
  void addField(ReceiptField field) {
    fields.add(field);
    updatedAt = DateTime.now();
  }

  // Remove field
  void removeField(String fieldKey) {
    fields.removeWhere((f) => f.fieldKey == fieldKey);
    updatedAt = DateTime.now();
  }

  // Reorder fields
  void reorderFields(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final field = fields.removeAt(oldIndex);
    fields.insert(newIndex, field);
    
    // Update order untuk semua fields
    for (int i = 0; i < fields.length; i++) {
      fields[i] = fields[i].copyWith(order: i);
    }
    updatedAt = DateTime.now();
  }

  @override
  String toString() {
    return 'ReceiptTemplate(id: $id, name: $templateName, active: $isActive, fields: ${fields.length})';
  }

  // Factory untuk create default template
  factory ReceiptTemplate.createDefault() {
    return ReceiptTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      templateName: 'Default Template',
      fields: ReceiptFieldKeys.getDefaultFields(),
      isActive: true,
      createdAt: DateTime.now(),
      paperSize: PaperSize.mm80,
      headerAlignment: PrintAlignment.center,
      enableLogo: false,
    );
  }

  // Duplicate template dengan nama baru
  ReceiptTemplate duplicate(String newName) {
    return ReceiptTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      templateName: newName,
      fields: fields.map((f) => f.copyWith()).toList(),
      isActive: false, // duplicate tidak langsung active
      createdAt: DateTime.now(),
      paperSize: paperSize,
      headerAlignment: headerAlignment,
      enableLogo: enableLogo,
      logoPath: logoPath,
      paperWidth: paperWidth,
    );
  }
}