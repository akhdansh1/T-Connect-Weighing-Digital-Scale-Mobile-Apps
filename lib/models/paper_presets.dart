class PaperPreset {
  final String name;
  final String displayName;
  final double width;  // mm
  final double height; // mm
  final String printerType;
  final String description;
  
  const PaperPreset({
    required this.name,
    required this.displayName,
    required this.width,
    required this.height,
    required this.printerType,
    required this.description,
  });
  
  @override
  String toString() {
    return 'PaperPreset($name: ${width}x${height}mm, $printerType)';
  }
  
  bool get isAutoHeight => height <= 0;
  bool get isTSC => printerType == 'TSC';
  bool get isESCPOS => printerType == 'ESCPOS';
}

class PaperPresets {
  
  static const tsc58x40 = PaperPreset(
    name: '58x40',
    displayName: '58mm x 40mm (TSC)',
    width: 58.0,
    height: 40.0,
    printerType: 'TSC',
    description: 'Label kecil - TSC 244 Pro, Alpha-2R',
  );
  
  static const tsc58x50 = PaperPreset(
    name: '58x50',
    displayName: '58mm x 50mm (TSC)',
    width: 58.0,
    height: 50.0,
    printerType: 'TSC',
    description: 'Label standard - TSC 244 Pro, Alpha-2R',
  );
  
  static const tsc72x50 = PaperPreset(
    name: '72x50',
    displayName: '72mm x 50mm (TSC)',
    width: 72.0,
    height: 50.0,
    printerType: 'TSC',
    description: 'Label lebar - TSC 244 Pro',
  );
  
  static const tsc100x50 = PaperPreset(
    name: '100x50',
    displayName: '100mm x 50mm (TSC)',
    width: 100.0,
    height: 50.0,
    printerType: 'TSC',
    description: 'Label besar - TSC 244 Pro, 342 Pro',
  );
  
  static const tsc100x70 = PaperPreset(
    name: '100x70',
    displayName: '100mm x 70mm (TSC)',
    width: 100.0,
    height: 70.0,
    printerType: 'TSC',
    description: 'Label extra besar - TSC 342 Pro',
  );
  
  static const tsc100x100 = PaperPreset(
    name: '100x100',
    displayName: '100mm x 100mm (TSC)',
    width: 100.0,
    height: 100.0,
    printerType: 'TSC',
    description: 'Label square - TSC 342 Pro',
  );
  
  static const escpos58 = PaperPreset(
    name: '58-receipt',
    displayName: '58mm Receipt (ESC/POS)',
    width: 58.0,
    height: 100.0,
    printerType: 'ESCPOS',
    description: 'Struk thermal 58mm - Virtual canvas untuk designer',
  );
  
  static const escpos80 = PaperPreset(
    name: '80-receipt',
    displayName: '80mm Receipt (ESC/POS)',
    width: 80.0,
    height: 150.0,
    printerType: 'ESCPOS',
    description: 'Struk thermal 80mm - Virtual canvas untuk designer',
  );
  
  static const escpos58Long = PaperPreset(
    name: '58-receipt-long',
    displayName: '58mm Receipt Long (ESC/POS)',
    width: 58.0,
    height: 200.0,
    printerType: 'ESCPOS',
    description: 'Struk thermal 58mm panjang - Untuk transaksi detail',
  );
  
  static const escpos80Long = PaperPreset(
    name: '80-receipt-long',
    displayName: '80mm Receipt Long (ESC/POS)',
    width: 80.0,
    height: 250.0,
    printerType: 'ESCPOS',
    description: 'Struk thermal 80mm panjang - Untuk transaksi detail',
  );
  
  static const List<PaperPreset> tscPresets = [
    tsc58x40,
    tsc58x50,
    tsc72x50,
    tsc100x50,
    tsc100x70,
    tsc100x100,
  ];
  
  static const List<PaperPreset> escposPresets = [
    escpos58,
    escpos80,
    escpos58Long,
    escpos80Long,
  ];
  
  static const List<PaperPreset> allPresets = [
    ...tscPresets,
    ...escposPresets,
  ];
  
  static PaperPreset? getPreset(String name) {
    try {
      return allPresets.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  static List<PaperPreset> getPresetsByType(String printerType) {
    return allPresets.where(
      (p) => p.printerType.toLowerCase() == printerType.toLowerCase(),
    ).toList();
  }
  
  static PaperPreset? getPresetBySize(
    double width, 
    double height, 
    String printerType, {
    double tolerance = 2.0, // mm
  }) {
    try {
      return allPresets.firstWhere(
        (p) {
          final widthMatch = (p.width - width).abs() <= tolerance;
          final heightMatch = (p.height - height).abs() <= tolerance;
          final typeMatch = p.printerType.toLowerCase() == printerType.toLowerCase();
          
          return widthMatch && heightMatch && typeMatch;
        },
      );
    } catch (e) {
      return null;
    }
  }
  
  static bool isCompatible(String paperSize, String printerType) {
    final preset = getPreset(paperSize);
    if (preset == null) return false;
    
    return preset.printerType.toLowerCase() == printerType.toLowerCase();
  }
  
  static PaperPreset getDefaultPreset(String printerType) {
    if (printerType.toLowerCase() == 'tsc') {
      return tsc58x50;
    } else {
      return escpos80;
    }
  }
  
  static List<PaperPreset> getSuggestedPresets(String printerModel) {
    final model = printerModel.toLowerCase();
    
    if (model.contains('tsc') || model.contains('alpha')) {
      if (model.contains('244') || model.contains('243')) {
        return [tsc58x40, tsc58x50, tsc72x50, tsc100x50, tsc100x70];
      } else if (model.contains('342') || model.contains('343')) {
        return [tsc100x50, tsc100x70, tsc100x100];
      } else {
        return tscPresets;
      }
    }
    
    if (model.contains('thermal') || 
        model.contains('receipt') || 
        model.contains('pos')) {
      
      if (model.contains('58')) {
        return [escpos58, escpos58Long];
      } else if (model.contains('80')) {
        return [escpos80, escpos80Long];
      } else {
        return escposPresets;
      }
    }
    
    return allPresets;
  }
  
  static bool isValidCanvasSize(double width, double height) {
    if (width <= 0) return false;
    
    if (height < 0) return false;
    
    if (width < 5 || width > 300) return false;
    if (height > 0 && (height < 5 || height > 500)) return false;
    
    return true;
  }
  
  static String getSizeDescription(double width, double height) {
    if (height <= 0) {
      return '${width.toInt()}mm wide (auto-height)';
    } else {
      return '${width.toInt()}mm × ${height.toInt()}mm';
    }
  }
  
  static int getRecommendedDPI(double width) {
    if (width > 80) {
      return 300;
    }
    else {
      return 203; // 8 dots/mm
    }
  }
  
  static void printAllPresets() {
    print('╔═══════════════════════════════════════════════════════╗');
    print('║           AVAILABLE PAPER PRESETS                    ║');
    print('╚═══════════════════════════════════════════════════════╝');
    
    print('\n📋 TSC Label Presets (${tscPresets.length}):');
    print('─' * 60);
    for (var preset in tscPresets) {
      print('  ${preset.displayName.padRight(35)} ${preset.width}×${preset.height}mm');
    }
    
    print('\n🧾 ESC/POS Receipt Presets (${escposPresets.length}):');
    print('─' * 60);
    for (var preset in escposPresets) {
      print('  ${preset.displayName.padRight(35)} ${preset.width}×${preset.height}mm');
    }
    
    print('\n' + '═' * 60);
    print('Total: ${allPresets.length} presets\n');
  }
}