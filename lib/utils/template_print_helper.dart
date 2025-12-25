// lib/utils/template_print_helper.dart
// ✅ VERSION: COMPLETE FIX - Full field mapping + proper data structure

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weighing_ticket.dart';
import '../models/transaction_receipt.dart';
import '../services/database_helper.dart';
import '../models/label_template_model.dart';
import '../services/label_print_service.dart';
import '../bluetooth_printer_helper.dart';

/// Helper class untuk print weighing ticket menggunakan template
class TemplatePrintHelper {
  
  // ============================================================================
  // ✅ FIX 1: COMPLETE DATA MAPPING UNTUK WEIGHING TICKET
  // ============================================================================
  
  /// Print weighing ticket using active template
  static Future<bool> printWeighingTicket({
    required BuildContext context,
    required WeighingTicket ticket,
    bool showPreview = false,
  }) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // Load active template
      final template = await dbHelper.getActiveLabelTemplate();
      if (template == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No active label template found.\nPlease create a template in Label Designer.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }

      // Show preview if requested
      if (showPreview && context.mounted) {
        final confirmed = await _showWeighingPreview(context, ticket, template);
        if (confirmed != true) return false;
      }

      // ✅ PREPARE COMPLETE DATA WITH ALL POSSIBLE FIELDS
      final printData = _prepareWeighingTicketData(ticket);

      // Execute print
      return await _executePrint(context, template, printData);
      
    } catch (e) {
      print('❌ Print error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      return false;
    }
  }

  // ============================================================================
  // ✅ FIX 2: COMPLETE DATA PREPARATION FUNCTION
  // ============================================================================
  
  /// Prepare complete data untuk weighing ticket
  static Map<String, dynamic> _prepareWeighingTicketData(WeighingTicket ticket) {
    
    // Calculate weights
    double grossWeight = ticket.firstWeight ?? ticket.netWeight;
    double tareWeight = ticket.tareWeight ?? 0.0;
    double netWeight = ticket.netWeight;
    
    return {
      // ========== HEADER & COMPANY INFO ==========
      'HEADER': 'T-CONNECT',
      'NAMA_PERUSAHAAN': 'PT TRISURYA SOLUSINDO UTAMA',
      'ALAMAT': 'Jl. Raya Citarik, Jatireja, Kec. Cikarang Tim., Kabupaten Bekasi, Jawa Barat 17530',
      'ALAMAT_PERUSAHAAN': 'Jl. Raya Citarik, Jatireja, Kec. Cikarang Tim., Kabupaten Bekasi, Jawa Barat 17530',
      'TELEPON': '(021) 56927540',
      'TELEPON_PERUSAHAAN': '(021) 56927540',
      
      // ========== TICKET/BATCH INFO ==========
      'NOMOR_BATCH': ticket.batchNumber ?? ticket.ticketNumber,
      'NOMOR_TICKET': ticket.ticketNumber,
      'BATCH': ticket.batchNumber ?? ticket.ticketNumber,
      'TICKET': ticket.ticketNumber,
      
      // ========== DATE & TIME ==========
      'TANGGAL': _formatDate(ticket.weighingDate),
      'WAKTU': _formatTime(ticket.weighingDate),
      'DATE': _formatDate(ticket.weighingDate),
      'TIME': _formatTime(ticket.weighingDate),
      'TANGGAL_WAKTU': '${_formatDate(ticket.weighingDate)} ${_formatTime(ticket.weighingDate)}',
      
      // ========== WEIGHT DATA (MULTIPLE FORMATS) ==========
      'BERAT': netWeight.toStringAsFixed(2),
      'WEIGHT': netWeight.toStringAsFixed(2),
      'NET': netWeight.toStringAsFixed(2),
      'NET_WEIGHT': netWeight.toStringAsFixed(2),
      'BERAT_NET': netWeight.toStringAsFixed(2),
      
      'GROSS': grossWeight.toStringAsFixed(2),
      'GROSS_WEIGHT': grossWeight.toStringAsFixed(2),
      'BERAT_GROSS': grossWeight.toStringAsFixed(2),
      
      'TARE': tareWeight.toStringAsFixed(2),
      'TARE_WEIGHT': tareWeight.toStringAsFixed(2),
      'BERAT_TARE': tareWeight.toStringAsFixed(2),
      
      // ========== UNIT ==========
      'UNIT': ticket.unit,
      'SATUAN': ticket.unit,
      
      // ========== WEIGHT WITH UNIT (FORMATTED) ==========
      'BERAT_UNIT': '${netWeight.toStringAsFixed(2)} ${ticket.unit}',
      'NET_UNIT': '${netWeight.toStringAsFixed(2)} ${ticket.unit}',
      'GROSS_UNIT': '${grossWeight.toStringAsFixed(2)} ${ticket.unit}',
      'TARE_UNIT': '${tareWeight.toStringAsFixed(2)} ${ticket.unit}',
      
      // ========== GTN (Gross-Tare-Net) ==========
      'GTN': 'G: ${grossWeight.toStringAsFixed(2)} T: ${tareWeight.toStringAsFixed(2)} N: ${netWeight.toStringAsFixed(2)}',
      'GROSS_TARE_NET': 'Gross: ${grossWeight.toStringAsFixed(2)} | Tare: ${tareWeight.toStringAsFixed(2)} | Net: ${netWeight.toStringAsFixed(2)}',
      
      // ========== MATERIAL INFO ==========
      'NAMA_BARANG': ticket.materialName,
      'MATERIAL': ticket.materialName,
      'BARANG': ticket.materialName,
      'KATEGORI': ticket.category,
      'CATEGORY': ticket.category,
      
      // ========== OPERATOR ==========
      'OPERATOR': ticket.operatorName,
      'OP': ticket.operatorName,
      'PETUGAS': ticket.operatorName,
      
      // ========== VEHICLE (if available) ==========
      'VEHICLE': ticket.vehicleNumber ?? '-',
      'KENDARAAN': ticket.vehicleNumber ?? '-',
      'NOMOR_KENDARAAN': ticket.vehicleNumber ?? '-',
      'PLAT': ticket.vehicleNumber ?? '-',
      'DRIVER': ticket.driverName ?? '-',
      'SUPIR': ticket.driverName ?? '-',
      'DRIVER_PHONE': ticket.driverPhone ?? '-',
      
      // ========== SUPPLIER INFO ==========
      'SUPPLIER': ticket.supplierName ?? '-',
      'SUPPLIER_CODE': ticket.supplierCode ?? '-',
      'PEMASOK': ticket.supplierName ?? '-',
      
      // ========== PO/DO INFO ==========
      'PO_NUMBER': ticket.poNumber ?? '-',
      'DO_NUMBER': ticket.doNumber ?? '-',
      'NOMOR_PO': ticket.poNumber ?? '-',
      'NOMOR_DO': ticket.doNumber ?? '-',
      
      // ========== NOTES/REMARKS ==========
      'KETERANGAN': ticket.remarks ?? '-',
      'NOTES': ticket.remarks ?? '-',
      'REMARKS': ticket.remarks ?? '-',
      'CATATAN': ticket.remarks ?? '-',

      // ========== GRADE (QC) ==========
'GRADE': ticket.grade ?? 'Standard',
'GRADE_LABEL': 'Grade   : ${ticket.grade ?? '-'}',
      
      // ========== STATUS ==========
      'STATUS': ticket.status,
      
      // ========== SEPARATOR & FOOTER ==========
      'GARIS_PEMISAH': '================================',
      'SEPARATOR': '--------------------------------',
      'FOOTER': 'T-CONNECT',
      'THANK_YOU': ' info@trisuryasolusindo.com',
    };
  }

  // ============================================================================
  // ✅ FIX 3: COMPLETE DATA MAPPING UNTUK TRANSACTION RECEIPT
  // ============================================================================
  
  /// Print transaction receipt using active template
  static Future<bool> printTransactionReceipt({
    required BuildContext context,
    required TransactionReceipt receipt,
    bool showPreview = false,
  }) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // Load active template
      final template = await dbHelper.getActiveLabelTemplate();
      if (template == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No active label template found.\nPlease create a template in Label Designer.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }

      // Show preview if requested
      if (showPreview && context.mounted) {
        final confirmed = await _showReceiptPreview(context, receipt, template);
        if (confirmed != true) return false;
      }

      // ✅ PREPARE COMPLETE DATA
      final printData = _prepareTransactionReceiptData(receipt);

      // Execute print
      return await _executePrint(context, template, printData);
      
    } catch (e) {
      print('❌ Print error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      return false;
    }
  }

  /// Prepare complete data untuk transaction receipt
  static Map<String, dynamic> _prepareTransactionReceiptData(TransactionReceipt receipt) {
  return {
    // ========== HEADER & COMPANY INFO ==========
    'HEADER': 'T-CONNECT',
    'QUALITY_CONTROL': 'Quality Control',
    'QC_REPORT': 'Quality Control',
    'NAMA_PERUSAHAAN': 'PT TRISURYA SOLUSINDO UTAMA',
    'COMPANY_NAME': 'PT TRISURYA SOLUSINDO UTAMA',
    'ALAMAT': 'Jl. Raya Citarik, Jatireja, Kec. Cikarang Tim., Kabupaten Bekasi, Jawa Barat 17530',
    'ALAMAT_PERUSAHAAN': 'Jl. Raya Citarik, Jatireja, Kec. Cikarang Tim., Kabupaten Bekasi, Jawa Barat 17530',
    'TELEPON': ' (021) 56927540',
    'TELEPON_PERUSAHAAN': ' (021) 56927540',
    
    // ========== RECEIPT/BATCH INFO ==========
    'NOMOR_RESI': receipt.receiptNumber,
    'NOMOR_TICKET': receipt.receiptNumber,
    'RECEIPT': receipt.receiptNumber,
    'NO_RESI': receipt.receiptNumber,
    'TICKET': receipt.receiptNumber,
    
    'BATCH': receipt.batchNumber ?? receipt.receiptNumber,
    'NOMOR_BATCH': receipt.batchNumber ?? receipt.receiptNumber,
    'BATCH_NUMBER': receipt.batchNumber ?? receipt.receiptNumber,
    
    // ========== DATE & TIME ==========
    'TANGGAL': _formatDate(receipt.transactionDate),
    'WAKTU': _formatTime(receipt.transactionDate),
    'DATE': _formatDate(receipt.transactionDate),
    'TIME': _formatTime(receipt.transactionDate),
    'TANGGAL_WAKTU': '${_formatDate(receipt.transactionDate)} ${_formatTime(receipt.transactionDate)}',
    'DATE_TIME': '${_formatDate(receipt.transactionDate)} ${_formatTime(receipt.transactionDate)}',
    
    // ========== OPERATOR ==========
    'OPERATOR': receipt.operatorName,
    'PETUGAS': receipt.operatorName,
    'OP': receipt.operatorName,
    'OPERATOR_NAME': receipt.operatorName,
    
    // ========== MATERIAL INFO ==========
    'MATERIAL': receipt.materialName,
    'NAMA_BARANG': receipt.materialName,
    'BARANG': receipt.materialName,
    'MATERIAL_NAME': receipt.materialName,
    
    'KATEGORI': receipt.category,
    'CATEGORY': receipt.category,
    
    'GRADE': receipt.grade,
    'GRADE_LABEL': 'Grade   : ${receipt.grade}',
    
    // ========== WEIGHT DATA (MULTIPLE FORMATS) ==========
    // Net Weight
    'NET': receipt.netWeight.toStringAsFixed(2),
    'NET_WEIGHT': receipt.netWeight.toStringAsFixed(2),
    'BERAT_NET': receipt.netWeight.toStringAsFixed(2),
    'BERAT': receipt.netWeight.toStringAsFixed(2),
    'WEIGHT': receipt.netWeight.toStringAsFixed(2),
    'NET_WT': receipt.netWeight.toStringAsFixed(2),
    
    // Gross Weight
    'GROSS': receipt.grossWeight.toStringAsFixed(2),
    'GROSS_WEIGHT': receipt.grossWeight.toStringAsFixed(2),
    'BERAT_GROSS': receipt.grossWeight.toStringAsFixed(2),
    'GROSS_WT': receipt.grossWeight.toStringAsFixed(2),
    
    // Tare Weight
    'TARE': receipt.tareWeight.toStringAsFixed(2),
    'TARE_WEIGHT': receipt.tareWeight.toStringAsFixed(2),
    'BERAT_TARE': receipt.tareWeight.toStringAsFixed(2),
    'TARE_WT': receipt.tareWeight.toStringAsFixed(2),
    
    // ========== UNIT ==========
    'UNIT': receipt.unit,
    'SATUAN': receipt.unit,
    
    // ========== WEIGHT WITH UNIT (FORMATTED) ==========
    'NET_UNIT': '${receipt.netWeight.toStringAsFixed(2)} ${receipt.unit}',
    'GROSS_UNIT': '${receipt.grossWeight.toStringAsFixed(2)} ${receipt.unit}',
    'TARE_UNIT': '${receipt.tareWeight.toStringAsFixed(2)} ${receipt.unit}',
    'BERAT_UNIT': '${receipt.netWeight.toStringAsFixed(2)} ${receipt.unit}',
    
    // ========== GTN (Gross-Tare-Net) ==========
    'GTN': 'G: ${receipt.grossWeight.toStringAsFixed(2)} T: ${receipt.tareWeight.toStringAsFixed(2)} N: ${receipt.netWeight.toStringAsFixed(2)}',
    'GROSS_TARE_NET': 'Gross: ${receipt.grossWeight.toStringAsFixed(2)} | Tare: ${receipt.tareWeight.toStringAsFixed(2)} | Net: ${receipt.netWeight.toStringAsFixed(2)}',
    
    // ========== FORMATTED WEIGHT DISPLAY (QC Report Style) ==========
    'GROSS_WT_LABEL': 'GROSS WT : ${receipt.grossWeight.toStringAsFixed(2)} ${receipt.unit}',
    'TARE_WT_LABEL': 'TARE WT  : ${receipt.tareWeight.toStringAsFixed(2)} ${receipt.unit}',
    'NET_WT_LABEL': 'NET WT   : ${receipt.netWeight.toStringAsFixed(2)} ${receipt.unit}',
    
    // ========== CUSTOMER INFO (if applicable) ==========
    'CUSTOMER': receipt.customerName ?? '-',
    'PELANGGAN': receipt.customerName ?? '-',
    'NAMA_CUSTOMER': receipt.customerName ?? '-',
    
    // ========== PRICING (Optional - bisa disembunyikan di QC Report) ==========
    'HARGA_PER_KG': _formatCurrency(receipt.pricePerKg),
    'PRICE_PER_KG': _formatCurrency(receipt.pricePerKg),
    'HARGA_SATUAN': _formatCurrency(receipt.pricePerKg),
    
    'TOTAL_HARGA': _formatCurrency(receipt.totalAmount),
    'TOTAL': _formatCurrency(receipt.totalAmount),
    'TOTAL_AMOUNT': _formatCurrency(receipt.totalAmount),
    'GRAND_TOTAL': _formatCurrency(receipt.totalAmount),
    
    // ========== STATUS ==========
    'STATUS': receipt.status,
    
    // ========== QR CODE DATA ==========
    'QR_CODE': receipt.receiptNumber, // Data untuk QR Code
    'QR_DATA': '${receipt.receiptNumber}|${receipt.materialName}|${receipt.netWeight}',
    
    // ========== SEPARATOR & FOOTER ==========
    'GARIS_PEMISAH': '================================',
    'SEPARATOR': '--------------------------------',
    'FOOTER': ' info@trisuryasolusindo.com',
    'THANK_YOU': 'Thank You',
    
    // ========== ADDITIONAL INFO (dari field baru TransactionReceipt) ==========
    'SUPPLIER': receipt.supplierName ?? '-',
    'SUPPLIER_CODE': receipt.supplierCode ?? '-',
    'VEHICLE': receipt.vehicleNumber ?? '-',
    'KENDARAAN': receipt.vehicleNumber ?? '-',
    'DRIVER': receipt.driverName ?? '-',
    'SUPIR': receipt.driverName ?? '-',
    'DO_NUMBER': receipt.doNumber ?? '-',
    'PO_NUMBER': receipt.poNumber ?? '-',
  };
}

  // ============================================================================
  // CORE PRINT EXECUTION
  // ============================================================================
  
  static Future<bool> _executePrint(
    BuildContext context,
    LabelTemplate template,
    Map<String, dynamic> printData,
  ) async {
    // Get default printer
    final prefs = await SharedPreferences.getInstance();
    final printerAddress = prefs.getString('defaultPrinterAddress');
    final printerName = prefs.getString('defaultPrinterName');

    if (printerAddress == null || printerAddress.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No default printer set.\nPlease set default printer in Settings.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    // Detect printer type
    final printerNameUpper = (printerName ?? '').toUpperCase();
    final isTSC = printerNameUpper.contains('TSC') || 
                   printerNameUpper.contains('ALPHA') || 
                   printerNameUpper.contains('TTP') || 
                   printerNameUpper.contains('PS-6') ||
                   printerNameUpper.contains('244') ||
                   printerNameUpper.contains('24') || 
                   printerNameUpper.contains('2R');

                   // ✅ TAMBAHKAN INI - FORCE CORRECT PRINTER TYPE
  if (isTSC && template.printerType != 'TSC') {
  print('⚠️  WARNING: Printer is TSC but template is ${template.printerType}');
  print('   Template elements: ${template.elements.length}');
  
  if (template.elements.isEmpty) {
    throw Exception(
      '❌ Template "${template.name}" has no elements!\n'
      'Please open Visual Label Designer and add fields to your template.'
    );
  }
  
  // Don't force change - let the template decide
  print('   Using template as-is (${template.elements.length} elements)');
  
} else if (!isTSC && template.printerType != 'ESCPOS') {
  print('⚠️  WARNING: Printer is ESC/POS but template is ${template.printerType}');
  print('   Template elements: ${template.elements.length}');
  
  if (template.elements.isEmpty) {
    throw Exception(
      '❌ Template "${template.name}" has no elements!\n'
      'Please open Visual Label Designer and add fields to your template.'
    );
  }
  
  print('   Using template as-is (${template.elements.length} elements)');
}

// ✅ DEBUG: Print template info
print('\n📋 Template Info:');
print('   Name: ${template.name}');
print('   Printer Type: ${template.printerType}');
print('   Size: ${template.width}x${template.height}mm');
print('   Elements: ${template.elements.length}');
print('   Active: ${template.isActive}');

if (template.elements.isEmpty) {
  throw Exception(
    '❌ Template "${template.name}" is empty!\n\n'
    'Please:\n'
    '1. Open Visual Label Designer\n'
    '2. Add fields from Field Library\n'
    '3. Click Save button\n'
    '4. Try printing again'
  );
}

    print('\n🖨️ Printer Info:');
    print('   Name: $printerName');
    print('   Type: ${isTSC ? "TSC (TSPL)" : "Thermal (ESC/POS)"}');
    print('   Address: $printerAddress');
    
    print('\n📊 Data to print:');
    printData.forEach((key, value) {
      print('   $key = $value');
    });

    // Generate content
    final content = LabelPrintService.renderTemplateToText(template, printData);

    // Show preview dialog
    bool? confirmed;
    
    if (context.mounted) {
      confirmed = await _showCommandPreview(context, content, printerName!, isTSC);
    }

    if (confirmed != true) return false;

    // Show sending dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sending to printer...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Connect and print
    final printerHelper = BluetoothPrinterHelper();
    final connected = await printerHelper.connect(printerAddress, printerName: printerName);

    if (context.mounted) {
      Navigator.pop(context); // Close sending dialog
    }

    if (!connected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to connect to $printerName'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    // Send to printer
    bool success = false;
if (isTSC) {
  // ✅ CRITICAL: Gunakan printRawTSPL() langsung, JANGAN printTSCLabel()!
  success = await printerHelper.printRawTSPL(content);
  print('✅ Sent via printRawTSPL() - no double parsing');
} else {
  success = await printerHelper.printFromTemplate(content);
  print('✅ Sent via printFromTemplate() for ESC/POS');
}

    await printerHelper.disconnect();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? '✓ Print sent to $printerName' 
              : '✗ Print may have failed'
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
          duration: Duration(seconds: success ? 2 : 3),
        ),
      );
    }

    return success;
  }

  // ============================================================================
  // PREVIEW DIALOGS
  // ============================================================================
  
  static Future<bool?> _showWeighingPreview(
    BuildContext context,
    WeighingTicket ticket,
    LabelTemplate template,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.preview, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Print Preview'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template: ${template.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${template.width}×${template.height} ${template.unit}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              _buildPreviewRow('Ticket', ticket.ticketNumber),
              _buildPreviewRow('Date', _formatDate(ticket.weighingDate)),
              _buildPreviewRow('Time', _formatTime(ticket.weighingDate)),
              _buildPreviewRow('Operator', ticket.operatorName),
              const Divider(),
              _buildPreviewRow('Material', ticket.materialName),
              _buildPreviewRow('Category', ticket.category),
              const Divider(),
              _buildPreviewRow('Net', '${ticket.netWeight.toStringAsFixed(2)} ${ticket.unit}', bold: true),
              _buildPreviewRow('Gross', '${(ticket.firstWeight ?? ticket.netWeight).toStringAsFixed(2)} ${ticket.unit}'),
              _buildPreviewRow('Tare', '${(ticket.tareWeight ?? 0.0).toStringAsFixed(2)} ${ticket.unit}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> _showReceiptPreview(
    BuildContext context,
    TransactionReceipt receipt,
    LabelTemplate template,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.preview, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Print Preview'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template: ${template.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${template.width}×${template.height} ${template.unit}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              _buildPreviewRow('Receipt', receipt.receiptNumber),
              _buildPreviewRow('Customer', receipt.customerName ?? '-'),
              const Divider(),
              _buildPreviewRow('Material', receipt.materialName),
              _buildPreviewRow('Weight', '${receipt.netWeight.toStringAsFixed(2)} ${receipt.unit}'),
              _buildPreviewRow('Price/kg', 'Rp ${_formatCurrency(receipt.pricePerKg)}'),
              const Divider(),
              _buildPreviewRow('TOTAL', 'Rp ${_formatCurrency(receipt.totalAmount)}', bold: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> _showCommandPreview(
    BuildContext context,
    String content,
    String printerName,
    bool isTSC,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.code, color: Colors.purple[700]),
              const SizedBox(width: 8),
              const Text('Command Preview'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isTSC ? Colors.purple[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Printer: $printerName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Type: ${isTSC ? "TSC Label (TSPL)" : "Thermal (ESC/POS)"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isTSC ? Colors.purple[700] : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        color: Colors.greenAccent,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Lines: ${content.split('\n').length} | Size: ${content.length} bytes',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.print),
              label: const Text('Send to Printer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================
  
  static Widget _buildPreviewRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}