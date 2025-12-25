enum PrinterType {
  escpos,
  tsc,
}

class PrinterConfig {
  final PrinterType type;
  final double labelWidth;
  final double labelHeight;
  final String typeName;
  
  PrinterConfig({
    required this.type,
    this.labelWidth = 58.0,
    this.labelHeight = 50.0,
    String? typeName,
  }) : typeName = typeName ?? (type == PrinterType.tsc ? 'TSC Label Printer' : 'ESC/POS Thermal Printer');
  
  factory PrinterConfig.fromDeviceName(String deviceName) {
    final nameLower = deviceName.toLowerCase();
    
    if (nameLower.contains('tsc') || 
        nameLower.contains('alpha') ||
        nameLower.contains('3crw') ||
        nameLower.contains('ttp') ||
        nameLower.contains('244') ||
        nameLower.contains('245') ||
        nameLower.contains('2r') ||
        nameLower.contains('label')) {
      
      double width = 58.0;
      double height = 50.0;
      
      if (nameLower.contains('244') || nameLower.contains('alpha')) {
        width = 58.0;
        height = 50.0;
      } else if (nameLower.contains('245')) {
        width = 104.0;
        height = 50.0;
      }
      
      return PrinterConfig(
        type: PrinterType.tsc,
        labelWidth: width,
        labelHeight: height,
        typeName: 'TSC Label Printer ($deviceName)',
      );
    }
    
    return PrinterConfig(
      type: PrinterType.escpos,
      typeName: 'ESC/POS Thermal ($deviceName)',
    );
  }
  
  String get tsplSizeCommand => 'SIZE $labelWidth mm, $labelHeight mm';
  
  bool get isTSC => type == PrinterType.tsc;
  
  bool get isESCPOS => type == PrinterType.escpos;
  
  @override
  String toString() => typeName;
}

extension PrinterTypeExtension on String {
  bool get isTSCPrinter {
    final lower = toLowerCase();
    return lower.contains('tsc') ||
           lower.contains('alpha') ||
           lower.contains('3crw') ||
           lower.contains('ttp') ||
           lower.contains('244') ||
           lower.contains('245') ||
           lower.contains('label');
  }
  
  bool get isESCPOSPrinter => !isTSCPrinter;
}