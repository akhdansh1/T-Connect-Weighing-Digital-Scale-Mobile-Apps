import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan printer settings ke persistent storage
/// Sehingga user tidak perlu set ulang setiap kali buka app
class PrinterPersistenceService {
  static const String _keyLastPrinter = 'last_connected_printer';
  static const String _keyPrinterHistory = 'printer_history';
  static const String _keyAutoDetect = 'auto_detect_enabled';
  
  // ============================================================================
  // SAVE & LOAD LAST PRINTER
  // ============================================================================
  
  /// Save printer yang terakhir digunakan
  static Future<void> saveLastPrinter({
    required String printerName,
    required String printerModel,
    required String printerAddress,
    required String detectedType,
    required String detectedPaperType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final data = {
      'name': printerName,
      'model': printerModel,
      'address': printerAddress,
      'type': detectedType,
      'paperType': detectedPaperType,
      'lastUsed': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_keyLastPrinter, jsonEncode(data));
    
    print('💾 Saved last printer: $printerName ($detectedType)');
  }
  
  /// Load printer yang terakhir digunakan
  static Future<Map<String, dynamic>?> getLastPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyLastPrinter);
    
    if (jsonStr == null) return null;
    
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      print('📥 Loaded last printer: ${data['name']}');
      return data;
    } catch (e) {
      print('❌ Error loading last printer: $e');
      return null;
    }
  }
  
  // ============================================================================
  // PRINTER HISTORY
  // ============================================================================
  
  /// Save ke history (untuk quick selection)
  static Future<void> addToHistory({
    required String printerName,
    required String printerModel,
    required String printerAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyPrinterHistory);
    
    List<Map<String, dynamic>> history = [];
    
    if (jsonStr != null) {
      try {
        final decoded = jsonDecode(jsonStr) as List;
        history = decoded.map((e) => e as Map<String, dynamic>).toList();
      } catch (e) {
        print('⚠️ Error loading history: $e');
      }
    }
    
    // Remove duplicate (same address)
    history.removeWhere((item) => item['address'] == printerAddress);
    
    // Add to front
    history.insert(0, {
      'name': printerName,
      'model': printerModel,
      'address': printerAddress,
      'lastUsed': DateTime.now().toIso8601String(),
    });
    
    // Keep only last 5 printers
    if (history.length > 5) {
      history = history.take(5).toList();
    }
    
    await prefs.setString(_keyPrinterHistory, jsonEncode(history));
    
    print('📝 Added to history: $printerName (total: ${history.length})');
  }
  
  /// Get printer history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyPrinterHistory);
    
    if (jsonStr == null) return [];
    
    try {
      final decoded = jsonDecode(jsonStr) as List;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('❌ Error loading history: $e');
      return [];
    }
  }
  
  // ============================================================================
  // AUTO-DETECT SETTING
  // ============================================================================
  
  /// Save user preference untuk auto-detect
  static Future<void> setAutoDetectEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDetect, enabled);
    print('⚙️ Auto-detect ${enabled ? "enabled" : "disabled"}');
  }
  
  /// Get auto-detect preference (default: true)
  static Future<bool> isAutoDetectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoDetect) ?? true;
  }
  
  // ============================================================================
  // CLEAR DATA
  // ============================================================================
  
  /// Clear all printer data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastPrinter);
    await prefs.remove(_keyPrinterHistory);
    print('🗑️ Cleared all printer data');
  }
}