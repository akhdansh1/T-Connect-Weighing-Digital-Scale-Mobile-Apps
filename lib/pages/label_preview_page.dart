// lib/pages/label_preview_page.dart
// ✅ FIXED VERSION - Proper preview for both TSC and ESC/POS printers

import 'package:flutter/material.dart';
import '../models/label_template_model.dart';
import '../services/label_print_service.dart';

class LabelPreviewPage extends StatelessWidget {
  final LabelTemplate template;
  final Map<String, dynamic> data;
  final VoidCallback? onPrint;

  const LabelPreviewPage({
    Key? key,
    required this.template,
    required this.data,
    this.onPrint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ DETECT PRINTER TYPE
    final isESCPOS = template.printerType == 'ESCPOS';
    final isTSC = template.printerType == 'TSC';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Label'),
        backgroundColor: Colors.blue[700],
        actions: [
          // Show printer type indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Chip(
              avatar: Icon(
                isESCPOS ? Icons.receipt_long : Icons.label,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                template.printerTypeDisplay,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: isESCPOS ? Colors.blue[600] : Colors.purple[600],
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ========== INFO BANNER ==========
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isESCPOS ? Colors.blue[50] : Colors.purple[50],
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isESCPOS ? Colors.blue[700] : Colors.purple[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview Hasil Print',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isESCPOS ? Colors.blue[900] : Colors.purple[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isESCPOS
                            ? 'Format thermal receipt (${template.paperSize})'
                            : 'Label sticker ${template.width}×${template.height} mm',
                        style: TextStyle(
                          fontSize: 12,
                          color: isESCPOS ? Colors.blue[700] : Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ========== PREVIEW AREA ==========
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ========== TSC VISUAL PREVIEW ==========
                      if (isTSC) ...[
                        _buildTSCVisualPreview(),
                        const SizedBox(height: 24),
                        Text(
                          'Visual Preview (Label Sticker)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ========== TEXT PREVIEW (BOTH PRINTERS) ==========
                      _buildTextPreview(isESCPOS),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ========== FOOTER BUTTONS ==========
          _buildFooterButtons(context),
        ],
      ),
    );
  }

  // ============================================================================
  // TSC VISUAL PREVIEW (Label dengan positioned elements)
  // ============================================================================
  
  Widget _buildTSCVisualPreview() {
    return Container(
      width: template.width * 3, // Scale up 3x for better visibility
      height: template.height * 3,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: template.elements.map((element) {
            final displayValue = LabelTemplateService.getValueForVariable(
              element.variable,
              data,
            );

            return Positioned(
              left: element.x * 3, // Scale coordinates
              top: element.y * 3,
              child: Container(
                width: element.width * 3,
                height: element.height * 3,
                padding: const EdgeInsets.all(4),
                child: Align(
                  alignment: _getAlignment(element.textAlign),
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: element.fontSize * 2.5, // Scale font
                      fontWeight: element.fontWeight,
                    ),
                    textAlign: element.textAlign,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================================
  // TEXT PREVIEW (Thermal printer format - both TSC and ESC/POS)
  // ============================================================================
  
  Widget _buildTextPreview(bool isESCPOS) {
    return Container(
      width: isESCPOS ? 350 : 400,
      constraints: BoxConstraints(
        maxWidth: isESCPOS ? 350 : 450,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isESCPOS ? Colors.blue[300]! : Colors.purple[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.print,
                color: isESCPOS ? Colors.blue[700] : Colors.purple[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isESCPOS ? 'Format Thermal Receipt' : 'Format Print Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Content preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              LabelPrintService.renderTemplateToText(template, data),
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: isESCPOS ? 11 : 10,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Footer info
          const SizedBox(height: 12),
          Text(
            'Paper: ${template.paperSize} | Size: ${template.width}×${template.height}mm',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // FOOTER BUTTONS
  // ============================================================================
  
  Widget _buildFooterButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onPrint?.call();
              },
              icon: const Icon(Icons.print),
              label: const Text('Print ke Printer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  Alignment _getAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}

/// ============================================================================
/// HELPER FUNCTION - Show Preview Dialog
/// ============================================================================

Future<void> showLabelPreview(
  BuildContext context,
  LabelTemplate template,
  Map<String, dynamic> data, {
  VoidCallback? onPrint,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LabelPreviewPage(
        template: template,
        data: data,
        onPrint: onPrint,
      ),
    ),
  );
}