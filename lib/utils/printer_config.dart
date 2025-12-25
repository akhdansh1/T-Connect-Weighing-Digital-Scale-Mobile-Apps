// lib/utils/printer_config.dart

/// Configuration untuk mapping printer model ke paper type
/// Dan auto-detection logic untuk printer settings
class PrinterConfig {
  
  // ============================================================================
  // PRINTER MODEL TO PAPER TYPE MAPPING
  // ============================================================================
  
  /// Map printer model/type ke paper type default
  /// Key: Printer model keyword (case-insensitive)
  /// Value: Paper type yang sesuai ('Struk' atau 'Label')
  static const Map<String, String> printerToPaperType = {
    // ═══════════════════════════════════════════════════════════════
    // ESC/POS PRINTERS (Thermal Receipt Printers) → STRUK
    // ═══════════════════════════════════════════════════════════════
    'ESC': 'Struk',
    'ESCPOS': 'Struk',
    'ESC/POS': 'Struk',
    'RPP': 'Struk',           // RPP series (thermal receipt)
    'THERMAL': 'Struk',
    'RECEIPT': 'Struk',
    'POS': 'Struk',
    'EPSON': 'Struk',         // Epson TM series
    'TM-': 'Struk',           // Epson TM-T82, TM-T88, etc
    'STAR': 'Struk',          // Star Micronics
    'BIXOLON': 'Struk',       // Bixolon SRP series
    'CITIZEN': 'Struk',       // Citizen CT-S series
    
    // ═══════════════════════════════════════════════════════════════
    // TSC LABEL PRINTERS → LABEL
    // ═══════════════════════════════════════════════════════════════
    'TSC': 'Label',
    'TTP': 'Label',           // TSC TTP series
    'TDP': 'Label',           // TSC TDP series
    'ALPHA': 'Label',         // TSC Alpha series
    'ME240': 'Label',         // TSC ME series
    'ME340': 'Label',
    'TC200': 'Label',         // TSC TC series
    'TC300': 'Label',
    
    // Other label printer brands
    'ZEBRA': 'Label',         // Zebra ZD, ZT series
    'DATAMAX': 'Label',       // Datamax O'Neil
    'SATO': 'Label',          // Sato CL series
    'GODEX': 'Label',         // Godex G series
    'ARGOX': 'Label',         // Argox OS series
  };
  
  // ============================================================================
  // PAPER SIZE PRESETS MAPPING
  // ============================================================================
  
  /// Map paper size name ke printer type yang cocok
  static const Map<String, String> paperSizeToPrinterType = {
    // Receipt sizes (ESC/POS)
    '58mm Struk': 'ESC/POS',
    '80mm Struk': 'ESC/POS',
    'Struk 58mm': 'ESC/POS',
    'Struk 80mm': 'ESC/POS',
    
    // Label sizes (TSC)
    '58x50 Label': 'TSC',
    '58x40 Label': 'TSC',
    '100x50 Label': 'TSC',
    '100x100 Label': 'TSC',
  };
  
  // ============================================================================
  // AUTO-DETECTION METHODS
  // ============================================================================
  
  /// Detect paper type berdasarkan printer model/name
  /// 
  /// Returns: 'Struk' atau 'Label'
  /// Default: 'Struk' (thermal receipt - most common)
  static String getPaperTypeForPrinter(String printerModel) {
    if (printerModel.isEmpty) return 'Struk';
    
    final modelUpper = printerModel.toUpperCase();
    
    // Check setiap keyword di mapping
    for (var entry in printerToPaperType.entries) {
      if (modelUpper.contains(entry.key.toUpperCase())) {
        print('🔍 Auto-detect: "$printerModel" → "${entry.value}"');
        return entry.value;
      }
    }
    
    // Default fallback: thermal receipt printer (most common)
    print('🔍 Auto-detect: "$printerModel" → "Struk" (default)');
    return 'Struk';
  }
  
  /// Detect printer type (ESC/POS atau TSC) berdasarkan model
  /// 
  /// Returns: 'ESC/POS' atau 'TSC'
  static String getPrinterTypeForModel(String printerModel) {
    final paperType = getPaperTypeForPrinter(printerModel);
    return paperType == 'Label' ? 'TSC' : 'ESC/POS';
  }
  
  /// Check apakah printer adalah TSC label printer
  static bool isTSCPrinter(String printerModel) {
    return getPaperTypeForPrinter(printerModel) == 'Label';
  }
  
  /// Check apakah printer adalah ESC/POS thermal printer
  static bool isESCPOSPrinter(String printerModel) {
    return getPaperTypeForPrinter(printerModel) == 'Struk';
  }
  
  // ============================================================================
  // PAPER SIZE RECOMMENDATIONS
  // ============================================================================
  
  /// Get recommended paper sizes untuk printer type
  static List<String> getRecommendedPaperSizes(String printerType) {
    if (printerType.toUpperCase().contains('TSC')) {
      return [
        '58x50 Label',
        '58x40 Label',
        '100x50 Label',
        '100x100 Label',
      ];
    } else {
      return [
        '58mm Struk',
        '80mm Struk',
      ];
    }
  }
  
  /// Get default paper size untuk printer type
  static String getDefaultPaperSize(String printerType) {
    if (printerType.toUpperCase().contains('TSC')) {
      return '58x50 Label';
    } else {
      return '58mm Struk';
    }
  }
  
  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================
  
  /// Validate apakah paper size cocok dengan printer type
  static bool isPaperSizeCompatible(String paperSize, String printerType) {
    final isLabel = paperSize.toLowerCase().contains('label');
    final isTSC = printerType.toUpperCase().contains('TSC');
    
    // Label paper harus dengan TSC printer
    // Struk paper harus dengan ESC/POS printer
    return isLabel == isTSC;
  }
  
  /// Get warning message jika paper size tidak cocok
  static String? getCompatibilityWarning(String paperSize, String printerType) {
    if (!isPaperSizeCompatible(paperSize, printerType)) {
      final isLabel = paperSize.toLowerCase().contains('label');
      if (isLabel) {
        return '⚠️ Label paper membutuhkan TSC printer.\n'
               'Printer Anda: $printerType (ESC/POS)';
      } else {
        return '⚠️ Struk paper membutuhkan ESC/POS printer.\n'
               'Printer Anda: $printerType (TSC)';
      }
    }
    return null;
  }
}

// ============================================================================
// PRINTER DETECTION RESULT CLASS
// ============================================================================

/// Result object dari printer detection
class PrinterDetectionResult {
  final String printerName;
  final String printerModel;
  final String detectedPrinterType; // 'ESC/POS' atau 'TSC'
  final String detectedPaperType;   // 'Struk' atau 'Label'
  final String recommendedPaperSize;
  final bool isAutoDetected;
  
  const PrinterDetectionResult({
    required this.printerName,
    required this.printerModel,
    required this.detectedPrinterType,
    required this.detectedPaperType,
    required this.recommendedPaperSize,
    this.isAutoDetected = true,
  });
  
  factory PrinterDetectionResult.fromPrinter(
    String printerName, 
    String printerModel,
  ) {
    final printerType = PrinterConfig.getPrinterTypeForModel(printerModel);
    final paperType = PrinterConfig.getPaperTypeForPrinter(printerModel);
    final paperSize = PrinterConfig.getDefaultPaperSize(printerType);
    
    return PrinterDetectionResult(
      printerName: printerName,
      printerModel: printerModel,
      detectedPrinterType: printerType,
      detectedPaperType: paperType,
      recommendedPaperSize: paperSize,
    );
  }
  
  @override
  String toString() {
    return 'PrinterDetection(\n'
           '  Name: $printerName\n'
           '  Model: $printerModel\n'
           '  Type: $detectedPrinterType\n'
           '  Paper: $detectedPaperType ($recommendedPaperSize)\n'
           '  Auto: $isAutoDetected\n'
           ')';
  }
}