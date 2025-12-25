import 'dart:convert';
import 'package:flutter/material.dart';

class LabelTemplate {
  final String id;
  String name;
  double width;
  double height;
  String unit; 
  List<LabelElement> elements;
  bool isActive;
  DateTime createdAt;
  DateTime? updatedAt;
  
  String printerType;
  String paperSize;
  Map<String, dynamic>? settings;

  LabelTemplate({
    required this.id,
    required this.name,
    this.width = 58.0,
    this.height = 50.0,
    this.unit = 'mm',
    List<LabelElement>? elements,
    this.isActive = false,
    DateTime? createdAt,
    this.updatedAt,
    this.printerType = 'TSC',
    this.paperSize = '58x50',
    this.settings,
  })  : elements = elements ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'unit': unit,
      'elements': jsonEncode(elements.map((e) => e.toMap()).toList()),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'printer_type': printerType,
      'paper_size': paperSize,
    };
    
    if (settings != null && settings!.isNotEmpty) {
      final reservedKeys = {
        'id', 'name', 'width', 'height', 'unit', 'elements', 
        'is_active', 'created_at', 'updated_at', 
        'printer_type', 'paper_size', 'settings'
      };
      
      final sanitizedSettings = Map<String, dynamic>.from(settings!)
        ..removeWhere((key, value) => reservedKeys.contains(key));
      
      if (sanitizedSettings.isNotEmpty) {
        map['settings'] = jsonEncode(sanitizedSettings);
      } else {
        map['settings'] = null;
      }
    } else {
      map['settings'] = null;
    }
    
    return map;
  }

  factory LabelTemplate.fromMap(Map<String, dynamic> map) {
    List<dynamic> elementsJson = jsonDecode(map['elements'] ?? '[]');
    List<LabelElement> elementsList = elementsJson
        .map((e) => LabelElement.fromMap(e))
        .toList();

    Map<String, dynamic>? parsedSettings;
    if (map['settings'] != null && map['settings'].toString().trim().isNotEmpty) {
      try {
        parsedSettings = jsonDecode(map['settings']);
      } catch (e) {
        print('⚠️ Error parsing settings: $e');
        parsedSettings = null;
      }
    }

    return LabelTemplate(
      id: map['id'],
      name: map['name'],
      width: map['width']?.toDouble() ?? 58.0,
      height: map['height']?.toDouble() ?? 50.0,
      unit: map['unit'] ?? 'mm',
      elements: elementsList,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      printerType: map['printer_type'] ?? 'TSC',
      paperSize: map['paper_size'] ?? '58x50',
      settings: parsedSettings,
    );
  }

  LabelTemplate copyWith({
    String? id,
    String? name,
    double? width,
    double? height,
    String? unit,
    List<LabelElement>? elements,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? printerType,
    String? paperSize,
    Map<String, dynamic>? settings,
  }) {
    return LabelTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      unit: unit ?? this.unit,
      elements: elements ?? this.elements,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      printerType: printerType ?? this.printerType,
      paperSize: paperSize ?? this.paperSize,
      settings: settings ?? this.settings,
    );
  }
  
  bool get isTSCPrinter => printerType == 'TSC';
  bool get isESCPOSPrinter => printerType == 'ESCPOS';
  
  String get printerTypeDisplay => isTSCPrinter ? 'TSC Label' : 'Thermal Receipt';

  @override
  String toString() {
    return 'LabelTemplate(id: $id, name: $name, size: ${width}×${height} $unit, '
           'printer: $printerType, paper: $paperSize, elements: ${elements.length}, active: $isActive)';
  }
}

class LabelElement {
  final String id;
  final String variable;
  final String label;
  double x;
  double y;
  double width;
  double height;
  double fontSize;
  FontWeight fontWeight;
  TextAlign textAlign;
  bool isVisible;
  bool? showLabel;
  
  bool isManualInput;

  LabelElement({
    required this.id,
    required this.variable,
    required this.label,
    this.x = 0,
    this.y = 0,
    this.width = 150,
    this.height = 30,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.isVisible = true,
    this.showLabel,
    this.isManualInput = false,
  });

  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'variable': variable,
    'label': label,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'fontSize': fontSize,
    'fontWeight': fontWeight.index,
    'textAlign': textAlign.index,
    'isVisible': isVisible ? 1 : 0,
    'showLabel': showLabel == null ? null : (showLabel! ? 1 : 0),
    'isManualInput': isManualInput ? 1 : 0,
  };
}

  factory LabelElement.fromMap(Map<String, dynamic> map) {
  return LabelElement(
    id: map['id'] as String,
    variable: map['variable'] as String,
    label: map['label'] as String,
    x: (map['x'] as num).toDouble(),
    y: (map['y'] as num).toDouble(),
    width: (map['width'] as num).toDouble(),
    height: (map['height'] as num).toDouble(),
    fontSize: (map['fontSize'] as num).toDouble(),
    fontWeight: FontWeight.values[map['fontWeight'] as int],
    textAlign: TextAlign.values[map['textAlign'] as int],
    isVisible: (map['isVisible'] as int?) == 1,
    showLabel: map['showLabel'] == null ? null : ((map['showLabel'] as int) == 1),
    isManualInput: (map['isManualInput'] as int?) == 1,
  );
}

  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory LabelElement.fromJson(Map<String, dynamic> json) {
    return LabelElement.fromMap(json);
  }

  LabelElement copyWith({
  String? id,
  String? variable,
  String? label,
  double? x,
  double? y,
  double? width,
  double? height,
  double? fontSize,
  FontWeight? fontWeight,
  TextAlign? textAlign,
  bool? isVisible,
  bool? showLabel,
  bool? isManualInput,
}) {
  return LabelElement(
    id: id ?? this.id,
    variable: variable ?? this.variable,
    label: label ?? this.label,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    textAlign: textAlign ?? this.textAlign,
    isVisible: isVisible ?? this.isVisible,
    showLabel: showLabel ?? this.showLabel,
    isManualInput: isManualInput ?? this.isManualInput,
  );
}

  @override
String toString() {
  return 'LabelElement(id: $id, var: $variable, label: "$label", '
         'pos: (${x.toStringAsFixed(0)},${y.toStringAsFixed(0)}), '
         'size: ${width.toStringAsFixed(0)}×${height.toStringAsFixed(0)}, '
         'font: ${fontSize.toStringAsFixed(0)}pt, visible: $isVisible, '
         'showLabel: $showLabel, isManualInput: $isManualInput)';
}
}

class AvailableField {
  final String variable;
  final String label;
  final String category;
  final IconData icon;
  final FieldType type;
  final List<String> supportedPrinters;

  AvailableField({
    required this.variable,
    required this.label,
    required this.category,
    required this.icon,
    this.type = FieldType.dynamic,
    this.supportedPrinters = const ['TSC', 'ESCPOS'],
  });
  
  bool supportsPrinter(String printerType) {
    return supportedPrinters.contains(printerType);
  }
}

enum FieldType {
  dynamic,
  manual,
  calculated,
  static,
}

class LabelFields {
  static List<AvailableField> get timbanganFields => [
    AvailableField(
      variable: 'BERAT',
      label: 'Berat',
      category: 'Info Timbangan',
      icon: Icons.scale,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'UNIT',
      label: 'Unit',
      category: 'Info Timbangan',
      icon: Icons.straighten,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
  ];

  static List<AvailableField> get transaksiFields => [
    AvailableField(
      variable: 'NOMOR_BATCH',
      label: 'Nomor Batch/Resi',
      category: 'Info Transaksi',
      icon: Icons.qr_code_2,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'NAMA_BARANG',
      label: 'Nama Barang',
      category: 'Info Transaksi',
      icon: Icons.inventory_2,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'KATEGORI',
      label: 'Kategori',
      category: 'Info Transaksi',
      icon: Icons.category,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'OPERATOR',
      label: 'Operator',
      category: 'Info Transaksi',
      icon: Icons.person,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
  ];

  static List<AvailableField> get tanggalFields => [
    AvailableField(
      variable: 'TANGGAL',
      label: 'Tanggal',
      category: 'Tanggal & Waktu',
      icon: Icons.calendar_today,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'WAKTU',
      label: 'Waktu',
      category: 'Tanggal & Waktu',
      icon: Icons.access_time,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'TANGGAL_LENGKAP',
      label: 'Tanggal Lengkap',
      category: 'Tanggal & Waktu',
      icon: Icons.event,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
  ];

  static List<AvailableField> get hargaFields => [
    AvailableField(
      variable: 'HARGA_PER_KG',
      label: 'Harga per kg',
      category: 'Harga',
      icon: Icons.attach_money,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'TOTAL_HARGA',
      label: 'Total Harga',
      category: 'Harga',
      icon: Icons.price_check,
      type: FieldType.calculated,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
  ];

  static List<AvailableField> get perusahaanFields => [
    AvailableField(
      variable: 'NAMA_PERUSAHAAN',
      label: 'PT TRISURYA SOLUSINDO UTAMA',
      category: 'Info Perusahaan',
      icon: Icons.business,
      type: FieldType.static,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'ALAMAT',
      label: 'Alamat',
      category: 'Info Perusahaan',
      icon: Icons.location_on,
      type: FieldType.static,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'TELEPON',
      label: 'Telepon',
      category: 'Info Perusahaan',
      icon: Icons.phone,
      type: FieldType.static,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
  ];

  static List<AvailableField> get teksBebas => [
    AvailableField(
      variable: 'HEADER',
      label: 'Header',
      category: 'Teks Bebas',
      icon: Icons.title,
      type: FieldType.static,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'FOOTER',
      label: 'Footer',
      category: 'Teks Bebas',
      icon: Icons.notes,
      type: FieldType.static,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'GARIS_PEMISAH',
      label: '================================',
      category: 'Teks Bebas',
      icon: Icons.horizontal_rule,
      type: FieldType.static,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
  ];
  
  static List<AvailableField> get graphicsFields => [
    AvailableField(
      variable: 'BARCODE',
      label: 'Barcode',
      category: 'Graphics',
      icon: Icons.qr_code_2,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC'],
    ),
    AvailableField(
      variable: 'QRCODE',
      label: 'QR Code',
      category: 'Graphics',
      icon: Icons.qr_code,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC'],
    ),
  ];

  static List<AvailableField> get weighingDataFields => [
    AvailableField(
      variable: 'GROSS_WEIGHT',
      label: 'Gross Weight',
      category: 'Weighing Data',
      icon: Icons.fitness_center,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'TARE_WEIGHT',
      label: 'Tare Weight',
      category: 'Weighing Data',
      icon: Icons.shopping_basket,
      type: FieldType.dynamic,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'NET_WEIGHT',
      label: 'Net Weight',
      category: 'Weighing Data',
      icon: Icons.scale,
      type: FieldType.calculated,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    
    AvailableField(
      variable: 'QUANTITY',
      label: 'Quantity (Counting Mode)',
      category: 'Weighing Data',
      icon: Icons.calculate,
      type: FieldType.calculated,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'UNIT_WEIGHT',
      label: 'Unit Weight (UW)',
      category: 'Weighing Data',
      icon: Icons.scale_outlined,
      type: FieldType.calculated,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'SAMPLE_COUNT',
      label: 'Sample Count',
      category: 'Weighing Data',
      icon: Icons.numbers,
      type: FieldType.calculated,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
  ];

  static List<AvailableField> get customInputFields => [
    AvailableField(
      variable: 'CLIENT',
      label: 'Client',
      category: 'Custom Input',
      icon: Icons.person_outline,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'MATERIAL_CODE',
      label: 'Material Code / ID',
      category: 'Custom Input',
      icon: Icons.qr_code_2,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'SUPPLIER',
      label: 'Supplier',
      category: 'Custom Input',
      icon: Icons.local_shipping,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'SKU',
      label: 'SKU',
      category: 'Custom Input',
      icon: Icons.inventory,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
    AvailableField(
      variable: 'LOCATION',
      label: 'Location',
      category: 'Custom Input',
      icon: Icons.location_on,
      type: FieldType.manual,
      supportedPrinters: ['TSC', 'ESCPOS'],
    ),
  ];

  static Map<String, List<AvailableField>> get groupedFields => {
    'Info Perusahaan': perusahaanFields,
    'Info Transaksi': transaksiFields,
    'Custom Input': customInputFields,
    'Info Timbangan': timbanganFields,
    'Weighing Data': weighingDataFields,
    'Tanggal & Waktu': tanggalFields,
    'Harga': hargaFields,
    'Teks Bebas': teksBebas,
    'Graphics (TSC)': graphicsFields,
  };

  static List<AvailableField> get allFields => [
    ...timbanganFields,
    ...transaksiFields,
    ...customInputFields,
    ...tanggalFields,
    ...hargaFields,
    ...perusahaanFields,
    ...teksBebas,
    ...graphicsFields,
    ...weighingDataFields,
  ];
  
  static List<AvailableField> getFieldsByPrinterType(String printerType) {
    return allFields.where((field) => field.supportsPrinter(printerType)).toList();
  }
  
  static Map<String, List<AvailableField>> getGroupedFieldsByPrinterType(String printerType) {
    Map<String, List<AvailableField>> filtered = {};
    
    groupedFields.forEach((category, fields) {
      List<AvailableField> supportedFields = fields
          .where((field) => field.supportsPrinter(printerType))
          .toList();
      
      if (supportedFields.isNotEmpty) {
        filtered[category] = supportedFields;
      }
    });
    
    return filtered;
  }
} 

class SampleData {
  static Map<String, dynamic> get data => {
    'NAMA_PERUSAHAAN': 'PT TRISURYA SOLUSINDO UTAMA',
    'ALAMAT': 'Jl. Raya Citarik, Jatireja, Kec. Cikarang Tim., Kabupaten Bekasi, Jawa Barat 17530',
    'TELEPON': '(021) 56927540',
    
    'NOMOR_BATCH': 'AUTO-${DateTime.now().millisecondsSinceEpoch}',
    'NAMA_BARANG': '[Pilih Barang]',
    'KATEGORI': '[Auto dari Barang]',
    'OPERATOR': '[Dari Database]',
    
    'BERAT': '0.00',
    'UNIT': 'KG',
    'BERAT_KG': '0.000',
    'GROSS_WEIGHT': '0.00',
    'TARE_WEIGHT': '0.00',
    'NET_WEIGHT': '0.00',
    
    'QUANTITY': '125 pcs',
    'UNIT_WEIGHT': '0.850 kg',
    'SAMPLE_COUNT': '10 pcs',
    
    'TANGGAL': _formatDate(DateTime.now()),
    'WAKTU': _formatTime(DateTime.now()),
    'TANGGAL_LENGKAP': _formatDateLengkap(DateTime.now()),
    
    'HARGA_PER_KG': 'Rp 0',
    'TOTAL_HARGA': 'Rp 0',
    
    'HEADER': 'T-CONNECT',
    'FOOTER': 'info@trisuryasolusindo.com',
    'GARIS_PEMISAH': '================================',
    
    'BARCODE': '',
    'QRCODE': '',

    'CLIENT': '[Nama Client]',
    'MATERIAL_CODE': 'MAT-12345',
    'SUPPLIER': 'PT Supplier ABC',
    'SKU': 'SKU-2025-001',
    'LOCATION': 'Warehouse A - Rack B3',
  };
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
  
  static String _formatDateLengkap(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month]} ${date.year}';
  }
}

class LabelTemplateService {
  static String getValueForVariable(
    String variable, 
    Map<String, dynamic> data,
  ) {
    return data[variable]?.toString() ?? variable;
  }

  static Future<bool> saveTemplate(LabelTemplate template) async {
    print('Saving template: ${template.name}');
    return true;
  }

  static Future<List<LabelTemplate>> getAllTemplates() async {
    print('Loading templates...');
    return [];
  }

  static Future<bool> setActiveTemplate(String templateId) async {
    print('Setting active template: $templateId');
    return true;
  }
}