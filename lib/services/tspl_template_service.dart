import '../models/label_template_model.dart';
import 'database_helper.dart';
import 'label_print_service.dart';  

/// ⚠️ DEPRECATED: Service ini sudah tidak dipakai
/// Gunakan LabelPrintService.renderTemplateToText() langsung
class PrintTemplateService {
  
  /// ✅ MAIN METHOD: Generate print command based on printer type
  static Future<dynamic> generateFromTemplate({
    required Map<String, dynamic> data,
    String? templateId,
  }) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // ✅ Get template dari database
      LabelTemplate? template;
      if (templateId != null) {
        template = await dbHelper.getLabelTemplateById(templateId);
      } else {
        template = await dbHelper.getActiveLabelTemplate();
      }
      
      if (template == null) {
        throw Exception('❌ No active template found!');
      }
      
      print('\n📝 ═══════════════════════════════════════════════════');
      print('🖨️  GENERATING PRINT COMMAND');
      print('   Template: ${template.name}');
      print('   Printer: ${template.printerType}');
      print('   Size: ${template.width}×${template.height}mm');
      print('   Elements: ${template.elements.length}');
      print('═══════════════════════════════════════════════════');
      
      // ✅ CRITICAL FIX: Redirect ke LabelPrintService (unified generator)
      print('✅ Redirecting to LabelPrintService.renderTemplateToText()');
      
      final result = LabelPrintService.renderTemplateToText(template, data);
      
      print('✅ Generation complete via LabelPrintService');
      print('═══════════════════════════════════════════════════\n');
      
      return result;
      
    } catch (e, stackTrace) {
      print('\n❌ ERROR GENERATING PRINT COMMAND: $e');
      print(stackTrace);
      rethrow;
    }
  }
  
  /// Format helpers (kept for backward compatibility)
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

// ✅ BACKWARD COMPATIBILITY: Alias untuk code lama
class TSPLTemplateService {
  @Deprecated('Use LabelPrintService.renderTemplateToText() instead')
  static Future<dynamic> generateFromTemplate({
    required Map<String, dynamic> data,
    String? templateId,
  }) {
    return PrintTemplateService.generateFromTemplate(
      data: data,
      templateId: templateId,
    );
  }
  
  static String formatDate(DateTime date) => PrintTemplateService.formatDate(date);
  static String formatTime(DateTime date) => PrintTemplateService.formatTime(date);
  static String formatCurrency(int amount) => PrintTemplateService.formatCurrency(amount);
}