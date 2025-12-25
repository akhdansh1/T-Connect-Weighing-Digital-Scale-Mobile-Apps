import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Helper class untuk manage koneksi dan printing ke Bluetooth printer
/// 
/// Supports:
/// - TSC Label Printer (TSPL commands)
/// - ESC/POS Thermal Receipt Printer
class BluetoothPrinterHelper {
  BluetoothConnection? _connection;
  String? _printerType; // 'TSC' or 'ESCPOS'
  
  // ============================================================================
  // CONNECTION MANAGEMENT
  // ============================================================================
  
  /// Connect ke printer via Bluetooth
  Future<bool> connect(String address, {String? printerName}) async {
    try {
      print('🔌 Connecting to printer: $address');
      _connection = await BluetoothConnection.toAddress(address);
      
      // Auto-detect printer type dari nama
      if (printerName != null) {
        // ✅ TAMBAH CHECK KHUSUS UNTUK PS-6E1A5A
        if (printerName.toUpperCase().contains('PS-6E1A5A')) {
          _printerType = 'TSC';
          print('✅ Connected - Forced TSC type for PS-6E1A5A');
        } else {
          _printerType = _detectPrinterType(printerName);
          print('✅ Connected successfully - Type: $_printerType');
        }
      } else {
        _printerType = 'ESCPOS'; // Default
        print('✅ Connected successfully - Type: $_printerType (default)');
      }
      
      return true;
    } catch (e) {
      print('❌ Connection failed: $e');
      return false;
    }
  }
  
  /// Detect printer type dari nama device
  String _detectPrinterType(String printerName) {
    String nameLower = printerName.toLowerCase();
    
    // Check for TSC printer keywords
    if (nameLower.contains('tsc') ||
        nameLower.contains('alpha') ||
        nameLower.contains('3crw') ||
        nameLower.contains('ttp') ||
        nameLower.contains('244') ||
        nameLower.contains('245') ||
        nameLower.contains('label')) {
      return 'TSC';
    }
    
    return 'ESCPOS';
  }
  
  /// Disconnect dari printer
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      _printerType = null;
      print('🔌 Disconnected from printer');
    } catch (e) {
      print('⚠️ Error disconnecting: $e');
    }
  }
  
  /// Check apakah masih terkoneksi
  bool get isConnected => 
      _connection != null && _connection!.isConnected;
  
  /// Get printer type
  String? get printerType => _printerType;
  bool get isTSCPrinter => _printerType == 'TSC';
  
  // ============================================================================
  // PRINT METHODS - TSC LABEL PRINTER (TSPL)
  // ============================================================================
  
  /// Print menggunakan TSPL commands (untuk TSC printer)
  /// 
  /// ⚠️ DEPRECATED: Function ini sekarang hanya redirect ke printRawTSPL
  /// untuk menghindari double-parsing TSPL commands yang merusak format.
  /// 
  /// Gunakan printRawTSPL() directly untuk hasil yang lebih baik.
  /// 
  /// textContent harus berupa TSPL commands yang sudah di-generate
  /// dari LabelPrintService atau TSPLTemplateService
  @Deprecated('Use printRawTSPL() directly for TSPL commands')
Future<bool> printTSCLabel(
  String textContent, {
  double labelWidth = 58.0,
  double labelHeight = 50.0,
}) async {
  print('⚠️  [DEPRECATED] printTSCLabel() called');
  print('   Forwarding to printRawTSPL() - ignoring width/height params');
  print('   TSPL commands should already include SIZE command');
  
  // ✅ Direct forward tanpa modifikasi apapun
  return await printRawTSPL(textContent);
}
  
  /// Print raw TSPL commands (sudah dalam format TSPL lengkap)
  /// 
  /// ✅ INI FUNCTION YANG BENAR UNTUK TSC PRINTER!
  /// 
  /// Function ini mengirim TSPL commands langsung ke printer tanpa modifikasi.
  /// TSPL commands harus sudah complete dan valid, termasuk:
  /// - SIZE command (ukuran label)
  /// - GAP/BLINE command (sensor type)
  /// - TEXT/BAR/BOX commands (content)
  /// - PRINT command (execute)
  /// 
  /// Example TSPL:
  /// ```
  /// SIZE 58 mm, 50 mm
  /// GAP 3 mm, 0 mm
  /// DENSITY 8
  /// SPEED 3
  /// CLS
  /// TEXT 30,50,"3",0,1,1,"Operator: Dimas"
  /// TEXT 60,120,"5",0,3,3,"15.50"
  /// PRINT 1,1
  /// ```
  Future<bool> printRawTSPL(String tsplCommands) async {
    if (!isConnected) {
      print('❌ Not connected to printer');
      return false;
    }
    
    try {
      print('📄 Sending raw TSPL commands...');
      print('═' * 50);
      print(tsplCommands);
      print('═' * 50);
      
      // Convert to bytes
      Uint8List bytes = Uint8List.fromList(utf8.encode(tsplCommands));
      
      // Send to printer
      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      
      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('✅ Raw TSPL sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending raw TSPL: $e');
      return false;
    }
  }
  
  // ============================================================================
  // PRINT METHODS - THERMAL RECEIPT PRINTER (ESC/POS)
  // ============================================================================
  
  /// Print menggunakan ESC/POS commands (untuk thermal receipt printer)
  /// 
  /// escposContent harus berupa ESC/POS byte sequence yang valid.
  /// Biasanya di-generate dari ESCPOSConverter atau LabelPrintService.
  Future<bool> printFromTemplate(String escposContent) async {
    if (!isConnected) {
      print('❌ Not connected to printer');
      return false;
    }
    
    try {
      print('📄 Sending ESC/POS commands...');
      
      // Convert to bytes
      Uint8List bytes = Uint8List.fromList(escposContent.codeUnits);
      
      // Send to printer
      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('✅ ESC/POS commands sent successfully');
      return true;
    } catch (e) {
      print('❌ Error printing ESC/POS: $e');
      return false;
    }
  }
  
  // ============================================================================
  // TEST PRINT METHODS
  // ============================================================================
  
  /// Smart test print - auto detect printer type
  /// 
  /// Function ini akan otomatis detect printer type dan print test label
  /// yang sesuai (TSPL untuk TSC, ESC/POS untuk thermal).
  Future<bool> testPrintSmart() async {
    if (!isConnected) {
      print('❌ Not connected');
      return false;
    }
    
    if (isTSCPrinter) {
      return await _testPrintTSC();
    } else {
      return await _testPrintESCPOS();
    }
  }
  
  /// Test print untuk TSC printer
  /// 
  /// Prints a simple test label dengan:
  /// - Header "TEST PRINT"
  /// - Separator lines
  /// - Current date/time
  /// - Footer text
  Future<bool> _testPrintTSC() async {
    print('🧪 Testing TSC printer...');
    
    StringBuffer tspl = StringBuffer();
    
    // Setup
    tspl.writeln('SIZE 58 mm, 50 mm');
    tspl.writeln('GAP 3 mm, 0 mm');
    tspl.writeln('DENSITY 8');
    tspl.writeln('SPEED 3');
    tspl.writeln('DIRECTION 0');
    tspl.writeln('CLS');
    
    // Content
    tspl.writeln('TEXT 100,20,"4",0,2,2,"TEST PRINT"');
    tspl.writeln('BAR 10,70,440,2');
    tspl.writeln('TEXT 50,80,"3",0,1,1,"TSC Printer OK!"');
    
    DateTime now = DateTime.now();
    String dateTime = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';
    tspl.writeln('TEXT 50,120,"2",0,1,1,"$dateTime"');
    
    tspl.writeln('TEXT 50,160,"2",0,1,1,"T-Connect Industrial"');
    tspl.writeln('BAR 10,200,440,2');
    
    tspl.writeln('PRINT 1');
    
    return await printRawTSPL(tspl.toString());
  }
  
  /// Test print untuk ESC/POS printer
  /// 
  /// Prints a simple test receipt dengan:
  /// - Header "TEST PRINT"
  /// - Current date/time
  /// - Footer text
  /// - Paper cut command
  Future<bool> _testPrintESCPOS() async {
    print('🧪 Testing ESC/POS printer...');
    
    StringBuffer test = StringBuffer();
    
    test.write('\x1B\x40'); // Init
    test.write('\x1B\x61\x01'); // Center
    test.write('\x1B\x21\x30'); // Double size
    test.writeln('TEST PRINT');
    test.write('\x1B\x21\x00'); // Normal
    test.writeln('ESC/POS Printer OK!');
    test.writeln('${DateTime.now()}');
    test.writeln('T-Connect Industrial');
    test.write('\x1B\x64\x03'); // Feed
    test.write('\x1D\x56\x00'); // Cut
    
    return await printFromTemplate(test.toString());
  }
  
  /// Print test label (for manual testing)
  /// 
  /// Alias untuk testPrintSmart() atau test specific printer type.
  /// 
  /// Parameters:
  /// - isTSC: force TSC test (true) atau ESC/POS test (false)
  Future<bool> printTestLabel({bool isTSC = false}) async {
    if (isTSC) {
      return await _testPrintTSC();
    } else {
      return await _testPrintESCPOS();
    }
  }
  
  // ============================================================================
  // PRINTER MAINTENANCE
  // ============================================================================
  
  /// Calibrate TSC printer sensor
  /// 
  /// Function ini mengirim SELFTEST command ke TSC printer untuk
  /// kalibrasi sensor (gap sensor atau black mark sensor).
  /// 
  /// Printer akan:
  /// 1. Feed beberapa label untuk detect gap/mark
  /// 2. Save settings ke memory
  /// 3. Return ke ready state
  /// 
  /// ⚠️ Pastikan ada label di printer saat calibrate!
  Future<bool> calibrateTSC() async {
    if (!isConnected) return false;
    
    try {
      print('🔧 Starting TSC calibration...');
      
      // Send calibration command
      String calibCmd = 'SELFTEST\r\n';
      Uint8List bytes = Uint8List.fromList(utf8.encode(calibCmd));
      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      
      print('✅ Calibration command sent');
      return true;
    } catch (e) {
      print('❌ Calibration error: $e');
      return false;
    }
  }
  
  /// Get printer status (for TSC)
  /// 
  /// Mengirim status inquiry command ke TSC printer.
  /// Response akan diterima via Bluetooth stream (belum di-handle di function ini).
  Future<bool> getTSCStatus() async {
    if (!isConnected) return false;
    
    try {
      String statusCmd = '<ESC>!?\r\n';
      Uint8List bytes = Uint8List.fromList(utf8.encode(statusCmd));
      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      return true;
    } catch (e) {
      print('Error getting status: $e');
      return false;
    }
  }
}