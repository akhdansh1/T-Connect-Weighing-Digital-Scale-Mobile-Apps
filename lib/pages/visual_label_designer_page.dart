import 'package:flutter/material.dart';
import '../models/label_template_model.dart';
import '../models/paper_presets.dart';
import '../services/database_helper.dart';
import '../widgets/template_settings_dialog.dart';
import 'dart:convert';
import '../utils/printer_config.dart';
import '../services/printer_persistence_service.dart';

// ✅ TAMBAHKAN ENUM DESIGN MODE
enum DesignMode { DRAG_DROP, FORM_INPUT, COMPACT_LAYOUT }

class VisualLabelDesignerPage extends StatefulWidget {
  const VisualLabelDesignerPage({Key? key}) : super(key: key);

  @override
  State<VisualLabelDesignerPage> createState() => _VisualLabelDesignerPageState();
}

class _VisualLabelDesignerPageState extends State<VisualLabelDesignerPage> {
  final dbHelper = DatabaseHelper.instance;
  
  List<LabelTemplate> _templates = [];
  LabelTemplate? _currentTemplate;
  LabelElement? _selectedElement;
  bool _isPreviewMode = false;
  bool _isLoading = true;
  bool _showFieldPanel = true;

  // ✅ TAMBAHKAN VARIABLE DESIGN MODE
  DesignMode _currentDesignMode = DesignMode.DRAG_DROP;

  // ✅ TAMBAHKAN FORM CONTROLLERS UNTUK MODE INPUT
  final Map<String, TextEditingController> _formControllers = {};
  final Map<String, String> _compactLayoutFields = {
    'company_name': 'PT TRISURYA SOLUSINDO UTAMA',
    'title': 'Quality Control',
    'material_name': 'Beras Premium',
    'material_grade': 'A',
    'batch_number': 'BATCH-2025-001',
    'gross_weight': '125.50 KG',
    'tare_weight': '100.00 KG',
    'net_weight': '25.50 KG',
    'date_time': '19/11/2025 16:27',
    'operator_name': 'Dimas',
  };

  // ✅ CONTROLLERS YANG SUDAH ADA
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _fontSizeController = TextEditingController();
  
  static const double pxPerMm = 3.78;

  // ✅ VARIABEL PRINTER YANG SUDAH ADA
  String? _connectedPrinterName;
  String? _connectedPrinterModel;
  String? _connectedPrinterAddress;
  bool _isAutoDetectEnabled = true;

  @override
void initState() {
  super.initState();
  _loadTemplates();
  _loadPrinterSettings();
  _initializeFormControllers(); // ✅ INISIALISASI FORM CONTROLLERS
}

// ✅ TAMBAHKAN METHOD INI
void _initializeFormControllers() {
  _formControllers.clear();
  _compactLayoutFields.forEach((key, value) {
    _formControllers[key] = TextEditingController(text: value);
  });
}

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _fontSizeController.dispose();
    
    // ✅ DISPOSE FORM CONTROLLERS
    _formControllers.forEach((key, controller) {
      controller.dispose();
    });
    
    super.dispose();
  }

  // ✅ TAMBAHKAN METHOD COMPACT LAYOUT DI SINI
void _applyCompactLayout() {
  if (_currentTemplate == null) return;

  // ✅ FIX #1: CLEAR ELEMENTS DULU SEBELUM GENERATE BARU!
  print('🧹 Clearing existing elements before applying compact layout...');
  
  setState(() {
    _currentTemplate = _currentTemplate!.copyWith(
      elements: [], // ← RESET DULU!
    );
  });

  final elements = <LabelElement>[];
  
  final double paperWidth = _currentTemplate!.width * pxPerMm;
  final double paperHeight = _currentTemplate!.height * pxPerMm;
  final bool isLargeCanvas = _currentTemplate!.width >= 80.0;
  
  print('🎨 Applying compact layout:');
  print('   Canvas: ${_currentTemplate!.width}×${_currentTemplate!.height}mm');
  print('   Canvas (px): ${paperWidth.toInt()}×${paperHeight.toInt()}px');
  
  final double startY = isLargeCanvas ? 15 : 20;
  double currentY = startY;
  
  final double lineHeight = isLargeCanvas ? 22 : 28;
  final double sectionGap = isLargeCanvas ? 10 : 18;
  final double lineGap = isLargeCanvas ? 4 : 6;
  
  final double headerFontSize = isLargeCanvas ? 12 : 14;
  final double titleFontSize = isLargeCanvas ? 11 : 13;
  final double bodyFontSize = isLargeCanvas ? 9 : 11;
  final double footerFontSize = isLargeCanvas ? 7 : 9;
  
  final double leftMargin = isLargeCanvas ? 10 : 15;
  final double rightMargin = isLargeCanvas ? 10 : 15;
  
  // ✅ FIX #2: Gunakan timestamp yang unique untuk SETIAP element
  final baseTimestamp = DateTime.now().millisecondsSinceEpoch;
  int elementCounter = 0; // ← Counter untuk ensure uniqueness
  
  // ===== HEADER =====
  
  // Company Name
  elements.add(LabelElement(
    id: 'element_company_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'NAMA_PERUSAHAAN',
    label: 'PT TRISURYA SOLUSINDO UTAMA',
    showLabel: false,
    x: leftMargin,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin,
    height: lineHeight + 5,
    fontSize: headerFontSize,
    fontWeight: FontWeight.bold,
    textAlign: TextAlign.center,
  ));
  currentY += lineHeight + 7;
  
  // Address
  elements.add(LabelElement(
    id: 'element_address_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'ALAMAT',
    label: 'Alamat',
    showLabel: false,
    x: leftMargin,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin,
    height: lineHeight * 2.5,
    fontSize: 7,
    textAlign: TextAlign.center,
  ));
  currentY += (lineHeight * 2.5) + lineGap;
  
  // Phone
  elements.add(LabelElement(
    id: 'element_phone_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'TELEPON',
    label: 'Tel',
    showLabel: false,
    x: leftMargin,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin,
    height: lineHeight,
    fontSize: 8,
    textAlign: TextAlign.center,
  ));
  currentY += lineHeight + lineGap;
  
  // Separator
  elements.add(LabelElement(
    id: 'element_sep1_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'GARIS_PEMISAH',
    label: '================================',
    showLabel: false,
    x: leftMargin,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin,
    height: 3,
    fontSize: 8,
    textAlign: TextAlign.center,
  ));
  currentY += 8;
  
  // ===== BODY =====
  
  // Batch Number
  elements.add(LabelElement(
    id: 'element_batch_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'NOMOR_BATCH',
    label: 'Batch',
    showLabel: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: bodyFontSize,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + lineGap;
  
  // Date Time
  elements.add(LabelElement(
    id: 'element_datetime_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'TANGGAL_LENGKAP',
    label: 'Tanggal',
    showLabel: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: bodyFontSize,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + lineGap;
  
  // Time
  elements.add(LabelElement(
    id: 'element_time_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'WAKTU',
    label: 'Waktu',
    showLabel: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: bodyFontSize,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + sectionGap;
  
  // Material Name
  elements.add(LabelElement(
    id: 'element_material_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'NAMA_BARANG',
    label: 'Nama Barang',
    showLabel: true,
    isManualInput: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: bodyFontSize,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + lineGap;
  
  // Category
  elements.add(LabelElement(
    id: 'element_kategori_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'KATEGORI',
    label: 'Kategori',
    showLabel: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: bodyFontSize,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + sectionGap;
  
  // Separator 2
  elements.add(LabelElement(
    id: 'element_sep2_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'GARIS_PEMISAH',
    label: '--------------------------------',
    showLabel: false,
    x: leftMargin,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin,
    height: 3,
    fontSize: 8,
    textAlign: TextAlign.center,
  ));
  currentY += 8;
  
  // ===== WEIGHT DATA =====
  
  // Gross Weight
  elements.add(LabelElement(
    id: 'element_gross_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'GROSS_WEIGHT',
    label: 'GROSS WT',
    showLabel: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: bodyFontSize,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + lineGap;
  
  // Tare Weight
  elements.add(LabelElement(
    id: 'element_tare_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'TARE_WEIGHT',
    label: 'TARE WT',
    showLabel: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: bodyFontSize,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + lineGap;
  
  // Net Weight
  elements.add(LabelElement(
    id: 'element_net_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'NET_WEIGHT',
    label: 'NET WT',
    showLabel: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: bodyFontSize + 2,
    fontWeight: FontWeight.bold,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + sectionGap;
  
  // Separator 3
  elements.add(LabelElement(
    id: 'element_sep3_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'GARIS_PEMISAH',
    label: '--------------------------------',
    showLabel: false,
    x: leftMargin,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin,
    height: 3,
    fontSize: 8,
    textAlign: TextAlign.center,
  ));
  currentY += 8;
  
  // ===== FOOTER =====
  
  // Operator
  elements.add(LabelElement(
    id: 'element_operator_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
    variable: 'OPERATOR',
    label: 'Operator',
    showLabel: true,
    x: leftMargin + 5,
    y: currentY,
    width: paperWidth - leftMargin - rightMargin - 10,
    height: lineHeight,
    fontSize: footerFontSize,
    textAlign: TextAlign.left,
  ));
  currentY += lineHeight + lineGap;
  
  // QR Code (if space available)
  if ((paperHeight - currentY) > 50) {
    elements.add(LabelElement(
      id: 'element_qr_${baseTimestamp}_${elementCounter++}', // ✅ FIXED ID
      variable: 'QRCODE',
      label: '[QR CODE]',
      showLabel: false,
      x: (paperWidth - 100) / 2,
      y: currentY,
      width: 100,
      height: 30,
      fontSize: 8,
      textAlign: TextAlign.center,
    ));
  }
  
  // ✅ FIX #3: Update state dengan elements baru (sudah tidak ada duplikat!)
  setState(() {
    _currentTemplate = _currentTemplate!.copyWith(elements: elements);
    _selectedElement = null;
    _currentDesignMode = DesignMode.DRAG_DROP;
  });
  
  // ✅ FIX #4: Save ke database
  _saveCurrentTemplate().then((_) {
    print('✅ Compact layout applied successfully!');
    print('   Total elements: ${elements.length}');
    _showSuccess('✅ Layout applied with ${elements.length} unique elements!');
  });
}

  // ✅ TAMBAHKAN METHOD FORM INPUT MODE
Widget _buildFormInputMode() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Form Input',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      'Isi field-field di bawah ini, lalu klik "Generate Layout"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Form Fields
        _buildFormField('company_name', 'Company Name', 'PT TRISURYA SOLUSINDO UTAMA'),
        _buildFormField('title', 'Title', 'Quality Control'),
        _buildFormField('material_name', 'Material Name', 'Beras Premium'),
        _buildFormField('material_grade', 'Grade', 'A'),
        _buildFormField('batch_number', 'Batch Number', 'BATCH-2025-001'),
        _buildFormField('gross_weight', 'Gross Weight', '125.50 KG'),
        _buildFormField('tare_weight', 'Tare Weight', '100.00 KG'),
        _buildFormField('net_weight', 'Net Weight', '25.50 KG'),
        _buildFormField('date_time', 'Date & Time', '19/11/2025 16:27'),
        _buildFormField('operator_name', 'Operator Name', 'Dimas'),
        
        const SizedBox(height: 24),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _applyCompactLayout,
                icon: const Icon(Icons.dashboard),
                label: const Text('Generate Compact Layout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _currentDesignMode = DesignMode.DRAG_DROP;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Kembali ke Drag & Drop Mode'),
        ),
      ],
    ),
  );
}

// ✅ TAMBAHKAN METHOD BUILD FORM FIELD
Widget _buildFormField(String key, String label, String hint) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: _formControllers[key],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
  );
}

// ✅ TAMBAHKAN METHOD MODE SELECTOR
Widget _buildModeSelector() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
    ),
    child: Row(
      children: [
        const Text(
          'Design Mode:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        ToggleButtons(
          isSelected: [
            _currentDesignMode == DesignMode.DRAG_DROP,
            _currentDesignMode == DesignMode.FORM_INPUT,
          ],
          onPressed: (index) {
            setState(() {
              _currentDesignMode = index == 0 ? DesignMode.DRAG_DROP : DesignMode.FORM_INPUT;
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, size: 16),
                  SizedBox(width: 8),
                  Text('Drag & Drop'),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.edit_note, size: 16),
                  SizedBox(width: 8),
                  Text('Form Input'),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> _loadPrinterSettings() async {
  _isAutoDetectEnabled = await PrinterPersistenceService.isAutoDetectEnabled();
  
  final lastPrinter = await PrinterPersistenceService.getLastPrinter();
  
  if (lastPrinter != null && mounted) {
    setState(() {
      _connectedPrinterName = lastPrinter['name'];
      _connectedPrinterModel = lastPrinter['model'];
      _connectedPrinterAddress = lastPrinter['address'];
    });
    
    print('📌 Loaded last printer: $_connectedPrinterName');
  }
}

  Future<void> _checkAndFixDatabase() async {
  print('🔍 Checking database schema...');
  
  try {
    // Test: coba buat template sederhana
    final testTemplate = LabelTemplate(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test Template',
      width: 58.0,
      height: 50.0,
      printerType: 'TSC',
      paperSize: '58x50',
      elements: [],
      isActive: false,
      createdAt: DateTime.now(),
    );
    
    // Coba convert ke map (test serialization)
    final map = testTemplate.toMap();
    print('✅ Template serialization OK');
    print('   Keys: ${map.keys.toList()}');
    
    // Coba save ke database
    await dbHelper.createLabelTemplate(testTemplate);
    print('✅ Database save OK');
    
    // Hapus test template
    await dbHelper.deleteLabelTemplate(testTemplate.id);
    print('✅ Database schema verified!');
    
  } catch (e) {
    print('❌ Database schema check FAILED: $e');
    print('🔧 Attempting to fix schema...');
    
    // Fix schema
    await dbHelper.fixLabelTemplatesSchema();
    
    print('✅ Schema fix completed. Please restart app.');
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Database Updated'),
          content: const Text(
            'Database schema telah diperbaiki.\n\n'
            'Silakan restart aplikasi untuk melanjutkan.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    
    rethrow;
  }
}

  // ========== DATABASE OPERATIONS ==========
  
  Future<void> _loadTemplates() async {
  print('\n🔍 ═══════════════════════════════════════════════════');
  print('📂 LOADING TEMPLATES...');
  print('═══════════════════════════════════════════════════');
  
  setState(() => _isLoading = true);
  
  try {
    // ✅ STEP 1: Force fix table schema
    print('🔧 Step 1: Fixing table schema...');
    await dbHelper.forceFixLabelTemplatesTable();
    print('✅ Table schema fixed');
    
    // ✅ STEP 2: Load templates from database
    print('\n📥 Step 2: Reading templates from database...');
    final templates = await dbHelper.readAllLabelTemplates();
    print('✅ Loaded ${templates.length} templates');
    
    // ✅ STEP 3: Check if we have a valid TSC template
    final tscTemplates = templates.where((t) => 
      t.printerType == 'TSC' && 
      t.width > 0 && 
      t.height > 0
    ).toList();
    
    print('\n🔍 TSC Templates found: ${tscTemplates.length}');
    
    // ✅ STEP 4: If no valid TSC template, create one
    if (tscTemplates.isEmpty) {
      print('\n⚠️  No valid TSC template found! Creating default...');
      
      final defaultTemplate = LabelTemplate(
        id: 'template_tsc_default_${DateTime.now().millisecondsSinceEpoch}',
        name: 'TSC Label 58x50',
        width: 58.0,
        height: 50.0,
        printerType: 'TSC',
        paperSize: '58x50',
        elements: [],
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      print('\n📝 Creating TSC default template:');
      print('   ID: ${defaultTemplate.id}');
      print('   Name: ${defaultTemplate.name}');
      print('   Size: ${defaultTemplate.width}x${defaultTemplate.height}mm');
      print('   Printer: ${defaultTemplate.printerType}');
      
      // ✅ Save to database
      await dbHelper.createLabelTemplate(defaultTemplate);
      print('✅ TSC template saved to database');
      
      // ✅ Verify save
      final verify = await dbHelper.getLabelTemplateById(defaultTemplate.id);
      if (verify == null) {
        throw Exception('❌ TSC template created but not found in database!');
      }
      print('✅ TSC template verified in database');
      
      // ✅ Update UI
      setState(() {
        _templates = [defaultTemplate, ...templates];
        _currentTemplate = defaultTemplate;
        _isLoading = false;
      });
      
      print('\n✅ UI updated with TSC template');
      print('   _templates.length: ${_templates.length}');
      print('   _currentTemplate: ${_currentTemplate?.name}');
      print('   _currentTemplate.printerType: ${_currentTemplate?.printerType}');
      
      _showSuccess('✅ TSC Label template berhasil dibuat!');
      
    } else {
      // ✅ STEP 5: Valid TSC templates exist, use active or first
      print('\n✅ Valid TSC templates found, selecting...');
      
      // Prefer active TSC template
      LabelTemplate selectedTemplate;
      
      final activeTsc = tscTemplates.firstWhere(
        (t) => t.isActive,
        orElse: () => tscTemplates.first,
      );
      
      selectedTemplate = activeTsc;
      
      setState(() {
        _templates = templates;
        _currentTemplate = selectedTemplate;
        _isLoading = false;
      });
      
      print('✅ TSC template selected: ${selectedTemplate.name}');
      print('   Size: ${selectedTemplate.width}x${selectedTemplate.height}mm');
      print('   Printer: ${selectedTemplate.printerType}');
      print('   Elements: ${selectedTemplate.elements.length}');
    }
    
    print('\n═══════════════════════════════════════════════════');
    print('✅ ✅ ✅ TEMPLATES LOADED SUCCESSFULLY! ✅ ✅ ✅');
    print('   Total templates: ${_templates.length}');
    print('   Current template: ${_currentTemplate?.name}');
    print('   Printer type: ${_currentTemplate?.printerType}');
    print('   Canvas size: ${_currentTemplate?.width}x${_currentTemplate?.height}mm');
    print('   Loading: $_isLoading');
    print('═══════════════════════════════════════════════════\n');
    
  } catch (e, stackTrace) {
    print('\n❌ ❌ ❌ ERROR LOADING TEMPLATES ❌ ❌ ❌');
    print('Error: $e');
    print('Stack trace:');
    print(stackTrace);
    print('═══════════════════════════════════════════════════\n');
    
    setState(() => _isLoading = false);
    
    _showError('Error loading templates:\n\n$e');
    
    // ✅ Create emergency TSC template
    print('🔄 Creating emergency TSC template...');
    try {
      final emergencyTemplate = LabelTemplate(
        id: 'template_emergency_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Emergency TSC Label',
        width: 58.0,
        height: 50.0,
        printerType: 'TSC',
        paperSize: '58x50',
        elements: [],
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      await dbHelper.createLabelTemplate(emergencyTemplate);
      
      setState(() {
        _templates = [emergencyTemplate];
        _currentTemplate = emergencyTemplate;
      });
      
      print('✅ Emergency TSC template created');
      _showSuccess('✅ Emergency template created!');
      
    } catch (emergencyError) {
      print('❌ Emergency creation failed: $emergencyError');
      _showError('Fatal error: Cannot create template');
    }
  }
}

  Future<void> _saveCurrentTemplate() async {
  if (_currentTemplate == null) {
    _showError('❌ Tidak ada template yang aktif');
    return;
  }

  try {
    print('\n🔍 ═══════════════════════════════════════════════════');
    print('📝 SAVING TEMPLATE: ${_currentTemplate!.name}');
    print('   ID: ${_currentTemplate!.id}');
    print('   Printer: ${_currentTemplate!.printerType}');
    print('   Paper: ${_currentTemplate!.paperSize}');
    print('   Size: ${_currentTemplate!.width}×${_currentTemplate!.height}mm');
    print('   Elements: ${_currentTemplate!.elements.length}');
    print('═══════════════════════════════════════════════════');
    
    // Validate template data
    if (_currentTemplate!.id.isEmpty) {
      throw Exception('Template ID tidak valid');
    }
    
    if (_currentTemplate!.name.isEmpty) {
      throw Exception('Template name tidak boleh kosong');
    }
    
    // Validate elements
    final elementsCount = _currentTemplate!.elements.length;
    print('\n📋 Total Elements: $elementsCount');
    
    if (elementsCount > 0) {
      print('─────────────────────────────────────────────────────');
      for (int i = 0; i < _currentTemplate!.elements.length; i++) {
        final elem = _currentTemplate!.elements[i];
        print('[$i] ${elem.variable} (${elem.label})');
        
        if (elem.id.isEmpty) {
          throw Exception('Element $i has invalid ID');
        }
        if (elem.variable.isEmpty) {
          throw Exception('Element $i has empty variable');
        }
      }
      print('─────────────────────────────────────────────────────');
    }
    
    // Test JSON serialization
    print('\n🔬 Testing JSON Serialization...');
    
    try {
      final templateMap = _currentTemplate!.toMap();
      final elementsJson = templateMap['elements'] as String?;
      
      if (elementsJson == null || elementsJson.isEmpty) {
        throw Exception('Elements JSON is null or empty!');
      }
      
      print('✅ JSON Serialization OK');
      print('   JSON Length: ${elementsJson.length} chars');
      
      // Test deserialization
      final decoded = jsonDecode(elementsJson);
      if (decoded is! List) {
        throw Exception('Decoded JSON is not a List!');
      }
      
      print('✅ JSON Deserialization OK');
      print('   Decoded Elements: ${decoded.length}');
      
      if (decoded.length != elementsCount) {
        throw Exception('Decoded count mismatch! Expected: $elementsCount, Got: ${decoded.length}');
      }
      
    } catch (e) {
      print('❌ JSON Serialization FAILED: $e');
      throw Exception('Failed to serialize template: $e');
    }
    
    // Update timestamp before saving
    final templateToSave = _currentTemplate!.copyWith(
      updatedAt: DateTime.now(),
    );
    
    // Save to database
    print('\n💾 Saving to database...');
    
    final result = await dbHelper.updateLabelTemplate(templateToSave);
    
    if (result == 0) {
      throw Exception('Database update returned 0 (no rows affected)');
    }
    
    print('✅ Database save successful (affected rows: $result)');
    
    // Verify saved data
    print('\n🔍 Verifying saved data...');
    
    final savedTemplate = await dbHelper.getLabelTemplateById(templateToSave.id);
    
    if (savedTemplate == null) {
      throw Exception('Failed to load saved template from database!');
    }
    
    print('✅ Template loaded back from database');
    print('   Loaded Elements: ${savedTemplate.elements.length}');
    
    // Compare counts
    if (savedTemplate.elements.length != elementsCount) {
      print('\n❌❌❌ CRITICAL ERROR: ELEMENT COUNT MISMATCH! ❌❌❌');
      print('   Expected: $elementsCount');
      print('   Got: ${savedTemplate.elements.length}');
      print('   LOST: ${elementsCount - savedTemplate.elements.length} elements');
      
      // Show which elements are missing
      final originalVars = _currentTemplate!.elements.map((e) => e.variable).toSet();
      final savedVars = savedTemplate.elements.map((e) => e.variable).toSet();
      final missing = originalVars.difference(savedVars);
      
      if (missing.isNotEmpty) {
        print('   Missing variables: $missing');
      }
      
      throw Exception('Elements were lost during save! Check database encoding.');
    }
    
    // Compare individual elements
    for (int i = 0; i < elementsCount; i++) {
      final original = _currentTemplate!.elements[i];
      final saved = savedTemplate.elements.firstWhere(
        (e) => e.id == original.id,
        orElse: () => throw Exception('Element ${original.id} not found in saved template'),
      );
      
      if (original.variable != saved.variable) {
        print('⚠️  Element $i variable changed: ${original.variable} → ${saved.variable}');
      }
      if (original.x != saved.x || original.y != saved.y) {
        print('⚠️  Element $i position changed: (${original.x},${original.y}) → (${saved.x},${saved.y})');
      }
    }
    
    print('✅ All elements verified successfully!');
    
    // Update UI state with saved version
    setState(() {
      _currentTemplate = savedTemplate;
    });
    
    print('\n═══════════════════════════════════════════════════');
    print('✅✅✅ TEMPLATE SAVED SUCCESSFULLY! ✅✅✅');
    print('═══════════════════════════════════════════════════\n');
    
    _showSuccess('✅ Template "${_currentTemplate!.name}" berhasil disimpan!');
    
  } catch (e, stackTrace) {
    print('\n❌❌❌ ERROR SAVING TEMPLATE ❌❌❌');
    print('Error: $e');
    print('Stack trace:');
    print(stackTrace);
    print('═══════════════════════════════════════════════════\n');
    
    _showError('❌ Gagal menyimpan template:\n\n$e');
  }
}

Future<void> _switchToTemplate(String templateId) async {
  try {
    print('🔄 Switching to template: $templateId');
    
    // 1. Set template as active di database
    await dbHelper.setActiveLabelTemplate(templateId);
    
    // 2. Reload templates untuk update flag isActive
    final updatedTemplates = await dbHelper.readAllLabelTemplates();
    
    // 3. Find selected template
    final selectedTemplate = updatedTemplates.firstWhere((t) => t.id == templateId);
    
    // 4. Update state
    setState(() {
      _templates = updatedTemplates;
      _currentTemplate = selectedTemplate;
      _selectedElement = null;
    });
    
    print('✅ Template switched successfully!');
    print('   Active template: ${_currentTemplate!.name}');
    print('   IsActive flag: ${_currentTemplate!.isActive}');
    
    _showSuccess('✅ Template "${_currentTemplate!.name}" diaktifkan!');
    
  } catch (e) {
    print('❌ Error switching template: $e');
    _showError('Gagal switch template: $e');
  }
}

  void _createNewTemplate() async {
  final preset = PaperPresets.tsc58x50;
  
  final newTemplate = LabelTemplate(
    id: 'template_${DateTime.now().millisecondsSinceEpoch}',
    name: 'Template ${_templates.length + 1}',
    width: preset.width,
    height: preset.height,
    printerType: 'TSC',
    paperSize: preset.name,
    elements: [],
    isActive: _templates.isEmpty,
    createdAt: DateTime.now(),
  );

  try {
    await dbHelper.createLabelTemplate(newTemplate);
    
    // ✅ UPDATE STATE LANGSUNG (TANPA RELOAD!)
    setState(() {
      _templates.add(newTemplate);
      _currentTemplate = newTemplate;
      _selectedElement = null;
    });
    
    _showSuccess('Template baru dibuat (TSC 58x50mm)');
  } catch (e) {
    print('Error creating template: $e');
    _showError('Gagal membuat template baru');
  }
}

  // ✅ NEW: Show template settings dialog
  void _showTemplateSettings() {
  if (_currentTemplate == null) return;
  
  showDialog(
    context: context,
    builder: (context) => TemplateSettingsDialog(
      currentPrinterType: _currentTemplate!.printerType,
      currentPaperSize: _currentTemplate!.paperSize,
      onApply: (printerType, paperSize, width, height) async {
        // ✅ FIX: Jangan hapus elements, tapi filter berdasarkan compatibility
        
        final printerTypeChanged = _currentTemplate!.printerType != printerType;
        List<LabelElement> keptElements = [];
        List<String> removedFields = [];
        
        if (printerTypeChanged) {
          // Filter elements: keep only compatible ones
          for (var element in _currentTemplate!.elements) {
            final field = LabelFields.allFields.firstWhere(
              (f) => f.variable == element.variable,
              orElse: () => AvailableField(
                variable: element.variable,
                label: element.label,
                category: 'Custom',
                icon: Icons.text_fields,
                supportedPrinters: ['TSC', 'ESCPOS'], // Default: support both
              ),
            );
            
            if (field.supportsPrinter(printerType)) {
              keptElements.add(element);
            } else {
              removedFields.add(field.label);
            }
          }
          
          print('🔍 Printer type changed: ${_currentTemplate!.printerType} → $printerType');
          print('   Kept: ${keptElements.length} fields');
          print('   Removed: ${removedFields.length} fields (${removedFields.join(", ")})');
        } else {
          // Printer type tidak berubah, keep semua elements
          keptElements = _currentTemplate!.elements;
        }
        
        setState(() {
          _currentTemplate = _currentTemplate!.copyWith(
            width: width,
            height: height,
            printerType: printerType,
            paperSize: paperSize,
            elements: keptElements,
            updatedAt: DateTime.now(),
          );
          
          // Clear selection if removed
          if (_selectedElement != null && 
              !keptElements.any((e) => e.id == _selectedElement!.id)) {
            _selectedElement = null;
          }
        });
        
        // ✅ CRITICAL: Save to database immediately!
        await _saveCurrentTemplate();
        
        // Show notification
        if (printerTypeChanged && removedFields.isNotEmpty) {
          _showSuccess(
            '⚠️ Template updated!\n'
            'Removed ${removedFields.length} incompatible fields:\n'
            '${removedFields.take(3).join(", ")}${removedFields.length > 3 ? "..." : ""}'
          );
        } else {
          _showSuccess(
            '✓ Template: $printerType ${width.toStringAsFixed(0)}×${height.toStringAsFixed(0)}mm',
          );
        }
      },
    ),
  );
}

/// Called dari Bluetooth service saat printer berhasil connect
Future<void> onPrinterConnected({
  required String printerName,
  required String printerModel,
  required String printerAddress,
}) async {
  print('\n🔌 ═══════════════════════════════════════════════════');
  print('📡 PRINTER CONNECTED');
  print('   Name: $printerName');
  print('   Model: $printerModel');
  print('   Address: $printerAddress');
  print('═══════════════════════════════════════════════════');
  
  // ✅ UPDATE STATE DULU
  setState(() {
    _connectedPrinterName = printerName;
    _connectedPrinterModel = printerModel;
    _connectedPrinterAddress = printerAddress;
  });
  
  // Detect printer type & paper
  final detection = PrinterDetectionResult.fromPrinter(
    printerName,
    printerModel,
  );
  
  print(detection);
  
  // Save to persistence
  await PrinterPersistenceService.saveLastPrinter(
    printerName: printerName,
    printerModel: printerModel,
    printerAddress: printerAddress,
    detectedType: detection.detectedPrinterType,
    detectedPaperType: detection.detectedPaperType,
  );
  
  await PrinterPersistenceService.addToHistory(
    printerName: printerName,
    printerModel: printerModel,
    printerAddress: printerAddress,
  );
  
  // ✅ CRITICAL FIX: Check if template exists and needs update
  if (_currentTemplate == null) {
    print('⚠️  No template loaded, skipping auto-update');
    _showSuccess('✓ Printer connected: $printerName');
    return;
  }
  
  // ✅ NEW: Always check compatibility
  final shouldUpdate = _shouldAutoUpdateTemplate(
    detection.detectedPrinterType,
    detection.detectedPaperType,
  );
  
  print('\n🔍 Template Check:');
  print('   Current Type: ${_currentTemplate!.printerType}');
  print('   Current Size: ${_currentTemplate!.width}x${_currentTemplate!.height}mm');
  print('   Detected Type: ${detection.detectedPrinterType}');
  print('   Should Update: $shouldUpdate');
  
  if (_isAutoDetectEnabled && shouldUpdate) {
    // ✅ OPTION A: Auto-update LANGSUNG tanpa konfirmasi
    /// Apply auto-detected settings LANGSUNG tanpa dialog konfirmasi
/// Gunakan ini jika Anda ingin fully automatic
Future<void> _applyAutoDetectedSettingsDirectly(
  PrinterDetectionResult detection,
) async {
  if (_currentTemplate == null) return;
  
  print('\n🔧 Applying auto-detected settings (direct mode)...');
  
  // Get preset
  PaperPreset? preset = _getPaperPresetByName(detection.recommendedPaperSize);
  
  if (preset == null) {
    print('❌ Paper size preset not found: ${detection.recommendedPaperSize}');
    _showError('Paper size preset not found: ${detection.recommendedPaperSize}');
    return;
  }
  
  // ✅ CRITICAL: Check if dimensions actually changed
  final widthChanged = (_currentTemplate!.width - preset.width).abs() > 0.1;
  final heightChanged = (_currentTemplate!.height - preset.height).abs() > 0.1;
  final typeChanged = _currentTemplate!.printerType != detection.detectedPrinterType;
  
  if (!widthChanged && !heightChanged && !typeChanged) {
    print('✅ Template already matches printer settings, no update needed');
    setState(() {}); // Just rebuild to update UI indicators
    return;
  }
  
  print('📐 Updating template dimensions:');
  print('   From: ${_currentTemplate!.width}×${_currentTemplate!.height}mm (${_currentTemplate!.printerType})');
  print('   To: ${preset.width}×${preset.height}mm (${detection.detectedPrinterType})');
  
  // Filter elements
  List<LabelElement> keptElements = [];
  List<String> removedFields = [];
  
  for (var element in _currentTemplate!.elements) {
    final field = LabelFields.allFields.firstWhere(
      (f) => f.variable == element.variable,
      orElse: () => AvailableField(
        variable: element.variable,
        label: element.label,
        category: 'Custom',
        icon: Icons.text_fields,
        supportedPrinters: ['TSC', 'ESCPOS'],
      ),
    );
    
    if (field.supportsPrinter(detection.detectedPrinterType)) {
      keptElements.add(element);
    } else {
      removedFields.add(field.label);
    }
  }
  
  // ✅ UPDATE TEMPLATE
  setState(() {
    _currentTemplate = _currentTemplate!.copyWith(
      width: preset!.width,
      height: preset.height,
      printerType: detection.detectedPrinterType,
      paperSize: detection.recommendedPaperSize,
      elements: keptElements,
      updatedAt: DateTime.now(),
    );
    
    if (_selectedElement != null && 
        !keptElements.any((e) => e.id == _selectedElement!.id)) {
      _selectedElement = null;
    }
  });
  
  // ✅ SAVE TO DATABASE
  await _saveCurrentTemplate();
  
  // Show notification
  final message = StringBuffer();
  message.writeln('✅ Canvas auto-updated!');
  message.writeln('');
  message.writeln('Printer: ${detection.detectedPrinterType}');
  message.writeln('Size: ${preset.width.toInt()}×${preset.height.toInt()}mm');
  
  if (removedFields.isNotEmpty) {
    message.writeln('');
    message.writeln('⚠️ Removed ${removedFields.length} incompatible fields');
  }
  
  _showSuccess(message.toString());
  
  print('✅ Auto-update completed!');
  print('   Canvas: ${_currentTemplate!.width}×${_currentTemplate!.height}mm');
  print('   Kept: ${keptElements.length} elements');
  print('   Removed: ${removedFields.length} elements');
}
    
    // ✅ OPTION B: Auto-update DENGAN konfirmasi (current)
    await _applyAutoDetectedSettingsDirectly(detection);
  } else {
    // Template sudah sesuai, tapi tetap update UI untuk reflect connection
    setState(() {}); // Trigger rebuild untuk update indicator
    
    _showSuccess(
      '✓ Printer connected: $printerName\n'
      'Type: ${detection.detectedPrinterType}\n'
      'Template: ${_currentTemplate!.printerType} '
      '${_currentTemplate!.width.toInt()}×${_currentTemplate!.height.toInt()}mm ✓',
    );
  }
  
  print('═══════════════════════════════════════════════════\n');
}

bool _shouldAutoUpdateTemplate(String newPrinterType, String newPaperType) {
  if (_currentTemplate == null) return false;
  
  final currentType = _currentTemplate!.printerType;
  
  // ✅ Check 1: Printer type berubah (ESC/POS ↔ TSC)
  final typeChanged = currentType != newPrinterType;
  
  if (typeChanged) {
    print('⚠️  Printer type changed: $currentType → $newPrinterType');
    return true;
  }
  
  // ✅ Check 2: Canvas size invalid (width/height = 0)
  if (_currentTemplate!.width <= 0 || _currentTemplate!.height <= 0) {
    print('⚠️  Canvas size invalid: ${_currentTemplate!.width}×${_currentTemplate!.height}mm');
    return true;
  }
  
  // ✅ Check 3: Paper size tidak compatible
  final currentPaperSize = _currentTemplate!.paperSize;
  final isCompatible = PrinterConfig.isPaperSizeCompatible(
    currentPaperSize,
    newPrinterType,
  );
  
  if (!isCompatible) {
    print('⚠️  Paper size not compatible with new printer');
    print('   Current: $currentPaperSize');
    print('   Printer: $newPrinterType');
    return true;
  }
  
  // ✅ Check 4: Canvas size tidak sesuai dengan paper size
  // Misalnya template claim 58x50 tapi actual size berbeda
  final expectedPreset = _getPaperPresetByName(currentPaperSize);
  if (expectedPreset != null) {
    final widthMismatch = (_currentTemplate!.width - expectedPreset.width).abs() > 1.0;
    final heightMismatch = (_currentTemplate!.height - expectedPreset.height).abs() > 1.0;
    
    if (widthMismatch || heightMismatch) {
      print('⚠️  Canvas size mismatch with paper size:');
      print('   Expected: ${expectedPreset.width}×${expectedPreset.height}mm');
      print('   Actual: ${_currentTemplate!.width}×${_currentTemplate!.height}mm');
      return true;
    }
  }
  
  print('✅ Template compatible with printer, no update needed');
  return false;
}

Future<void> _applyAutoDetectedSettingsDirectly(
  PrinterDetectionResult detection,
) async {
  if (_currentTemplate == null) return;
  
  print('\n🔧 Applying auto-detected settings (direct mode)...');
  
  PaperPreset? preset = _getPaperPresetByName(detection.recommendedPaperSize);
  
  if (preset == null) {
    print('❌ Paper size preset not found: ${detection.recommendedPaperSize}');
    _showError('Paper size preset not found: ${detection.recommendedPaperSize}');
    return;
  }
  
  // Check if dimensions actually changed
  final widthChanged = (_currentTemplate!.width - preset.width).abs() > 0.1;
  final heightChanged = (_currentTemplate!.height - preset.height).abs() > 0.1;
  final typeChanged = _currentTemplate!.printerType != detection.detectedPrinterType;
  
  if (!widthChanged && !heightChanged && !typeChanged) {
    print('✅ Template already matches printer settings');
    setState(() {});
    return;
  }
  
  print('📐 Updating template dimensions:');
  print('   From: ${_currentTemplate!.width}×${_currentTemplate!.height}mm');
  print('   To: ${preset.width}×${preset.height}mm');
  
  // Filter elements
  List<LabelElement> keptElements = [];
  List<String> removedFields = [];
  
  for (var element in _currentTemplate!.elements) {
    final field = LabelFields.allFields.firstWhere(
      (f) => f.variable == element.variable,
      orElse: () => AvailableField(
        variable: element.variable,
        label: element.label,
        category: 'Custom',
        icon: Icons.text_fields,
        supportedPrinters: ['TSC', 'ESCPOS'],
      ),
    );
    
    if (field.supportsPrinter(detection.detectedPrinterType)) {
      keptElements.add(element);
    } else {
      removedFields.add(field.label);
    }
  }
  
  setState(() {
    _currentTemplate = _currentTemplate!.copyWith(
      width: preset.width,
      height: preset.height,
      printerType: detection.detectedPrinterType,
      paperSize: detection.recommendedPaperSize,
      elements: keptElements,
      updatedAt: DateTime.now(),
    );
    
    if (_selectedElement != null && 
        !keptElements.any((e) => e.id == _selectedElement!.id)) {
      _selectedElement = null;
    }
  });
  
  await _saveCurrentTemplate();
  
  _showSuccess(
    '✅ Canvas auto-updated!\n'
    'Printer: ${detection.detectedPrinterType}\n'
    'Size: ${preset.width.toInt()}×${preset.height.toInt()}mm'
  );
  
  print('✅ Auto-update completed!');
}

Future<void> _applyAutoDetectedSettings(PrinterDetectionResult detection) async {
  if (_currentTemplate == null) return;
  
  final confirm = await _showAutoUpdateDialog(detection);
  
  if (!confirm) {
    print('❌ User declined auto-update');
    return;
  }
  
  print('\n🔧 Applying auto-detected settings...');
  
  PaperPreset? preset = _getPaperPresetByName(detection.recommendedPaperSize);
  
  if (preset == null) {
    _showError('Paper size preset not found: ${detection.recommendedPaperSize}');
    return;
  }
  
  List<LabelElement> keptElements = [];
  List<String> removedFields = [];
  
  for (var element in _currentTemplate!.elements) {
    final field = LabelFields.allFields.firstWhere(
      (f) => f.variable == element.variable,
      orElse: () => AvailableField(
        variable: element.variable,
        label: element.label,
        category: 'Custom',
        icon: Icons.text_fields,
        supportedPrinters: ['TSC', 'ESCPOS'],
      ),
    );
    
    if (field.supportsPrinter(detection.detectedPrinterType)) {
      keptElements.add(element);
    } else {
      removedFields.add(field.label);
    }
  }
  
  setState(() {
    _currentTemplate = _currentTemplate!.copyWith(
      width: preset!.width,
      height: preset.height,
      printerType: detection.detectedPrinterType,
      paperSize: detection.recommendedPaperSize,
      elements: keptElements,
      updatedAt: DateTime.now(),
    );
    
    if (_selectedElement != null && 
        !keptElements.any((e) => e.id == _selectedElement!.id)) {
      _selectedElement = null;
    }
  });
  
  await _saveCurrentTemplate();
  
  final message = StringBuffer();
  message.writeln('✅ Template updated automatically!');
  message.writeln('');
  message.writeln('Printer: ${detection.detectedPrinterType}');
  message.writeln('Paper: ${detection.recommendedPaperSize}');
  message.writeln('Size: ${preset.width}×${preset.height}mm');
  
  if (removedFields.isNotEmpty) {
    message.writeln('');
    message.writeln('⚠️ Removed ${removedFields.length} incompatible fields:');
    message.writeln(removedFields.take(3).join(', '));
    if (removedFields.length > 3) {
      message.write(' + ${removedFields.length - 3} more');
    }
  }
  
  _showSuccess(message.toString());
  
  print('✅ Auto-update completed!');
  print('   Kept: ${keptElements.length} elements');
  print('   Removed: ${removedFields.length} elements');
}

Future<bool> _showAutoUpdateDialog(PrinterDetectionResult detection) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_fix_high, color: Colors.blue[700]),
          const SizedBox(width: 12),
          const Text('Auto-Detect Settings'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Printer yang terhubung terdeteksi sebagai:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('Printer', detection.printerName),
          _buildInfoRow('Model', detection.printerModel),
          _buildInfoRow('Type', detection.detectedPrinterType),
          _buildInfoRow('Paper Type', detection.detectedPaperType),
          _buildInfoRow('Paper Size', detection.recommendedPaperSize),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Template akan disesuaikan secara otomatis dengan printer ini.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Tidak, Biarkan Manual'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check),
          label: const Text('Ya, Update Otomatis'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  ) ?? false;
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

PaperPreset? _getPaperPresetByName(String name) {
  // TSC Label presets (gunakan preset yang sudah ada)
  if (name == '58x50 Label') return PaperPresets.tsc58x50;
  if (name == '58x40 Label') return PaperPresets.tsc58x40;
  if (name == '72x50 Label') return PaperPresets.tsc72x50;
  if (name == '100x70 Label') return PaperPresets.tsc100x70;
  
  // ✅ PERBAIKAN: Custom preset dengan parameter yang benar
  if (name.contains('100') && name.contains('50')) {
    return const PaperPreset(
      name: '100x50',
      displayName: '100mm x 50mm (TSC)',  // ✅ Required parameter
      width: 100.0,
      height: 50.0,
      printerType: 'TSC',
      description: '100mm x 50mm label for TSC printer',
    );
  }
  if (name.contains('100') && name.contains('100')) {
    return const PaperPreset(
      name: '100x100',
      displayName: '100mm x 100mm (TSC)',  // ✅ Required parameter
      width: 100.0,
      height: 100.0,
      printerType: 'TSC',
      description: '100mm x 100mm label for TSC printer',
    );
  }
  
  // ESC/POS Receipt presets (gunakan preset yang sudah ada)
  if (name == '58mm Struk') return PaperPresets.escpos58;
  if (name == '80mm Struk') return PaperPresets.escpos80;
  
  // ✅ Fallback: cari di PaperPresets.allPresets
  return PaperPresets.getPreset(name);
}

void _showPrinterSettingsDialog() async {
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_bluetooth),
            SizedBox(width: 12),
            Text('Printer Settings'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ AUTO-DETECT TOGGLE ═══
              SwitchListTile(
                title: const Text('Auto-detect Paper Type'),
                subtitle: const Text(
                  'Otomatis sesuaikan kertas dengan printer',
                  style: TextStyle(fontSize: 12),
                ),
                value: _isAutoDetectEnabled,
                onChanged: (value) async {
                  await PrinterPersistenceService.setAutoDetectEnabled(value);
                  setState(() => _isAutoDetectEnabled = value);
                  setDialogState(() {});
                },
              ),
              
              const Divider(),
              
              // ═══ CONNECTED PRINTER INFO ═══
              const Text(
                'Connected Printer:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (_connectedPrinterName != null) ...[
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.bluetooth_connected,
                    color: Colors.green[700],
                  ),
                  title: Text(_connectedPrinterName!),
                  subtitle: Text(
                    _connectedPrinterModel ?? 'Unknown model',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () {
                      final detection = PrinterDetectionResult.fromPrinter(
                        _connectedPrinterName!,
                        _connectedPrinterModel ?? '',
                      );
                      
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Printer Info'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Name', detection.printerName),
                              _buildInfoRow('Model', detection.printerModel),
                              _buildInfoRow('Type', detection.detectedPrinterType),
                              _buildInfoRow('Paper Type', detection.detectedPaperType),
                              _buildInfoRow('Paper Size', detection.recommendedPaperSize),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.bluetooth_disabled, color: Colors.grey),
                  title: Text('No printer connected'),
                  subtitle: Text(
                    'Connect a printer from main menu',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
              
              const Divider(),
              
              // ═══ PRINTER HISTORY ═══
              const Text(
                'Recent Printers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              FutureBuilder<List<Map<String, dynamic>>>(
                future: PrinterPersistenceService.getHistory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No printer history',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: snapshot.data!.map((printer) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history, size: 20),
                        title: Text(printer['name']),
                        subtitle: Text(
                          printer['address'],
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: const Icon(Icons.info_outline, size: 18),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(printer['name']),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Model: ${printer['model']}'),
                                  Text('Address: ${printer['address']}'),
                                  Text('Last used: ${printer['lastUsed']}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Data?'),
                  content: const Text(
                    'Hapus semua printer history dan settings?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await PrinterPersistenceService.clearAll();
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccess('Printer data cleared');
                }
              }
            },
            child: const Text('Clear Data'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}

  // ========== ELEMENT OPERATIONS ==========
  // ✅ TAMBAHKAN 3 METHOD INI DI SINI
  void _updateControllers() {
    if (_selectedElement == null) return;
    
    _xController.text = (_selectedElement!.x / pxPerMm).toStringAsFixed(1);
    _yController.text = (_selectedElement!.y / pxPerMm).toStringAsFixed(1);
    _widthController.text = (_selectedElement!.width / pxPerMm).toStringAsFixed(1);
    _heightController.text = (_selectedElement!.height / pxPerMm).toStringAsFixed(1);
    _fontSizeController.text = _selectedElement!.fontSize.toStringAsFixed(0);
  }

  void _applyManualChanges() {
    if (_selectedElement == null) return;

    try {
      final x = (double.tryParse(_xController.text) ?? 0) * pxPerMm;
      final y = (double.tryParse(_yController.text) ?? 0) * pxPerMm;
      final width = (double.tryParse(_widthController.text) ?? 0) * pxPerMm;
      final height = (double.tryParse(_heightController.text) ?? 0) * pxPerMm;
      final fontSize = double.tryParse(_fontSizeController.text) ?? 12;

      final maxX = (_currentTemplate!.width * pxPerMm) - width;
      final maxY = (_currentTemplate!.height * pxPerMm) - height;

      setState(() {
        _updateElement(_selectedElement!.copyWith(
          x: x.clamp(0, maxX),
          y: y.clamp(0, maxY),
          width: width.clamp(10, _currentTemplate!.width * pxPerMm),
          height: height.clamp(10, _currentTemplate!.height * pxPerMm),
          fontSize: fontSize.clamp(6, 72),
        ));
        _updateControllers();
      });

      _showSuccess('✓ Changes applied');
    } catch (e) {
      _showError('Invalid input values');
    }
  }

  void _applySizePreset(String preset) {
    if (_selectedElement == null) return;

    double width, height, fontSize;
    
    switch (preset) {
      case 'small':
        width = 20; height = 6; fontSize = 8;
        break;
      case 'normal':
        width = 30; height = 8; fontSize = 10;
        break;
      case 'medium':
        width = 40; height = 10; fontSize = 12;
        break;
      case 'large':
        width = 50; height = 12; fontSize = 14;
        break;
      case 'xlarge':
        width = 60; height = 15; fontSize = 16;
        break;
      default:
        return;
    }

    setState(() {
      _updateElement(_selectedElement!.copyWith(
        width: width * pxPerMm,
        height: height * pxPerMm,
        fontSize: fontSize,
      ));
      _updateControllers();
    });

    _showSuccess('✓ $preset preset applied');
  }
  
  void _addElement(AvailableField field) {
    if (_currentTemplate == null) return;

    final newElement = LabelElement(
      id: 'element_${DateTime.now().millisecondsSinceEpoch}',
      variable: field.variable,
      label: field.label,
      x: 20,
      y: 20 + (_currentTemplate!.elements.length * 35),
      width: 150,
      height: 30,
    );

    setState(() {
      _currentTemplate!.elements.add(newElement);
      _selectedElement = newElement;
      _updateControllers(); // ✅ TAMBAHKAN BARIS INI
    });
  }

  void _updateElement(LabelElement element) {
    if (_currentTemplate == null) return;

    setState(() {
      final index = _currentTemplate!.elements.indexWhere((e) => e.id == element.id);
      if (index >= 0) {
        _currentTemplate!.elements[index] = element;
      }
    });
  }

  void _deleteElement(String elementId) {
    if (_currentTemplate == null) return;

    setState(() {
      _currentTemplate!.elements.removeWhere((e) => e.id == elementId);
      if (_selectedElement?.id == elementId) {
        _selectedElement = null;
      }
    });
  }

  /// Reset template - Clear all elements
void _resetTemplate() async {
  if (_currentTemplate == null) return;
  
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[700]),
          const SizedBox(width: 12),
          const Text('Reset Template?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ini akan menghapus SEMUA element dari template ini.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Template: ${_currentTemplate!.name}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Elements: ${_currentTemplate!.elements.length}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tip: Gunakan "Generate Compact Layout" untuk membuat ulang template otomatis.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Reset Template'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
  
  if (confirm == true) {
    print('\n🧹 ═══════════════════════════════════════════════════');
    print('🗑️ RESETTING TEMPLATE: ${_currentTemplate!.name}');
    print('   Removing ${_currentTemplate!.elements.length} elements...');
    print('═══════════════════════════════════════════════════');
    
    setState(() {
      _currentTemplate = _currentTemplate!.copyWith(
        elements: [], // Clear all elements
        updatedAt: DateTime.now(),
      );
      _selectedElement = null;
    });
    
    await _saveCurrentTemplate();
    
    print('✅ Template reset successfully!');
    print('═══════════════════════════════════════════════════\n');
    
    _showSuccess('✅ Template direset! Semua element telah dihapus.');
  }
}

/// Delete duplicate elements by variable
void _removeDuplicateElements() async {
  if (_currentTemplate == null) return;
  
  print('\n🔍 ═══════════════════════════════════════════════════');
  print('🧹 SCANNING FOR DUPLICATE ELEMENTS');
  print('   Template: ${_currentTemplate!.name}');
  print('   Total elements: ${_currentTemplate!.elements.length}');
  print('═══════════════════════════════════════════════════');
  
  // Scan untuk duplicates
  final Map<String, List<LabelElement>> groupedByVariable = {};
  
  for (var element in _currentTemplate!.elements) {
    final key = element.variable.toUpperCase();
    groupedByVariable.putIfAbsent(key, () => []).add(element);
  }
  
  // Find duplicates
  final duplicates = <String, int>{};
  for (var entry in groupedByVariable.entries) {
    if (entry.value.length > 1) {
      duplicates[entry.key] = entry.value.length;
      print('   ⚠️ Found duplicate: ${entry.key} (${entry.value.length}x)');
    }
  }
  
  if (duplicates.isEmpty) {
    print('✅ No duplicates found!');
    print('═══════════════════════════════════════════════════\n');
    
    _showSuccess('✅ Tidak ada duplikat! Template sudah bersih.');
    return;
  }
  
  // Show confirmation dialog
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700]),
          const SizedBox(width: 12),
          const Text('Duplikat Ditemukan!'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ditemukan ${duplicates.length} field yang duplikat:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...duplicates.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value} copies',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Untuk setiap field duplikat, hanya 1 element yang akan dipertahankan (yang terakhir).',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Hapus Duplikat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
  
  if (confirm == true) {
    // Remove duplicates - keep last one for each variable
    final uniqueElements = <LabelElement>[];
    final seenVariables = <String>{};
    
    // Process in reverse (so last element is kept)
    for (var element in _currentTemplate!.elements.reversed) {
      final key = element.variable.toUpperCase();
      if (!seenVariables.contains(key)) {
        uniqueElements.insert(0, element);
        seenVariables.add(key);
      } else {
        print('   ✂️ Removing duplicate: $key (ID: ${element.id})');
      }
    }
    
    final removedCount = _currentTemplate!.elements.length - uniqueElements.length;
    
    setState(() {
      _currentTemplate = _currentTemplate!.copyWith(
        elements: uniqueElements,
        updatedAt: DateTime.now(),
      );
      _selectedElement = null;
    });
    
    await _saveCurrentTemplate();
    
    print('✅ Duplicates removed!');
    print('   Before: ${_currentTemplate!.elements.length + removedCount} elements');
    print('   After: ${uniqueElements.length} elements');
    print('   Removed: $removedCount duplicates');
    print('═══════════════════════════════════════════════════\n');
    
    _showSuccess('✅ $removedCount duplikat berhasil dihapus!\n\nSekarang template punya ${uniqueElements.length} element unik.');
  }
}

  // ========== UI HELPERS ==========
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Get display value untuk preview canvas (dengan label jika showLabel = true)
String _getPreviewDisplayValue(LabelElement element) {
  // 1. Ambil raw value dari sample data
  String rawValue = SampleData.data[element.variable]?.toString() ?? '';
  
  // 2. Jika value kosong, gunakan placeholder
  if (rawValue.trim().isEmpty) {
    rawValue = '[${element.label}]';
  }
  
  // 3. Cek apakah perlu tampilkan label
  bool shouldShowLabel = element.showLabel ?? true;
  
  // 4. Jika tidak perlu label, return value aja
  if (!shouldShowLabel) {
    return rawValue;
  }
  
  // 5. Ambil label
  String label = element.label.trim();
  
  // 6. Jika label sama dengan variable, return value aja
  if (label.toUpperCase() == element.variable.toUpperCase()) {
    return rawValue;
  }
  
  // 7. Jika label kosong, return value aja
  if (label.isEmpty) {
    return rawValue;
  }
  
  // 8. Daftar field yang tidak perlu label
  final noLabelFields = [
    'T-CONNECT',
    'PT TRISURYA SOLUSINDO UTAMA',
    'HEADER',
    'FOOTER',
    'GARIS_PEMISAH',
  ];
  
  if (noLabelFields.contains(label)) {
    return rawValue;
  }
  
  // 9. ✅ FORMAT DENGAN LABEL
  return '$label: $rawValue';
}

  void _showManualFieldsEditor() async {
    if (_currentTemplate == null) return;

    final manualFields = _currentTemplate!.elements
        .where((e) {
          final field = LabelFields.allFields.firstWhere(
            (f) => f.variable == e.variable,
            orElse: () => AvailableField(
              variable: e.variable,
              label: e.variable,
              category: 'Lainnya',
              icon: Icons.text_fields,
              type: FieldType.manual,
            ),
          );
          return field.type == FieldType.manual;
        })
        .toList();

    if (manualFields.isEmpty) {
      _showError('Template ini tidak memiliki field manual input.\n\nTambahkan field dari kategori "Info Transaksi".');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => ManualFieldsEditorDialog(
        template: _currentTemplate!,
        manualFields: manualFields,
      ),
    );
  }

  // ✅ Get filtered fields based on printer type
  Map<String, List<AvailableField>> get _filteredFields {
    if (_currentTemplate == null) {
      return LabelFields.groupedFields;
    }
    return LabelFields.getGroupedFieldsByPrinterType(_currentTemplate!.printerType);
  }

  // ========== BUILD UI ==========

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Label Designer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentTemplate == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Label Designer')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Tidak ada template'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createNewTemplate,
                icon: const Icon(Icons.add),
                label: const Text('Buat Template Baru'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Visual Label Designer', style: TextStyle(fontSize: 18)),
      
      // ✅ PERBAIKAN: Row untuk info printer
      Row(
        children: [
          Text(
            '${_currentTemplate!.printerTypeDisplay} - ${_currentTemplate!.paperSize}',
            style: const TextStyle(fontSize: 11),
          ),
          
          // Printer indicator
          if (_connectedPrinterName != null) ...[
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 8),
            Icon(
              Icons.bluetooth_connected,
              size: 14,
              color: Colors.green[300],
            ),
            const SizedBox(width: 4),
            Text(
              _connectedPrinterName!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[300],
              ),
            ),
          ],
        ],
      ),
    ],
  ),
  
  actions: [
    // ✅ Printer Settings Button
    IconButton(
      icon: const Icon(Icons.settings_bluetooth),
      tooltip: 'Printer Settings',
      onPressed: _showPrinterSettingsDialog,
    ),
    
    // Template Settings Button
    IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Template Settings (Printer & Paper)',
      onPressed: _showTemplateSettings,
    ),
    
    // Template Dropdown
    Container(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: DropdownButton<String>(
    value: _currentTemplate!.id,
    dropdownColor: Colors.blue[700],
    style: const TextStyle(color: Colors.white),
    underline: Container(),
    items: _templates.map((template) {
      return DropdownMenuItem(
        value: template.id,
        child: Row(
          children: [
            Text(template.name),
            if (template.isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    }).toList(),
    // ✅ FIXED: Ganti dengan async call ke _switchToTemplate
    onChanged: (templateId) async {
      if (templateId != null) {
        await _switchToTemplate(templateId);
      }
    },
  ),
),
          
          // Toggle Field Panel
          IconButton(
            icon: Icon(_showFieldPanel ? Icons.chevron_left : Icons.chevron_right),
            tooltip: 'Toggle Field Panel',
            onPressed: () => setState(() => _showFieldPanel = !_showFieldPanel),
          ),
          
          // Preview Toggle
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
            tooltip: _isPreviewMode ? 'Edit Mode' : 'Preview Mode',
            onPressed: () => setState(() {
              _isPreviewMode = !_isPreviewMode;
              _selectedElement = null;
            }),
          ),

          // Manual Fields Editor
          if (!_isPreviewMode)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit Manual Input Fields',
              onPressed: _showManualFieldsEditor,
              color: Colors.white,
            ),

            // Remove Duplicates Button
IconButton(
  icon: const Icon(Icons.auto_fix_high),
  tooltip: 'Remove Duplicate Elements',
  onPressed: _removeDuplicateElements,
  color: Colors.orange,
),

// Reset Template Button
IconButton(
  icon: const Icon(Icons.delete_sweep),
  tooltip: 'Reset Template (Clear All)',
  onPressed: _resetTemplate,
  color: Colors.red,
),
          
          // Save Button
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Simpan Template',
            onPressed: _saveCurrentTemplate,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ TAMBAHKAN MODE SELECTOR DI SINI
          if (!_isPreviewMode) _buildModeSelector(),
          
          Expanded(
            child: Row(
              children: [
                // Left Panel: Field Library (hanya untuk drag-drop mode)
                if (_showFieldPanel && !_isPreviewMode && _currentDesignMode == DesignMode.DRAG_DROP)
                  Container(
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(right: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: _buildFieldLibrary(),
                  ),

                // Center: Canvas atau Form Input
                Expanded(
                  child: _currentDesignMode == DesignMode.FORM_INPUT 
                      ? _buildFormInputMode()  // ✅ MODE FORM INPUT
                      : _buildCanvas(),        // ✅ MODE DRAG-DROP
                ),

                // Right Panel: Properties (hanya untuk drag-drop mode)
                if (_selectedElement != null && !_isPreviewMode && _currentDesignMode == DesignMode.DRAG_DROP)
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(left: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: _buildPropertiesPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLibrary() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text(
              'Field Library',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _currentTemplate!.isTSCPrinter ? Colors.purple[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _currentTemplate!.printerType,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _currentTemplate!.isTSCPrinter ? Colors.purple[900] : Colors.blue[900],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ..._filteredFields.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(entry.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            
            // ✅ PERBAIKAN: Wrap dengan Draggable!
            ...entry.value.map((field) {
              return Draggable<AvailableField>(
                data: field,
                feedback: Material(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(field.icon, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(field.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: Icon(field.icon, size: 20, color: Colors.grey),
                      title: Text(field.label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ),
                  ),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: Icon(field.icon, size: 20, color: Colors.blue),
                    title: Text(field.label, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(field.variable, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                    trailing: const Icon(Icons.add, size: 18, color: Colors.green),
                    onTap: () => _addElement(field), // Keep tap untuk mobile
                  ),
                ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    ],
  );
}

  Widget _buildCanvas() {
  if (_currentTemplate == null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('Template tidak valid', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload Templates'),
          ),
        ],
      ),
    );
  }
  
  if (_currentTemplate!.width <= 0 || _currentTemplate!.height <= 0) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orange[700]),
            const SizedBox(height: 16),
            Text('Invalid Canvas Size',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 8),
            Text('Width: ${_currentTemplate!.width}mm, Height: ${_currentTemplate!.height}mm',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showTemplateSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Fix Template Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ✅ VALID TEMPLATE
  return LayoutBuilder(
    builder: (context, constraints) {
      final isLandscape = constraints.maxWidth > constraints.maxHeight;
      
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: isLandscape ? Axis.horizontal : Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: isLandscape ? Axis.vertical : Axis.horizontal,
              child: Builder(  // ✅ CRITICAL: Wrap dengan Builder untuk context yang benar!
                builder: (canvasContext) {
                  return DragTarget<AvailableField>(
                    onWillAcceptWithDetails: (details) {
                      print('🎯 Drag over canvas: ${details.data.label}');
                      return true;  // Accept all fields
                    },
                    onAcceptWithDetails: (details) {
                      print('\n✅ ═══════════════════════════════════════');
                      print('📦 DROPPED: ${details.data.label}');
                      print('═══════════════════════════════════════');
                      
                      // Get canvas RenderBox
                      final RenderBox canvasBox = canvasContext.findRenderObject() as RenderBox;
                      
                      // Convert global position to canvas local position
                      final localPosition = canvasBox.globalToLocal(details.offset);
                      
                      print('📍 Drop position:');
                      print('   Global: ${details.offset}');
                      print('   Local: $localPosition');
                      
                      // Canvas dimensions in pixels
                      final canvasWidth = _currentTemplate!.width * pxPerMm;
                      final canvasHeight = _currentTemplate!.height * pxPerMm;
                      
                      print('📐 Canvas size: ${canvasWidth}px × ${canvasHeight}px');
                      
                      // Calculate element position (with bounds checking)
                      // Offset untuk cursor berada di tengah element
                      final elementX = (localPosition.dx - 75).clamp(0.0, canvasWidth - 150);
                      final elementY = (localPosition.dy - 15).clamp(0.0, canvasHeight - 30);
                      
                      print('🎯 Element position: ($elementX, $elementY)');
                      
                      // Create new element
                      final newElement = LabelElement(
                        id: 'element_${DateTime.now().millisecondsSinceEpoch}',
                        variable: details.data.variable,
                        label: details.data.label,
                        x: elementX,
                        y: elementY,
                        width: 150,
                        height: 30,
                        fontSize: 12,
                        isManualInput: details.data.type == FieldType.manual,  // ✅ Auto-detect manual fields
                      );
                      
                      print('✅ New element created:');
                      print('   Variable: ${newElement.variable}');
                      print('   Position: (${newElement.x}, ${newElement.y})');
                      print('   Manual input: ${newElement.isManualInput}');
                      
                      setState(() {
                        _currentTemplate!.elements.add(newElement);
                        _selectedElement = newElement;
                        _updateControllers();
                      });
                      
                      print('═══════════════════════════════════════\n');
                      
                      _showSuccess('✅ ${details.data.label} ditambahkan!');
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isDraggingOver = candidateData.isNotEmpty;
                      
                      return Container(
                        width: _currentTemplate!.width * pxPerMm,
                        height: _currentTemplate!.height * pxPerMm,
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDraggingOver ? Colors.blue[50] : Colors.white,
                          border: isDraggingOver 
                              ? Border.all(color: Colors.blue, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Grid background
                            if (!_isPreviewMode)
                              CustomPaint(
                                size: Size(
                                  _currentTemplate!.width * pxPerMm,
                                  _currentTemplate!.height * pxPerMm,
                                ),
                                painter: GridPainter(),
                              ),

                            // Paper size label
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_currentTemplate!.width.toStringAsFixed(0)} × ${_currentTemplate!.height.toStringAsFixed(0)} mm',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            // ✅ Drop indicator saat dragging
                            if (isDraggingOver)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    border: Border.all(color: Colors.blue, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_circle, size: 48, color: Colors.blue),
                                      SizedBox(height: 8),
                                      Text(
                                        'Drop di sini untuk menambahkan',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Elements
                            ..._currentTemplate!.elements.map((element) {
  final isSelected = _selectedElement?.id == element.id;
  final displayValue = _getPreviewDisplayValue(element);

  // ✅ WRAPPER UNTUK MOVABLE ELEMENT
  Widget elementWidget = Container(
    width: element.width,
    height: element.height,
    decoration: BoxDecoration(
      border: Border.all(
        color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
      color: _isPreviewMode
          ? Colors.transparent
          : (isSelected
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05)),
    ),
    child: Stack(
      children: [
        // Content
        Padding(
          padding: const EdgeInsets.all(4),
          child: Align(
            alignment: _getAlignment(element.textAlign),
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: element.fontSize,
                fontWeight: element.fontWeight,
              ),
              textAlign: element.textAlign,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Delete button
        if (isSelected && !_isPreviewMode)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _deleteElement(element.id),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  // ✅ MAKE IT DRAGGABLE (hanya di edit mode)
  if (!_isPreviewMode) {
    elementWidget = Draggable<LabelElement>(
      data: element,
      feedback: Opacity(
        opacity: 0.7,
        child: Material(
          elevation: 4,
          child: Container(
            width: element.width,
            height: element.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              color: Colors.blue.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                displayValue,
                style: TextStyle(fontSize: element.fontSize),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: elementWidget,
      ),
      onDragEnd: (details) {
        // Calculate new position
        final RenderBox canvasBox = context.findRenderObject() as RenderBox;
        final localPosition = canvasBox.globalToLocal(details.offset);
        
        final canvasWidth = _currentTemplate!.width * pxPerMm;
        final canvasHeight = _currentTemplate!.height * pxPerMm;
        
        // Clamp position
        final newX = (localPosition.dx - element.width / 2).clamp(0.0, canvasWidth - element.width);
        final newY = (localPosition.dy - element.height / 2).clamp(0.0, canvasHeight - element.height);
        
        // Update element position
        setState(() {
          _updateElement(element.copyWith(x: newX, y: newY));
          _updateControllers();
        });
        
        print('📍 Element moved to: ($newX, $newY)');
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedElement = element;
            _updateControllers();
          });
        },
        child: elementWidget,
      ),
    );
  } else {
    // Preview mode: tidak bisa drag
    elementWidget = GestureDetector(
      onTap: null,
      child: elementWidget,
    );
  }

  return Positioned(
    left: element.x,
    top: element.y,
    child: elementWidget,
  );
}).toList(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildPropertiesPanel() {
    if (_selectedElement == null) return const SizedBox();

    final element = _selectedElement!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // ✅ NEW: Manual Input Section
        _buildSection('Position & Size (mm)', [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _xController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'X',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _yController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Y',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _widthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ]),

        // ✅ NEW: Size Presets
        _buildSection('Quick Size Presets', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetButton('Small', 'small'),
              _buildPresetButton('Normal', 'normal'),
              _buildPresetButton('Medium', 'medium'),
              _buildPresetButton('Large', 'large'),
              _buildPresetButton('XLarge', 'xlarge'),
            ],
          ),
        ]),

        // Text Settings
        _buildSection('Text', [
          TextField(
            controller: _fontSizeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Font Size (pt)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Weight: '),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [
                  element.fontWeight == FontWeight.normal,
                  element.fontWeight == FontWeight.bold,
                ],
                onPressed: (index) {
                  _updateElement(element.copyWith(
                    fontWeight: index == 0 ? FontWeight.normal : FontWeight.bold,
                  ));
                  _updateControllers();
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Normal'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Bold'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Align: '),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [
                  element.textAlign == TextAlign.left,
                  element.textAlign == TextAlign.center,
                  element.textAlign == TextAlign.right,
                ],
                
                onPressed: (index) {
                  final aligns = [TextAlign.left, TextAlign.center, TextAlign.right];
                  _updateElement(element.copyWith(textAlign: aligns[index]));
                  _updateControllers();
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.format_align_left, size: 18),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.format_align_center, size: 18),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.format_align_right, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
CheckboxListTile(
  title: const Text('Tampilkan Label Prefix'),
  subtitle: const Text('ON: "Operator: Dimas" | OFF: "Dimas"'),
  value: element.showLabel ?? true,
  onChanged: (value) {
    setState(() {
      _updateElement(element.copyWith(showLabel: value));
      _updateControllers();
    });
  },
  dense: true,
  contentPadding: EdgeInsets.zero,
),

        ]),

        // ✅ NEW: Apply Changes Button
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _applyManualChanges,
            icon: const Icon(Icons.check),
            label: const Text('Apply Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _deleteElement(element.id),
            icon: const Icon(Icons.delete),
            label: const Text('Delete Element'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  // ✅ TAMBAHKAN METHOD INI DI SINI
  Widget _buildPresetButton(String label, String preset) {
    return OutlinedButton(
      onPressed: () => _applySizePreset(preset),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Alignment _getAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}

// ============================================================================
// Grid Painter
// ============================================================================

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    const gridSize = 10.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// Manual Fields Editor Dialog
// ============================================================================

class ManualFieldsEditorDialog extends StatelessWidget {
  final LabelTemplate template;
  final List<LabelElement> manualFields;

  const ManualFieldsEditorDialog({
    Key? key,
    required this.template,
    required this.manualFields,
  }) : super(key: key);

  String _getFieldLabel(String variable) {
    final field = LabelFields.allFields.firstWhere(
      (f) => f.variable == variable,
      orElse: () => AvailableField(
        variable: variable,
        label: variable,
        category: 'Lainnya',
        icon: Icons.text_fields,
      ),
    );
    return field.label;
  }

  IconData _getFieldIcon(String variable) {
    final field = LabelFields.allFields.firstWhere(
      (f) => f.variable == variable,
      orElse: () => AvailableField(
        variable: variable,
        label: variable,
        category: 'Lainnya',
        icon: Icons.text_fields,
      ),
    );
    return field.icon;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual Input Fields',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Field yang perlu diisi manual saat print',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // List of manual fields
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Field ini akan muncul sebagai form input saat user klik tombol "Simpan" di halaman timbangan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Field list
                  ...manualFields.map((element) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: Icon(
                            _getFieldIcon(element.variable),
                            color: Colors.blue[700],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _getFieldLabel(element.variable),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Variable: ${element.variable}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'MANUAL INPUT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total: ${manualFields.length} field manual',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('OK, Mengerti'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}