import 'package:flutter/material.dart';
import 'dart:math';
import '../models/label_template_model.dart';

class LabelPrintService {

  static String _getUnitAbbreviation(String unit) {
    switch (unit.toUpperCase()) {
      case 'GRAM':
        return 'g';
      case 'KG':
        return 'kg';
      case 'ONS':
        return 'ons';
      case 'POUND':
        return 'lb';
      case 'MG':
        return 'mg';
      default:
        return unit.toLowerCase();
    }
  }
  
  // ============================================================================
  // MAIN RENDER FUNCTION - AUTO DETECT PRINTER TYPE
  // ============================================================================
  
  static String renderTemplateToText(
    LabelTemplate template,
    Map<String, dynamic> data,
  ) {
    String printerType = (template.printerType ?? 'ESCPOS').toUpperCase().trim();
    
    bool isTSCPrinter = printerType.contains('TSC') || 
                        printerType.contains('TSPL') ||
                        printerType.contains('LABEL');
    
    print('\n🖨️ ═══════════════════════════════════════════════════');
    print('   PRINTER DETECTION');
    print('   Template: ${template.name}');
    print('   Printer Type: ${template.printerType}');
    print('   Detected as: ${isTSCPrinter ? "TSC" : "ESC/POS"}');
    print('═══════════════════════════════════════════════════\n');
    
    if (isTSCPrinter) {
      return _generateTSPLFromTemplate(template, data);
    } else {
      return _renderESCPOSIsolated(template, data);
    }
  }

  static String renderTemplateToESCPOS(
    LabelTemplate template,
    Map<String, dynamic> data,
  ) {
    print('📄 Generating ESC/POS from template...');
    return _renderESCPOSIsolated(template, data);
  }

  // ============================================================================
  // ✅ FIXED: ESC/POS GENERATOR
  // ============================================================================
  
  static String _renderESCPOSIsolated(
    LabelTemplate template,
    Map<String, dynamic> data,
  ) {
    print('🧾 Generating ESC/POS (FIXED Version)...');
    
    final buffer = StringBuffer();
    
    const String ESC = '\x1B';
    const String GS = '\x1D';
    const String INIT = '$ESC@';
    const String CENTER = '$ESC\x61\x01';
    const String LEFT = '$ESC\x61\x00';
    const String RIGHT = '$ESC\x61\x02';
    const String BOLD_ON = '$ESC\x45\x01';
    const String BOLD_OFF = '$ESC\x45\x00';
    const String CUT_PAPER = '$GS\x56\x00';
    const String LINE_FEED = '\n';
    
    buffer.write(INIT);
    
    // ✅ FIX: Filter visible elements only
    final visibleElements = template.elements.where((e) => e.isVisible).toList();
    print('📊 Total elements: ${template.elements.length}, Visible: ${visibleElements.length}');
    
    final sortedElements = List<LabelElement>.from(visibleElements)
      ..sort((a, b) => a.y.compareTo(b.y));
    
    // ✅ FIX: Improved row grouping with 20px threshold
    final rows = <List<LabelElement>>[];
    for (var element in sortedElements) {
      bool added = false;
      
      // ✅ CRITICAL FIX: Increased threshold dari 10 → 20
      for (var row in rows) {
        if (row.isNotEmpty && (element.y - row.first.y).abs() < 20) {
          row.add(element);
          added = true;
          break; // ✅ EXIT setelah ditambahkan!
        }
      }
      
      if (!added) {
        rows.add([element]);
      }
    }
    
    print('📋 Grouped into ${rows.length} rows');
    
    // ✅ Track rendered elements
    int renderedCount = 0;
    Set<String> renderedVariables = {};
    
    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      var row = rows[rowIndex];
      row.sort((a, b) => a.x.compareTo(b.x));
      
      print('  Row $rowIndex: ${row.length} elements');
      
      if (row.length == 1) {
        // ===== SINGLE ELEMENT ROW =====
        final element = row.first;
        var text = _formatElementWithLabel(element, data);
        
        // ✅ FIX: Show placeholder instead of skipping empty
        if (text.trim().isEmpty) {
          text = '[${element.label}]'; // Placeholder
          print('    ⚠️ Empty value for ${element.variable}, using placeholder');
        }
        
        // Handle separator line
        if (element.variable == 'GARIS_PEMISAH' || 
            text.contains('===') || 
            text.contains('---')) {
          
          int maxChars = 32;
          
          if (template.width >= 80) {
            maxChars = 42;
          } else if (template.width >= 72) {
            maxChars = 38;
          }
          
          if (text.contains('===')) {
            text = '=' * maxChars;
          } else if (text.contains('---')) {
            text = '-' * maxChars;
          }
        }
        
        // Set alignment
        if (element.textAlign == TextAlign.center) {
          buffer.write(CENTER);
        } else if (element.textAlign == TextAlign.right) {
          buffer.write(RIGHT);
        } else {
          buffer.write(LEFT);
        }
        
        // Set bold
        if (element.fontWeight == FontWeight.bold) {
          buffer.write(BOLD_ON);
        }
        
        // Set size
        buffer.write(_getESCPOSSize(element.fontSize));
        buffer.write(text);
        buffer.write(LINE_FEED);
        buffer.write(BOLD_OFF);
        buffer.write('$GS\x21\x00');
        
        renderedCount++;
        renderedVariables.add(element.variable);
        print('    ✅ Rendered: ${element.variable} = "$text"');
        
      } else {
        // ===== MULTIPLE ELEMENTS IN ONE ROW =====
        buffer.write(LEFT);
        
        bool hasBold = row.any((e) => e.fontWeight == FontWeight.bold);
        if (hasBold) buffer.write(BOLD_ON);
        
        final line = StringBuffer();
        for (int i = 0; i < row.length; i++) {
          final element = row[i];
          var text = _formatElementWithLabel(element, data);
          
          // ✅ FIX: Show placeholder untuk empty values
          if (text.trim().isEmpty) {
            text = '[${element.label}]';
          }
          
          if (text.trim().isNotEmpty) {
            line.write(text);
            
            if (i < row.length - 1) {
              final nextElement = row[i + 1];
              final spacing = ((nextElement.x - (element.x + element.width)) / 5).round();
              line.write(' ' * (spacing > 0 ? spacing : 1));
            }
            
            renderedCount++;
            renderedVariables.add(element.variable);
            print('    ✅ Rendered: ${element.variable} = "$text"');
          }
        }
        
        buffer.write(line.toString());
        buffer.write(LINE_FEED);
        
        if (hasBold) buffer.write(BOLD_OFF);
      }
    }
    
    // ✅ Final summary
    print('\n📊 ESC/POS Rendering Summary:');
    print('   Total elements: ${visibleElements.length}');
    print('   Rendered: $renderedCount');
    print('   Missing: ${visibleElements.length - renderedCount}');
    
    if (renderedCount < visibleElements.length) {
      final missing = visibleElements
          .where((e) => !renderedVariables.contains(e.variable))
          .map((e) => e.variable)
          .toList();
      print('   ⚠️ Not rendered: ${missing.join(", ")}');
    }
    
    buffer.write(LINE_FEED);
    buffer.write(LINE_FEED);
    buffer.write(LINE_FEED);
    buffer.write(CUT_PAPER);
    
    print('✅ ESC/POS generation complete\n');
    
    return buffer.toString();
  }

  // ============================================================================
  // ✅ FIXED: TSPL GENERATOR WITH DEDUPLICATION
  // ============================================================================
  
  static String _generateTSPLFromTemplate(
  LabelTemplate template,
  Map<String, dynamic> data,
) {
  StringBuffer tspl = StringBuffer();
  
  print('🔍 ═══════════════════════════════════════════════════');
  print('📄 TSPL Generation with Deduplication');
  print('   Template: ${template.name}');
  print('   Paper: ${template.width}x${template.height}mm');
  print('═══════════════════════════════════════════════════');

  // Printer setup
  double labelWidth = template.width;
  double labelHeight = template.height;
  
  // ✅ CRITICAL FIX #1: SIZE command
  tspl.writeln('SIZE $labelWidth mm, $labelHeight mm');
  
  // ✅ CRITICAL FIX #2: GAP setting yang benar
  // GAP harus >= 3mm untuk deteksi yang reliable
  // Format: GAP gap_height, gap_offset
  tspl.writeln('GAP 3 mm, 0 mm');
  
  // ✅ CRITICAL FIX #3: Set sensor type (optional tapi recommended)
  // Uncomment salah satu sesuai tipe label:
  // tspl.writeln('BLINE 3 mm, 0 mm');  // ← Untuk black mark label
  // tspl.writeln('GAP 3 mm, 0 mm');     // ← Untuk gap label (default, sudah ada di atas)
  
  // ✅ CRITICAL FIX #4: Density & Speed
  tspl.writeln('DENSITY 8');   // Darkness: 0-15 (8 = medium)
  tspl.writeln('SPEED 4');     // Speed: 1-6 (4 = medium, lebih stabil dari 3)
  
  // ✅ CRITICAL FIX #5: Direction & Offset
  tspl.writeln('DIRECTION 0');       // Print direction
  tspl.writeln('REFERENCE 0, 0');    // Reference point
  tspl.writeln('OFFSET 0 mm');       // Horizontal offset
  
  // ✅ CRITICAL FIX #6: Clear buffer SEBELUM render
  tspl.writeln('CLS');
  
  print('✅ Printer setup:');
  print('   SIZE: $labelWidth x $labelHeight mm');
  print('   GAP: 3mm (reliable detection)');
  print('   DENSITY: 8, SPEED: 4');
  
  final double dotsPerMm = detectDotsPerMm(template);
  const double pxPerMm = 3.78;
  
  // ✅ FIX #1: Filter visible elements
  final activeElements = template.elements
      .where((e) => e.isVisible == true)
      .toList();
  
  print('\n📊 Element Stats:');
  print('   Total in template: ${template.elements.length}');
  print('   Visible: ${activeElements.length}');
  
  if (activeElements.isEmpty) {
    print('\n❌ ERROR: No visible elements in template!');
    return tspl.toString();
  }

  // ✅ FIX #2: DEDUPLICATE ELEMENTS BY VARIABLE
  // Jika ada 2+ element dengan variable sama, ambil yang terakhir saja
  print('\n🧹 Deduplicating elements by variable...');
  
  final Map<String, LabelElement> uniqueElements = {};
  for (var element in activeElements) {
    final key = element.variable.toUpperCase();
    
    if (uniqueElements.containsKey(key)) {
      print('   ⚠️ Duplicate found: $key - Keeping latest');
    }
    
    uniqueElements[key] = element; // Last one wins
  }
  
  final deduplicatedElements = uniqueElements.values.toList();
  
  print('✅ Deduplication complete:');
  print('   Before: ${activeElements.length} elements');
  print('   After: ${deduplicatedElements.length} elements');
  print('   Removed: ${activeElements.length - deduplicatedElements.length} duplicates');

  // Sort by Y position
  final sortedElements = List<LabelElement>.from(deduplicatedElements)
    ..sort((a, b) => a.y.compareTo(b.y));

  // ✅ RENDER WITH DEDUPLICATION
  int currentY = 30;
  const int lineSpacing = 22;
  int renderedCount = 0;

  print('\n🎨 Rendering Elements:');
  print('─' * 60);

  // ✅ FIX #3: Track rendered variables untuk detect double-render
  Set<String> renderedVariables = {};

  for (var element in sortedElements) {
    String variableUpper = element.variable.toUpperCase();
    
    // ✅ FIX #4: Skip jika variable ini sudah di-render
    if (renderedVariables.contains(variableUpper)) {
      print('\n⚠️ SKIPPED: $variableUpper (already rendered)');
      continue;
    }
    
    // Convert X
    double xMm = element.x / pxPerMm;
    int xDots = (xMm * dotsPerMm).round();
    int yDots = currentY;
    
    print('\n[$renderedCount] ${element.variable}');
    print('   Label: "${element.label}"');
    print('   Position: X=$xDots, Y=$yDots');

    // ✅ CHECK 1: Separator line
    if (_isSeparatorLine(variableUpper, element.label)) {
      double widthMm = element.width / pxPerMm;
      int widthDots = (widthMm * dotsPerMm).round();
      tspl.writeln('BAR $xDots,$yDots,$widthDots,2');
      print('   Type: SEPARATOR LINE');
      renderedCount++;
      renderedVariables.add(variableUpper); // ✅ Mark as rendered
      currentY += lineSpacing;
      continue;
    }

    // ✅ CHECK 2: QR Code
    if (_isQRCode(variableUpper)) {
      String qrData = _getValueForElement(element, data);
      print('   Type: QR CODE');
      print('   Data: "${qrData}"');
      
      if (qrData.trim().isNotEmpty) {
        int cellSize = 4;
        tspl.writeln('QRCODE $xDots,$yDots,H,$cellSize,A,0,"$qrData"');
        print('   Command: QRCODE');
        renderedCount++;
        renderedVariables.add(variableUpper); // ✅ Mark as rendered
      }
      currentY += lineSpacing * 2;
      continue;
    }

    // ✅ CHECK 3: Barcode
    if (_isBarcode(variableUpper)) {
      String barcodeData = _getValueForElement(element, data);
      print('   Type: BARCODE');
      
      if (barcodeData.trim().isNotEmpty) {
        String sanitized = barcodeData.replaceAll(RegExp(r'[^0-9A-Za-z\-\.\s]'), '');
        if (sanitized.isNotEmpty) {
          tspl.writeln('BARCODE $xDots,$yDots,"128",60,1,0,2,4,"$sanitized"');
          renderedCount++;
          renderedVariables.add(variableUpper); // ✅ Mark as rendered
        }
      }
      currentY += lineSpacing * 2;
      continue;
    }

    // ✅ CHECK 4: Text
    String formattedText = _formatElementWithLabel(element, data);
    
    print('   Type: TEXT');
    print('   Formatted: "$formattedText"');
    
    // Static fields
    final staticVars = ['HEADER', 'FOOTER', 'NAMA_PERUSAHAAN', 'ALAMAT', 'TELEPON'];
    bool isStatic = staticVars.contains(variableUpper);
    
    if (formattedText.trim().isEmpty && !isStatic) {
      print('   ⚠️ SKIPPED - No data');
      currentY += lineSpacing;
      continue;
    }
    
    // Force static text
    if (variableUpper == 'NAMA_PERUSAHAAN' && formattedText.trim().isEmpty) {
      formattedText = 'PT TRISURYA SOLUSINDO UTAMA';
    }
    if (variableUpper == 'FOOTER' && formattedText.trim().isEmpty) {
      formattedText = 'info@trisuryasolusindo.com';
    }

    if (formattedText.trim().isEmpty) {
      print('   ⚠️ SKIPPED - Still empty');
      currentY += lineSpacing;
      continue;
    }

    String escapedText = formattedText.replaceAll('"', '\\"');
    String font = element.fontSize >= 14 ? "3" : "2";
    
    tspl.writeln('TEXT $xDots,$yDots,"$font",0,1,1,"$escapedText"');
    print('   Command: TEXT');
    print('   Output: "$escapedText"');
    
    renderedCount++;
    renderedVariables.add(variableUpper); // ✅ Mark as rendered
    currentY += lineSpacing;
  }

  tspl.writeln('PRINT 1');  // ← Cuma 1 parameter = print 1 label saja!

print('─' * 60);
print('\n📊 Final Summary:');
print('   Template elements: ${template.elements.length}');
print('   Visible elements: ${activeElements.length}');
print('   After deduplication: ${deduplicatedElements.length}');
print('   Actually rendered: $renderedCount');
print('   Duplicates removed: ${activeElements.length - deduplicatedElements.length}');

// ✅ OPTIONAL: Tambahkan command EOJ (End of Job) untuk lebih eksplisit
// Ini memberitahu printer bahwa job sudah selesai
// tspl.writeln('EOJ');  // ← Uncomment jika masih double print

if (currentY > (labelHeight * dotsPerMm)) {
  print('\n❌ WARNING: Label content EXCEEDS label height!');
} else {
  print('\n✅ Label content fits within bounds.');
}

print('═══════════════════════════════════════════════════\n');

final validatedTspl = _validateTSPL(tspl.toString());
return validatedTspl;
}

// ============================================================================
// ✅ FIXED: STATISTICAL WEIGHING - WEIGHT ONLY RENDER (SPACING FIXED)
// ============================================================================

/// Render WEIGHT ONLY for statistical weighing (no header)
/// Used for subsequent weighings after first weighing in statistical session
static String renderWeightOnly(
    LabelTemplate template, 
    Map<String, dynamic> data,
    {int? decimalPlaces}
  ) {
    print('\n🔍 ═══════════════════════════════════════════════════');
    print('📄 Statistical Weighing - WEIGHT ONLY Mode');
    print('   Template: ${template.name}');
    print('   Decimal Places: ${decimalPlaces ?? "auto-detect"}');
    
    // ✅ NEW: Check printer type from template
    String printerType = (template.printerType ?? 'ESCPOS').toUpperCase().trim();
    bool isTSPL = printerType.contains('TSC') || 
                  printerType.contains('TSPL') ||
                  printerType.contains('LABEL');
    
    print('   Template Printer Type: $printerType');
    print('   Detected as: ${isTSPL ? "TSPL (Label)" : "ESC/POS (Receipt)"}');
    print('═══════════════════════════════════════════════════════\n');
    
    // ✅ NEW: Route to correct renderer
    if (!isTSPL) {
      // ESC/POS printer - use receipt format
      return renderWeightOnlyESCPOS(template, data, decimalPlaces: decimalPlaces);
    }
    
    // Extract weight info from data
    String weightStr = data['BERAT']?.toString() ?? '0.0';
    String unit = data['UNIT']?.toString() ?? 'kg';
    
    // ✅ FIX: Determine decimal places
    int decimals;
    if (decimalPlaces != null) {
      decimals = decimalPlaces;
      print('   Using provided decimal places: $decimals');
    } else {
      // Auto-detect from weight string
      if (weightStr.contains('.')) {
        String decimalPart = weightStr.split('.')[1];
decimals = decimalPart.replaceAll(RegExp(r'0+$'), '').length;
      } else {
        decimals = 0;
      }
      print('   Auto-detected decimal places: $decimals');
    }
    
    // ✅ FIX: Format weight consistently
    double weight = double.tryParse(weightStr) ?? 0.0;
    String formattedWeight = weight.toStringAsFixed(decimals);
    
    String? quantity = data['QUANTITY']?.toString();
    bool hasQuantity = quantity != null && quantity != '-' && quantity.isNotEmpty;
    
    print('📊 Weight Data:');
    print('   Weight: $formattedWeight $unit (${decimals}dp)');
    if (hasQuantity) {
      print('   Quantity: $quantity');
    }
    
    StringBuffer tspl = StringBuffer();
    
    double labelWidth = template.width;
    
    // ✅ FIX #1: REDUCED HEIGHT - sesuaikan dengan konten (hanya berat)
    double labelHeight = hasQuantity ? 20.0 : 15.0;  // ✅ FIXED: Reduced from 30mm
    
    print('📏 Label Dimensions:');
    print('   Width: $labelWidth mm');
    print('   Height: $labelHeight mm (reduced for weight-only)');
    
    // ✅ TSPL Header
    tspl.writeln('SIZE $labelWidth mm, $labelHeight mm');
    tspl.writeln('GAP 3 mm, 0 mm');
    tspl.writeln('DIRECTION 0');
    tspl.writeln('REFERENCE 0,0');
    tspl.writeln('OFFSET 0 mm');
    tspl.writeln('DENSITY 8');
    tspl.writeln('SPEED 4');
    tspl.writeln('CLS');
    
    final double dotsPerMm = detectDotsPerMm(template);
    int centerX = ((labelWidth / 2) * dotsPerMm).round();
    
    // ✅ FIX #2: REDUCED Y POSITION - lebih atas untuk mengurangi spacing
    int centerY = 30;  // ✅ FIXED: Reduced from 60
    
    print('🎯 Positioning:');
    print('   DPI: ${dotsPerMm * 25.4} (${dotsPerMm} dots/mm)');
    print('   Center X: $centerX dots');
    print('   Center Y: $centerY dots (reduced for tighter spacing)');
    
    // ✅ RENDER WEIGHT with consistent formatting
    String weightText = '$formattedWeight $unit';
    
    if (hasQuantity) {
      tspl.writeln('TEXT $centerX,$centerY,"3",0,2,2,"$weightText"');
      
      int quantityY = centerY + 40;  // ✅ FIXED: Reduced spacing dari 50
      tspl.writeln('TEXT $centerX,$quantityY,"3",0,1,1,"$quantity"');
      
      print('📝 Content:');
      print('   Line 1: $weightText (2x2 font)');
      print('   Line 2: $quantity (1x1 font)');
    } else {
      tspl.writeln('TEXT $centerX,$centerY,"3",0,2,2,"$weightText"');
      
      print('📝 Content:');
      print('   Weight: $weightText (2x2 font, ${decimals}dp)');
    }
    
    tspl.writeln('PRINT 1,1');
    
    print('✅ Weight-only TSPL generated successfully');
    print('   Spacing optimized for statistical mode');
    print('═══════════════════════════════════════════════════════\n');
    
    return tspl.toString();
  }

// ============================================================================
// ✅ FIXED: ESC/POS STATISTICAL WEIGHING - WEIGHT ONLY RENDER
// ============================================================================

/// Render WEIGHT ONLY for ESC/POS printer (statistical mode)
static String renderWeightOnlyESCPOS(
    LabelTemplate template, 
    Map<String, dynamic> data,
    {int? decimalPlaces}
  ) {
    print('\n🔍 ═══════════════════════════════════════════════════');
    print('📄 Statistical Subsequent Weighing - "N:" ONLY');
    print('═══════════════════════════════════════════════════════\n');
    
    final buffer = StringBuffer();
    
    const String ESC = '\x1B';
    const String GS = '\x1D';
    const String INIT = '$ESC@';
    const String LEFT = '$ESC\x61\x00';
    const String CUT_PAPER = '$GS\x56\x00';
    const String LINE_FEED = '\n';
    
    buffer.write(INIT);
    buffer.write(LEFT);
    
    // Extract & format weight
    String weightStr = data['BERAT']?.toString() ?? '0.0';
    String unit = data['UNIT']?.toString() ?? 'kg';
    
    // Determine decimal places
    int decimals;
    if (decimalPlaces != null) {
      decimals = decimalPlaces;
    } else {
      if (weightStr.contains('.')) {
        String decimalPart = weightStr.split('.')[1];
decimals = decimalPart.replaceAll(RegExp(r'0+$'), '').length;
      } else {
        decimals = 0;
      }
    }
    
    // Format weight consistently
    double weight = double.tryParse(weightStr) ?? 0.0;
    String formattedWeight = weight.toStringAsFixed(decimals);
    
    String? quantity = data['QUANTITY']?.toString();
    bool hasQuantity = quantity != null && quantity != '-' && quantity.isNotEmpty;
    
    // GET COUNTER NUMBER
    int counterNumber = data['COUNTER_NUMBER'] ?? 2;
    
    print('📊 Weight Data:');
    print('   Counter: $counterNumber');
    print('   Weight: $formattedWeight $unit');
    
    // ═══════════════════════════════════════════════════════
    // ✅ FORMAT: "N: X.XX KG" (simple, no "Counter" text)
    // ═══════════════════════════════════════════════════════
    buffer.write('$counterNumber: $formattedWeight $unit');
    buffer.write(LINE_FEED);
    
    // ✅ QUANTITY (if counting mode)
    if (hasQuantity) {
      buffer.write('   $quantity');  // 3 spaces indent
      buffer.write(LINE_FEED);
    }
    
    buffer.write(CUT_PAPER);
    
    print('✅ Subsequent weighing generated');
    print('   Format: "$counterNumber: $formattedWeight $unit"');
    print('═══════════════════════════════════════════════════════\n');
    
    return buffer.toString();
  }

  static String generateStatisticalFirstWeighing({
    required LabelTemplate template,
    required Map<String, String> activeFields,
    required String weight,
    required String unit,
    int? quantity,
    double? unitWeight,
    int? decimalPlaces,
    required int counterNumber,
  }) {
    print('\n🔍 ═══════════════════════════════════════════════════');
    print('📄 Statistical First Weighing - HEADER + "1."');
    print('   Weight: $weight $unit');
    print('   Counter: $counterNumber');
    print('   Decimal Places: ${decimalPlaces ?? "auto"}');
    print('═══════════════════════════════════════════════════\n');
    
    final buffer = StringBuffer();
    
    const String ESC = '\x1B';
    const String GS = '\x1D';
    const String INIT = '$ESC@';
    const String CENTER = '$ESC\x61\x01';
    const String LEFT = '$ESC\x61\x00';
    const String BOLD_ON = '$ESC\x45\x01';
    const String BOLD_OFF = '$ESC\x45\x00';
    const String LINE_FEED = '\n';
    
    // Initialize
    buffer.write(INIT);
    buffer.write(CENTER);
    
    // ═══════════════════════════════════════════════════════
    // ✅ HEADER: T-CONNECT
    // ═══════════════════════════════════════════════════════
    buffer.write(BOLD_ON);
    buffer.write('$GS\x21\x11');  // 2x2 size
    buffer.write('T-CONNECT');
    buffer.write(LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write('$GS\x21\x00');  // Reset size
    
    buffer.write('================================');
    buffer.write(LINE_FEED);
    
    // ═══════════════════════════════════════════════════════
    // ✅ TIMESTAMP
    // ═══════════════════════════════════════════════════════
    buffer.write(LEFT);
    String timestamp = DateTime.now().toString().substring(0, 19);
    buffer.write('Time    : $timestamp');
    buffer.write(LINE_FEED);
    
    // ═══════════════════════════════════════════════════════
    // ✅ ACTIVE FIELDS (13 char padding untuk rata kiri)
    // ═══════════════════════════════════════════════════════
    activeFields.forEach((label, value) {
      // Padding label ke 13 karakter untuk alignment
      String paddedLabel = label.padRight(13);
      buffer.write('$paddedLabel: $value');
      buffer.write(LINE_FEED);
    });
    
    buffer.write('================================');
    buffer.write(LINE_FEED);
    
    // ═══════════════════════════════════════════════════════
// ✅ FIX: COUNTER FORMAT "1. X g" (ikut decimal places dari raw data)
// ═══════════════════════════════════════════════════════

// ✅ CRITICAL: Auto-detect decimals from raw weight string
int decimals;  // ← TAMBAHKAN DEKLARASI INI!
if (decimalPlaces != null) {
  // Use provided decimal places
  decimals = decimalPlaces;
  print('   Using provided decimal places: $decimals');
} else {
  // Auto-detect from raw weight string
  if (weight.contains('.')) {
    String decimalPart = weight.split('.')[1];
    // Remove trailing zeros untuk dapat exact decimals
    decimals = decimalPart.replaceAll(RegExp(r'0+$'), '').length;
    if (decimals == 0) decimals = 0; // Jika semua nol, no decimals
  } else {
    decimals = 0; // Integer, no decimals
  }
  print('   Auto-detected decimal places: $decimals (from "$weight")');
}

// Format weight dengan exact decimals
double weightValue = double.tryParse(weight) ?? 0.0;
String formattedWeight = weightValue.toStringAsFixed(decimals);

// ✅ Convert unit ke abbreviation (g, kg, lb, dll)
String unitAbbr = _getUnitAbbreviation(unit);

// ✅ FORMAT: "1. 1000 g" atau "1. 1000.5 g" (sesuai raw data)
buffer.write('$counterNumber. $formattedWeight $unitAbbr');
buffer.write(LINE_FEED);

// ✅ QUANTITY (jika counting mode)
if (quantity != null && quantity > 0) {
  buffer.write('   $quantity pcs');  // 3 spaces indent
  buffer.write(LINE_FEED);
}

print('✅ Statistical first weighing generated');
print('   Format: "$counterNumber. $formattedWeight $unitAbbr"');
print('   Decimals: $decimals (from raw data)');
print('═══════════════════════════════════════════════════\n');

return buffer.toString();
  }

// ============================================================================
// ✅ FIXED: STATISTICAL SUMMARY GENERATOR
// ============================================================================

static String renderStatisticalSummary(
      LabelTemplate template,
      List<double> weights,
      {
        String? operatorName, 
        String? productName,
        String? unit,
        int? decimalPlaces,
      }
    ) {
      print('\n🔍 ═══════════════════════════════════════════════════');
      print('📊 Statistical Summary Generation');
      print('   Weights count: ${weights.length}');
      print('   Unit: ${unit ?? "kg (default)"}');
      print('   Decimal Places: ${decimalPlaces ?? "3 (default)"}');
      print('═══════════════════════════════════════════════════\n');
      
      if (weights.isEmpty) {
        print('⚠️ No weights to summarize');
        return '';
      }
      
      // ✅ FIX: Ensure all weights are in the SAME UNIT before calculations
      // weights should already be in kg from session tracking
      
      int count = weights.length;
      double sum = weights.reduce((a, b) => a + b);
      double average = sum / count;
      double max = weights.reduce((a, b) => a > b ? a : b);
      double min = weights.reduce((a, b) => a < b ? a : b);
      double diff = max - min;

      double variance = 0.0;
      for (var weight in weights) {
        variance += (weight - average) * (weight - average);
      }
      variance = variance / count;
      double stdDev = sqrt(variance);

      // ✅ Use unit & decimal from session
      String displayUnit = unit ?? 'kg';
      int displayDecimals = decimalPlaces ?? 3;
      double stdDevPercent = average > 0 ? (stdDev / average) * 100 : 0;

      // ✅ Convert displayUnit to abbreviation for consistency
      String unitAbbr = _getUnitAbbreviation(displayUnit);

      print('📈 Statistics (Session Format):');
      print('   Unit: $unitAbbr');
      print('   Decimals: $displayDecimals');
      print('   Count: $count');
      print('   Sum: ${sum.toStringAsFixed(displayDecimals)} $unitAbbr');
      print('   Average: ${average.toStringAsFixed(displayDecimals)} $unitAbbr');
      print('   Max: ${max.toStringAsFixed(displayDecimals)} $unitAbbr');
      print('   Min: ${min.toStringAsFixed(displayDecimals)} $unitAbbr');
      print('   Diff: ${diff.toStringAsFixed(displayDecimals)} $unitAbbr');
      print('   Std Dev: ${stdDevPercent.toStringAsFixed(2)}% (${stdDev.toStringAsFixed(displayDecimals)} $unitAbbr)');
      
      // ✅ CRITICAL FIX: FORCE ESC/POS for Statistical Summary
      print('\n🔍 Printer Detection for Summary:');
      print('   ⚠️ STATISTICAL MODE: Forcing ESC/POS (receipt printer)');
      print('   Reason: Statistical summaries require text-based formatting');
      
      // ✅ ALWAYS use ESC/POS for statistical summary (FIXED ROUTING)
      return _generateESCPOSSummary(
        count, sum, average, max, min, diff, stdDev,
        operatorName: operatorName, 
        productName: productName,
        unit: unitAbbr,  // ✅ Pass abbreviated unit
        decimalPlaces: displayDecimals,
      );
    }

// ============================================================================
// ✅ FIXED: TSPL STATISTICAL SUMMARY
// ============================================================================

static String _generateTSPLSummary(
    LabelTemplate template,
    int count,
    double sum,
    double average,
    double max,
    double min,
    double diff,
    double stdDev,
    {
      String? operatorName, 
      String? productName,
      String? unit,
      int? decimalPlaces,
    }
  ) {
    print('📄 Generating TSPL Statistical Summary...');
    
    StringBuffer tspl = StringBuffer();
    
    double labelWidth = template.width;
    double labelHeight = 80.0;  // ✅ FIXED: Reduced from 100mm
    
    String displayUnit = unit ?? 'kg';
    int displayDecimals = decimalPlaces ?? 3;
    double stdDevPercent = average > 0 ? (stdDev / average) * 100 : 0;
    
    print('📊 Summary Settings:');
    print('   Unit: $displayUnit');
    print('   Decimals: $displayDecimals');
    print('   Std Dev %: ${stdDevPercent.toStringAsFixed(2)}%');
    
    // ✅ CRITICAL FIX: Proper TSPL header setup
    tspl.writeln('SIZE $labelWidth mm, $labelHeight mm');
    tspl.writeln('GAP 3 mm, 0 mm');
    tspl.writeln('DENSITY 8');
    tspl.writeln('SPEED 4');
    tspl.writeln('DIRECTION 0');
    tspl.writeln('REFERENCE 0,0');
    tspl.writeln('OFFSET 0 mm');
    tspl.writeln('CLS');
    
    final double dotsPerMm = detectDotsPerMm(template);
    int leftMargin = 20;
    int yPos = 20;  // ✅ FIXED: Reduced from 30
    int lineHeight = 25;  // ✅ FIXED: Reduced from 30
    
    // ✅ Header
    int centerX = ((labelWidth / 2) * dotsPerMm).round();
    tspl.writeln('TEXT $centerX,$yPos,"4",0,2,2,"STATISTICS"');
    yPos += 50;  // ✅ FIXED: Reduced from 60
    
    // ✅ Separator line
    int lineWidth = ((labelWidth - 10) * dotsPerMm).round();
    tspl.writeln('BAR $leftMargin,$yPos,$lineWidth,2');
    yPos += 15;
    
    // ✅ Statistics data with consistent formatting
    tspl.writeln('TEXT $leftMargin,$yPos,"3",0,1,1,"Count    : $count"');
    yPos += lineHeight;
    
    tspl.writeln('TEXT $leftMargin,$yPos,"3",0,1,1,"Sum      : ${sum.toStringAsFixed(displayDecimals)} $displayUnit"');
    yPos += lineHeight;
    
    tspl.writeln('TEXT $leftMargin,$yPos,"3",0,1,1,"Average  : ${average.toStringAsFixed(displayDecimals)} $displayUnit"');
    yPos += lineHeight;
    
    tspl.writeln('TEXT $leftMargin,$yPos,"3",0,1,1,"Max      : ${max.toStringAsFixed(displayDecimals)} $displayUnit"');
    yPos += lineHeight;
    
    tspl.writeln('TEXT $leftMargin,$yPos,"3",0,1,1,"Min      : ${min.toStringAsFixed(displayDecimals)} $displayUnit"');
    yPos += lineHeight;
    
    tspl.writeln('TEXT $leftMargin,$yPos,"3",0,1,1,"Diff     : ${diff.toStringAsFixed(displayDecimals)} $displayUnit"');
    yPos += lineHeight;

    tspl.writeln('TEXT $leftMargin,$yPos,"3",0,1,1,"Std Dev  : ${stdDevPercent.toStringAsFixed(2)}%"');
    yPos += lineHeight;
    
    // ✅ Footer separator
    tspl.writeln('BAR $leftMargin,$yPos,$lineWidth,2');
    yPos += 15;
    
    // ✅ Timestamp
    DateTime now = DateTime.now();
    String dateTime = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
    tspl.writeln('TEXT $centerX,$yPos,"2",0,1,1,"$dateTime"');
    
    // ✅ CRITICAL: Single PRINT command
    tspl.writeln('PRINT 1,1');
    
    print('✅ TSPL Statistical Summary generated');
    print('   Height: $labelHeight mm (optimized)');
    print('   Lines: 7 data lines + header + footer');
    print('   Line spacing: ${lineHeight}px (optimized)');
    
    return tspl.toString();
  }

// ============================================================================
// ✅ FIXED: ESC/POS STATISTICAL SUMMARY
// ============================================================================

static String _generateESCPOSSummary(
      int count,
      double sum,
      double average,
      double max,
      double min,
      double diff,
      double stdDev,
      {
        String? operatorName, 
        String? productName,
        String? unit,
        int? decimalPlaces,
      }
    ) {
      print('📄 Generating ESC/POS Statistical Summary...');
      
      final buffer = StringBuffer();
      
      const String ESC = '\x1B';
      const String GS = '\x1D';
      const String INIT = '$ESC@';
      const String CENTER = '$ESC\x61\x01';
      const String LEFT = '$ESC\x61\x00';
      const String BOLD_ON = '$ESC\x45\x01';
      const String BOLD_OFF = '$ESC\x45\x00';
      const String CUT_PAPER = '$GS\x56\x00';
      const String LINE_FEED = '\n';
      
      buffer.write(INIT);
      buffer.write(CENTER);
      
      // ═══════════════════════════════════════════════════════
      // ✅ HEADER
      // ═══════════════════════════════════════════════════════
      buffer.write(BOLD_ON);
      buffer.write('$GS\x21\x00');
      buffer.write('=== STATISTICS ===');
      buffer.write(LINE_FEED);
      buffer.write(BOLD_OFF);
      buffer.write('$GS\x21\x00');
      
      buffer.write(LEFT);
      
      // ✅ Use parameters with defaults (unit should already be abbreviated)
      String displayUnit = unit ?? 'kg';
      int displayDecimals = decimalPlaces ?? 3;
      double stdDevPercent = average > 0 ? (stdDev / average) * 100 : 0;
      
      print('   Using unit: $displayUnit');
      print('   Using decimals: $displayDecimals');
      
      // ═══════════════════════════════════════════════════════
      // ✅ STATISTICS DATA (9 char padding)
      // ═══════════════════════════════════════════════════════
      
      // Count
      buffer.write('Count    : $count');
      buffer.write(LINE_FEED);
      
      // Sum
      buffer.write('Sum      : ${sum.toStringAsFixed(displayDecimals)} $displayUnit');
      buffer.write(LINE_FEED);
      
      // Average (bold)
      buffer.write(BOLD_ON);
      buffer.write('Average  : ${average.toStringAsFixed(displayDecimals)} $displayUnit');
      buffer.write(LINE_FEED);
      buffer.write(BOLD_OFF);
      
      // Max
      buffer.write('Max      : ${max.toStringAsFixed(displayDecimals)} $displayUnit');
      buffer.write(LINE_FEED);
      
      // Min
      buffer.write('Min      : ${min.toStringAsFixed(displayDecimals)} $displayUnit');
      buffer.write(LINE_FEED);
      
      // Diff
      buffer.write('Diff     : ${diff.toStringAsFixed(displayDecimals)} $displayUnit');
      buffer.write(LINE_FEED);

      // Std Dev
      buffer.write('Std Dev  : ${stdDevPercent.toStringAsFixed(2)}%');
      buffer.write(LINE_FEED);
      
      buffer.write(LINE_FEED);
      buffer.write(LINE_FEED);
      buffer.write(CUT_PAPER);
      
      print('✅ ESC/POS Statistical Summary generated');
      return buffer.toString();
    }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  static bool _isSeparatorLine(String variableUpper, String label) {
    return variableUpper == 'GARIS_PEMISAH' ||
           variableUpper == 'SEPARATOR' ||
           variableUpper == 'LINE' ||
           label.contains('===') ||
           label.contains('---');
  }

  static bool _isQRCode(String variableUpper) {
    return variableUpper == 'QRCODE' ||
           variableUpper == 'QR_CODE' ||
           variableUpper == 'QR';
  }

  static bool _isBarcode(String variableUpper) {
    return variableUpper == 'BARCODE' ||
           variableUpper == 'BAR_CODE' ||
           variableUpper == 'BAR';
  }

  static String _validateTSPL(String tspl) {
  // Count PRINT commands
  final printCount = 'PRINT '.allMatches(tspl).length;
  
  if (printCount == 0) {
    print('⚠️  WARNING: No PRINT command found in TSPL!');
    print('   Label will not print without PRINT command');
  } else if (printCount > 1) {
    print('❌ ERROR: Multiple PRINT commands detected! ($printCount)');
    print('   This will cause $printCount labels to print!');
    
    // ✅ FIX: Remove duplicate PRINT commands, keep only last one
    final lines = tspl.split('\n');
    final filtered = <String>[];
    String? lastPrintCmd;
    
    for (var line in lines) {
      if (line.trim().startsWith('PRINT ')) {
        lastPrintCmd = line; // Keep the last PRINT command
        print('   Found PRINT command: $line');
      } else {
        filtered.add(line);
      }
    }
    
    // Add back the last PRINT command
    if (lastPrintCmd != null) {
      filtered.add(lastPrintCmd);
    }
    
    print('✅ Fixed: Removed ${printCount - 1} duplicate PRINT commands');
    print('   Now has single PRINT command: $lastPrintCmd');
    
    return filtered.join('\n');
  } else {
    print('✅ TSPL valid: Single PRINT command detected');
  }
  
  return tspl;
}

  static double detectDotsPerMm(LabelTemplate template) {
    if (template.settings != null) {
      int? dpi = template.settings!['dpi'] as int?;
      if (dpi != null) {
        return _dpiToDotsPerMm(dpi);
      }
    }
    
    String printerType = template.printerType?.toUpperCase() ?? '';
    double width = template.width;
    
    if (printerType.contains('245') || printerType.contains('300DPI')) {
      return 12.0;
    }
    
    if (width > 80) {
      return 12.0;
    }
    
    return 8.0;
  }

  static double _dpiToDotsPerMm(int dpi) {
    switch (dpi) {
      case 203: return 8.0;
      case 300: return 12.0;
      case 600: return 24.0;
      default: return dpi / 25.4;
    }
  }

  static String _formatElementWithLabel(
  LabelElement element, 
  Map<String, dynamic> data,
) {
  // 1. Ambil raw value
  String rawValue = _getValueForElement(element, data);
  
  // 2. Jika value kosong, return empty (kecuali field static)
  if (rawValue.trim().isEmpty) {
    final staticVars = ['HEADER', 'FOOTER', 'NAMA_PERUSAHAAN', 'ALAMAT', 'TELEPON'];
    bool isStatic = staticVars.contains(element.variable.toUpperCase());
    
    if (!isStatic) {
      return '';
    }
  }
  
  // 3. Ambil label dari element
  String label = element.label.trim();
  
  // 4. ✅ CEK SHOWLABEL (INI YANG KRUSIAL!)
  bool shouldShowLabel = element.showLabel ?? true;  // Default TRUE
  
  print('🏷️  Formatting: ${element.variable}');
  print('   Label: "$label"');
  print('   Value: "$rawValue"');
  print('   showLabel: $shouldShowLabel');
  
  // 5. ✅ Jika showLabel = FALSE, return value aja (tanpa label)
  if (shouldShowLabel == false) {
    print('   ❌ showLabel=false → Output: "$rawValue" (tanpa label)');
    return rawValue;
  }
  
  // 6. ✅ Field yang TIDAK PERLU label (meskipun showLabel = true)
  final noLabelFields = [
    'HEADER',
    'FOOTER', 
    'GARIS_PEMISAH',
    'NAMA_PERUSAHAAN',
  ];
  
  if (noLabelFields.contains(element.variable.toUpperCase())) {
    print('   ℹ️  No-label field → Output: "$rawValue"');
    return rawValue;
  }
  
  // 7. Jika label kosong atau sama dengan variable, return value aja
  if (label.isEmpty || label.toUpperCase() == element.variable.toUpperCase()) {
    print('   ⚠️  Empty/same label → Output: "$rawValue"');
    return rawValue;
  }
  
  // 8. ✅ FORMAT DENGAN LABEL! (INI YANG KITA MAU)
  String formattedOutput = '$label: $rawValue';
  print('   ✅ showLabel=true → Output: "$formattedOutput"');
  
  return formattedOutput;
}
  static String _getValueForElement(LabelElement element, Map<String, dynamic> data) {
    String variable = element.variable.toUpperCase();
    
    for (var entry in data.entries) {
      if (entry.key.toUpperCase() == variable) {
        var value = entry.value;
        if (value == null) return '';
        if (value.toString().trim().isEmpty) return '';
        return value.toString().trim();
      }
    }
    
    return '';
  }

  static String _getESCPOSSize(double fontSize) {
    const String GS = '\x1D';
    
    if (fontSize <= 12) {
      return '$GS\x21\x00'; // 1x1
    } else if (fontSize <= 18) {
      return '$GS\x21\x01'; // 1x2
    } else if (fontSize <= 24) {
      return '$GS\x21\x11'; // 2x2
    } else {
      return '$GS\x21\x11'; // Max safe
    }
  }

  // ============================================================================
  // DATA PREPARATION
  // ============================================================================

  static Map<String, dynamic> prepareDataForPrint({
  required double berat,
  required String unit,
  String? namaBarang,
  String? kategori,
  String? operator,
  String? keterangan,
  int? hargaPerKg,

  int? quantity,
  double? unitWeight,
  int? sampleCount,

  Map<String, dynamic>? additionalData,
  Map<String, String>? customFieldsData,
}) {
  final now = DateTime.now();
  
  final data = <String, dynamic>{
    // ===== WEIGHT DATA =====
    'BERAT': berat.toStringAsFixed(2),
    'UNIT': unit,
    'BERAT_KG': _convertToKg(berat, unit).toStringAsFixed(3),
    'GROSS_WEIGHT': berat.toStringAsFixed(2),
    'TARE_WEIGHT': '0.00',
    'NET_WEIGHT': berat.toStringAsFixed(2),

    // ===== MODE COUNTING DATA =====
'QUANTITY': quantity != null && quantity > 0
    ? '$quantity pcs'
    : '-',

'UNIT_WEIGHT': unitWeight != null && unitWeight > 0
    ? '${(unitWeight * 1000).toStringAsFixed(1)} g/pcs'
    : '-',

'SAMPLE_COUNT': sampleCount != null && sampleCount > 0
    ? '$sampleCount pcs'
    : '-',
    
    // ===== DATE & TIME =====
    'TANGGAL': '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
    'WAKTU': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    'TANGGAL_LENGKAP': _formatTanggalLengkap(now),
    
    // ===== TRANSACTION DATA =====
    'NOMOR_BATCH': 'BATCH-${now.millisecondsSinceEpoch.toString().substring(7)}',
    'NAMA_BARANG': namaBarang ?? '-',
    'KATEGORI': kategori ?? '-',
    'OPERATOR': operator ?? '-',
    'KETERANGAN': keterangan ?? '-',
    
    // ===== PRICE DATA =====
    'HARGA_PER_KG': hargaPerKg != null ? 'Rp ${_formatCurrency(hargaPerKg)}' : '-',
    'TOTAL_HARGA': (hargaPerKg != null && berat > 0)
        ? 'Rp ${_formatCurrency((_convertToKg(berat, unit) * hargaPerKg).round())}'
        : '-',
    
    // ===== COMPANY INFO =====
    'NAMA_PERUSAHAAN': 'PT TRISURYA SOLUSINDO UTAMA',
    'ALAMAT': 'Jl. Raya Citarik, Jatireja, Kec. Cikarang Tim., Kabupaten Bekasi, Jawa Barat 17530',
    'TELEPON': '(021) 56927540',
    'HEADER': 'T-CONNECT',
    'FOOTER': 'info@trisuryasolusindo.com',
    
    // ===== SEPARATORS =====
    'GARIS_PEMISAH': '================================',
  };

  if (customFieldsData != null && customFieldsData.isNotEmpty) {
    print('\n📋 Custom Fields Mapping:');
    customFieldsData.forEach((label, value) {
      String variableName = _mapLabelToVariable(label);
      data[variableName] = value.isEmpty ? '-' : value;
      print('   $label → $variableName = "$value"');
    });
  }
  
  if (additionalData != null) {
    data.addAll(additionalData);
  }
  
  return data;
}

static String _mapLabelToVariable(String label) {
  final mapping = {
    'Product': 'NAMA_BARANG',
    'Client': 'CLIENT',
    'ID': 'MATERIAL_CODE',
    'Supplier': 'SUPPLIER',
    'Batch Number': 'NOMOR_BATCH',
    'Material Code': 'MATERIAL_CODE',
    'SKU': 'SKU',
    'Location': 'LOCATION',
    'Operator': 'OPERATOR',
    'Notes': 'KETERANGAN',
  };
  
  return mapping[label] ?? label.toUpperCase().replaceAll(' ', '_');
}

  static double _convertToKg(double weight, String unit) {
    switch (unit.toUpperCase()) {
      case 'KG': return weight;
      case 'GRAM': return weight / 1000;
      case 'ONS': return weight / 10;
      case 'POUND': return weight * 0.453592;
      default: return weight;
    }
  }

static String _formatTanggalLengkap(DateTime date) {
  const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  return '${days[date.weekday % 7]}, ${date.day} ${months[date.month]} ${date.year}';
}

  // ============================================================================
// DEBUG & SIMPLE LABEL GENERATION
// ============================================================================

/// Debug TSPL output dengan formatting yang rapi
static void debugTSPL(String tspl) {
  print('╔═══════════════════════════════════════════════════════╗');
  print('║              📄 TSPL COMMANDS DEBUG                   ║');
  print('╚═══════════════════════════════════════════════════════╝');
  
  List<String> lines = tspl.split('\n');
  int lineNum = 1;
  
  for (String line in lines) {
    if (line.trim().isEmpty) continue;
    print('${lineNum.toString().padLeft(3, '0')} │ $line');
    lineNum++;
  }
  
  print('═' * 60);
}

/// Generate simple TSPL label (untuk testing/fallback)
static String generateSimpleTSPLLabel({
  required double berat,
  required String unit,
  String? namaBarang,
  String? kategori,
  String? operator,
}) {
  StringBuffer tspl = StringBuffer();
  
  // Printer setup
  tspl.writeln('SIZE 58 mm, 40 mm');
  tspl.writeln('GAP 2 mm, 0 mm');
  tspl.writeln('DIRECTION 0');
  tspl.writeln('REFERENCE 0,0');
  tspl.writeln('OFFSET 0 mm');
  tspl.writeln('DENSITY 8');
  tspl.writeln('SPEED 3');
  tspl.writeln('SET TEAR ON');
  tspl.writeln('SET LINESPACE 0');
  tspl.writeln('CLS');
  
  const int marginLeft = 40;
  int yPos = 30;
  
  // Header
  tspl.writeln('TEXT 140,$yPos,"3",0,1,1,"T-CONNECT"');
  yPos += 28;
  
  tspl.writeln('BAR 40,$yPos,380,2');
  yPos += 12;
  
  // Item name
  if (namaBarang != null && namaBarang.isNotEmpty && namaBarang != '-') {
    String shortName = namaBarang.length > 18 
        ? '${namaBarang.substring(0, 18)}..' 
        : namaBarang;
    tspl.writeln('TEXT $marginLeft,$yPos,"3",0,1,1,"$shortName"');
    yPos += 28;
  }
  
  // Category
  if (kategori != null && kategori.isNotEmpty && kategori != '-') {
    String shortKat = kategori.length > 20 
        ? '${kategori.substring(0, 20)}..' 
        : kategori;
    tspl.writeln('TEXT $marginLeft,$yPos,"3",0,1,1,"$shortKat"');
    yPos += 28;
  }
  
  tspl.writeln('BAR 40,$yPos,380,2');
  yPos += 12;
  
  // Weight
  String beratStr = berat.toStringAsFixed(2);
  tspl.writeln('TEXT $marginLeft,$yPos,"3",0,1,1,"$beratStr $unit"');
  yPos += 28;
  
  tspl.writeln('BAR 40,$yPos,380,2');
  yPos += 12;
  
  // Footer
  DateTime now = DateTime.now();
  String dateStr = '${now.day.toString().padLeft(2, '0')}/'
                   '${now.month.toString().padLeft(2, '0')} '
                   '${now.hour.toString().padLeft(2, '0')}:'
                   '${now.minute.toString().padLeft(2, '0')}';
  
  tspl.writeln('TEXT $marginLeft,$yPos,"2",0,1,1,"$dateStr"');
  
  if (operator != null && operator.isNotEmpty && operator != '-') {
    String shortOp = operator.length > 8 
        ? operator.substring(0, 8) 
        : operator;
    tspl.writeln('TEXT 320,$yPos,"2",0,1,1,"$shortOp"');
  }
  
  tspl.writeln('PRINT 1');
  
  return tspl.toString();
}

  static String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

// TSC Font Configuration Class
class TSCFontConfig {
  final String font;
  final String size;
  final String displaySize;
  
  const TSCFontConfig({
    required this.font,
    required this.size,
    required this.displaySize,
  });
}