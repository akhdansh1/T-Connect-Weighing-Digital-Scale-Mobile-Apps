// lib/services/label_template_service.dart

import '../models/label_template_model.dart';
import 'database_helper.dart';

class LabelTemplateService {
  /// Get all templates from database
  static Future<List<LabelTemplate>> getAllTemplates() async {
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.readAllLabelTemplates();
  }

  /// Get active template
  static Future<LabelTemplate?> getActiveTemplate() async {
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.getActiveLabelTemplate();
  }

  /// Save template
  static Future<bool> saveTemplate(LabelTemplate template) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.createLabelTemplate(template);
      return true;
    } catch (e) {
      print('❌ Error saving template: $e');
      return false;
    }
  }

  /// Update template
  static Future<bool> updateTemplate(LabelTemplate template) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.updateLabelTemplate(template);
      return true;
    } catch (e) {
      print('❌ Error updating template: $e');
      return false;
    }
  }

  /// Delete template
  static Future<bool> deleteTemplate(String templateId) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteLabelTemplate(templateId);
      return true;
    } catch (e) {
      print('❌ Error deleting template: $e');
      return false;
    }
  }

  /// Set active template
  static Future<bool> setActiveTemplate(String templateId) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.setActiveLabelTemplate(templateId);
      return true;
    } catch (e) {
      print('❌ Error setting active template: $e');
      return false;
    }
  }

  /// Duplicate template
  static Future<LabelTemplate?> duplicateTemplate(String templateId, String newName) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      return await dbHelper.duplicateLabelTemplate(templateId, newName);
    } catch (e) {
      print('❌ Error duplicating template: $e');
      return null;
    }
  }

  /// Generate label content from template and data
  static String generateLabelContent(
    LabelTemplate template,
    Map<String, dynamic> data,
  ) {
    final buffer = StringBuffer();
    
    // Sort elements by Y position (top to bottom)
    final sortedElements = List<LabelElement>.from(template.elements)
      ..sort((a, b) => a.y.compareTo(b.y));
    
    // Group elements by row (tolerance: 15px)
    final rows = <List<LabelElement>>[];
    for (var element in sortedElements) {
      bool added = false;
      
      for (var row in rows) {
        if (row.isNotEmpty && (element.y - row.first.y).abs() < 15) {
          row.add(element);
          added = true;
          break;
        }
      }
      
      if (!added) {
        rows.add([element]);
      }
    }
    
    // Render each row
    for (var row in rows) {
      // Sort elements in row by X position (left to right)
      row.sort((a, b) => a.x.compareTo(b.x));
      
      if (row.length == 1) {
        // Single element
        final element = row.first;
        final value = _getValueForElement(element, data);
        
        buffer.writeln(value);
      } else {
        // Multiple elements - arrange horizontally
        final line = StringBuffer();
        for (int i = 0; i < row.length; i++) {
          final element = row[i];
          final value = _getValueForElement(element, data);
          
          line.write(value);
          
          // Add spacing between elements
          if (i < row.length - 1) {
            line.write('  '); // Double space as separator
          }
        }
        buffer.writeln(line.toString());
      }
    }
    
    return buffer.toString();
  }

  /// Get value for element from data
  static String _getValueForElement(LabelElement element, Map<String, dynamic> data) {
    // Check if there's data for this variable
    if (data.containsKey(element.variable)) {
      final value = data[element.variable];
      if (value != null) {
        return value.toString();
      }
    }
    
    // If no data, return default label
    return element.label;
  }

  /// Format double value
  static String formatDouble(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  /// Format currency
  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}