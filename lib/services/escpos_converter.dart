import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/label_template_model.dart';

/// ESC/POS Converter
/// Converts label template to ESC/POS printer commands
/// 
/// Digunakan untuk convert template visual menjadi command printer thermal
class ESCPOSConverter {
  // ============================================================================
  // ESC/POS COMMANDS CONSTANTS
  // ============================================================================
  
  static const ESC = 0x1B;  // Escape character
  static const GS = 0x1D;   // Group Separator
  
  // Text alignment
  static const ALIGN_LEFT = 0x00;
  static const ALIGN_CENTER = 0x01;
  static const ALIGN_RIGHT = 0x02;
  
  // Text size
  static const SIZE_NORMAL = 0x00;
  static const SIZE_DOUBLE_HEIGHT = 0x01;
  static const SIZE_DOUBLE_WIDTH = 0x10;
  static const SIZE_DOUBLE = 0x11;
  static const SIZE_TRIPLE = 0x22;
  
  // ============================================================================
  // MAIN CONVERTER FUNCTION
  // ============================================================================
  
  /// Convert label template to ESC/POS byte commands
  /// 
  /// Usage:
  /// ```dart
  /// final bytes = ESCPOSConverter.generateESCPOS(template, printData);
  /// await bluetoothPrinter.writeBytes(bytes);
  /// ```
  static Uint8List generateESCPOS(
    LabelTemplate template,
    Map<String, dynamic> data,
  ) {
    final List<int> bytes = [];
    
    try {
      // Initialize printer
      bytes.addAll([ESC, 0x40]); // ESC @ - Initialize printer
      
      // Sort elements by Y position (top to bottom)
      final sortedElements = List<LabelElement>.from(template.elements)
        ..sort((a, b) => a.y.compareTo(b.y));
      
      // Process each element
      for (var element in sortedElements) {
        // Get value from data
        final value = _getValueForVariable(element.variable, data);
        if (value.isEmpty) continue;
        
        // Set text alignment
        bytes.addAll(_getAlignmentCommand(element.textAlign));
        
        // Set text size based on fontSize
        bytes.addAll(_getTextSizeCommand(element.fontSize));
        
        // Set bold if needed
        if (element.fontWeight == FontWeight.bold) {
          bytes.addAll([ESC, 0x45, 0x01]); // ESC E 1 - Bold ON
        }
        
        // Print the text
        bytes.addAll(value.codeUnits);
        bytes.add(0x0A); // Line feed (new line)
        
        // Reset formatting
        bytes.addAll([ESC, 0x45, 0x00]); // ESC E 0 - Bold OFF
        bytes.addAll([GS, 0x21, SIZE_NORMAL]); // GS ! 0 - Normal size
      }
      
      // Add separator line at the end
      bytes.addAll([ESC, 0x61, ALIGN_LEFT]); // Left align
      bytes.addAll('================================'.codeUnits);
      bytes.add(0x0A);
      
      // Feed paper and cut
      bytes.addAll([0x0A, 0x0A, 0x0A]); // 3 line feeds for spacing
      bytes.addAll([GS, 0x56, 0x00]); // GS V 0 - Full cut paper
      
      return Uint8List.fromList(bytes);
      
    } catch (e) {
      print('Error generating ESC/POS: $e');
      // Return minimal safe command on error
      return Uint8List.fromList([ESC, 0x40]); // Just initialize
    }
  }
  
  // ============================================================================
  // HELPER FUNCTIONS - ESC/POS COMMANDS
  // ============================================================================
  
  /// Get alignment command based on TextAlign
  static List<int> _getAlignmentCommand(TextAlign align) {
    int alignValue;
    
    switch (align) {
      case TextAlign.center:
        alignValue = ALIGN_CENTER;
        break;
      case TextAlign.right:
        alignValue = ALIGN_RIGHT;
        break;
      default:
        alignValue = ALIGN_LEFT;
    }
    
    return [ESC, 0x61, alignValue]; // ESC a n - Set alignment
  }
  
  /// Get text size command based on fontSize
  static List<int> _getTextSizeCommand(double fontSize) {
    int sizeValue;
    
    if (fontSize <= 12) {
      sizeValue = SIZE_NORMAL;          // Normal (12px or less)
    } else if (fontSize <= 18) {
      sizeValue = SIZE_DOUBLE_HEIGHT;   // Double height (13-18px)
    } else if (fontSize <= 24) {
      sizeValue = SIZE_DOUBLE;          // Double width & height (19-24px)
    } else {
      sizeValue = SIZE_TRIPLE;          // Triple size (25px+)
    }
    
    return [GS, 0x21, sizeValue]; // GS ! n - Set text size
  }
  
  // ============================================================================
  // HELPER FUNCTIONS - DATA PROCESSING
  // ============================================================================
  
  /// Get value for variable from data map
  /// 
  /// Supports variables like:
  /// - {company_name} → Company name
  /// - {gross_weight} → 15,250 (formatted)
  /// - {total_price} → 25,000,000 (formatted)
  static String _getValueForVariable(String variable, Map<String, dynamic> data) {
    // Remove curly braces to get the key
    final key = variable.replaceAll('{', '').replaceAll('}', '');
    
    // Get value from data map
    final value = data[key];
    
    // Return empty if null
    if (value == null) return '';
    
    // Format numbers with thousand separator
    if (value is num) {
      return _formatNumber(value);
    }
    
    // Return as string for other types
    return value.toString();
  }
  
  /// Format number with thousand separator
  /// 
  /// Examples:
  /// - 1000 → 1,000
  /// - 15250 → 15,250
  /// - 25000000 → 25,000,000
  /// - 1250.50 → 1,250.50
  static String _formatNumber(num number) {
    // Split into integer and decimal parts
    final parts = number.toString().split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
    
    // Add thousand separators to integer part
    final buffer = StringBuffer();
    var count = 0;
    
    // Process from right to left
    for (var i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
      count++;
    }
    
    // Reverse back and add decimal part
    return buffer.toString().split('').reversed.join() + decimalPart;
  }
  
  // ============================================================================
  // ALTERNATIVE - SIMPLE TEXT FORMAT
  // ============================================================================
  
  /// Generate simple text content (fallback untuk testing)
  /// 
  /// Ini untuk testing tanpa printer, atau untuk printer yang
  /// tidak support ESC/POS commands
  /// 
  /// Usage:
  /// ```dart
  /// final text = ESCPOSConverter.generateSimpleText(template, printData);
  /// await bluetoothPrinter.printText(text);
  /// ```
  static String generateSimpleText(
    LabelTemplate template,
    Map<String, dynamic> data,
  ) {
    try {
      // Sort elements by Y position (top to bottom)
      final sortedElements = List<LabelElement>.from(template.elements)
        ..sort((a, b) => a.y.compareTo(b.y));
      
      final buffer = StringBuffer();
      
      // Add header separator
      buffer.writeln('================================');
      
      // Process each element
      for (var element in sortedElements) {
        final value = _getValueForVariable(element.variable, data);
        
        if (value.isNotEmpty) {
          // Format: Label: Value
          final line = _formatLine(element.label, value, element.textAlign);
          buffer.writeln(line);
        }
      }
      
      // Add footer separator
      buffer.writeln('================================');
      
      return buffer.toString();
      
    } catch (e) {
      print('Error generating simple text: $e');
      return 'Error generating receipt';
    }
  }
  
  /// Format line dengan alignment
  static String _formatLine(String label, String value, TextAlign align) {
    const maxWidth = 32; // Standard thermal printer width
    
    switch (align) {
      case TextAlign.center:
        // Center the whole line
        final text = '$label: $value';
        return _centerText(text, maxWidth);
        
      case TextAlign.right:
        // Right align value
        final leftPart = '$label: ';
        final spaces = maxWidth - leftPart.length - value.length;
        return leftPart + (' ' * (spaces > 0 ? spaces : 1)) + value;
        
      default:
        // Left align (label: value)
        return '$label: $value';
    }
  }
  
  /// Center text dengan padding
  static String _centerText(String text, int width) {
    if (text.length >= width) return text;
    
    final padding = (width - text.length) ~/ 2;
    return (' ' * padding) + text;
  }
  
  // ============================================================================
  // ADVANCED - WITH PRINTER SPECS
  // ============================================================================
  
  /// Generate ESC/POS dengan printer specifications
  /// 
  /// Untuk printer yang butuh konfigurasi khusus
  static Uint8List generateESCPOSWithSpecs(
    LabelTemplate template,
    Map<String, dynamic> data, {
    int printerWidth = 384, // dots (48mm = 384 dots @ 203dpi)
    int charsPerLine = 32,
    bool enableCut = true,
    bool enableBuzzer = false,
  }) {
    final List<int> bytes = [];
    
    try {
      // Initialize
      bytes.addAll([ESC, 0x40]);
      
      // Set print area width if needed
      // bytes.addAll([GS, 0x57, printerWidth & 0xFF, (printerWidth >> 8) & 0xFF]);
      
      // Generate content (reuse main function)
      final content = generateESCPOS(template, data);
      bytes.addAll(content);
      
      // Buzzer (optional)
      if (enableBuzzer) {
        bytes.addAll([ESC, 0x42, 0x02, 0x02]); // ESC B - Buzzer
      }
      
      return Uint8List.fromList(bytes);
      
    } catch (e) {
      print('Error generating ESC/POS with specs: $e');
      return Uint8List.fromList([ESC, 0x40]);
    }
  }
}
