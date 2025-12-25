import 'package:flutter/material.dart';
import '../models/paper_presets.dart';

class TemplateSettingsDialog extends StatefulWidget {
  final String currentPrinterType;
  final String currentPaperSize;
  final Function(String printerType, String paperSize, double width, double height) onApply;

  const TemplateSettingsDialog({
    Key? key,
    required this.currentPrinterType,
    required this.currentPaperSize,
    required this.onApply,
  }) : super(key: key);

  @override
  State<TemplateSettingsDialog> createState() => _TemplateSettingsDialogState();
}

class _TemplateSettingsDialogState extends State<TemplateSettingsDialog> {
  late String _selectedPrinterType;
  late String _selectedPaperSize;
  late PaperPreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPrinterType = widget.currentPrinterType;
    _selectedPaperSize = widget.currentPaperSize;
    _selectedPreset = PaperPresets.getPreset(_selectedPaperSize);
  }

  List<PaperPreset> get _availablePresets {
    return PaperPresets.getPresetsByType(_selectedPrinterType);
  }

  void _onPrinterTypeChanged(String? newType) {
    if (newType == null) return;
    
    setState(() {
      _selectedPrinterType = newType;
      
      // Auto-select first preset of new printer type
      final presets = _availablePresets;
      if (presets.isNotEmpty) {
        _selectedPreset = presets[0];
        _selectedPaperSize = _selectedPreset!.name;
      }
    });
  }

  void _onPaperSizeChanged(PaperPreset? preset) {
    if (preset == null) return;
    
    setState(() {
      _selectedPreset = preset;
      _selectedPaperSize = preset.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Text('Template Settings'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== PRINTER TYPE SELECTION ==========
            const Text(
              'Printer Type:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.label, color: Colors.purple[700], size: 20),
                  const SizedBox(width: 8),
                  const Text('TSC Label Printer'),
                ],
              ),
              subtitle: const Text(
                'Untuk label sticker (TSC 244 Pro, dll)',
                style: TextStyle(fontSize: 11),
              ),
              value: 'TSC',
              groupValue: _selectedPrinterType,
              onChanged: _onPrinterTypeChanged,
            ),
            
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Text('ESC/POS Thermal'),
                ],
              ),
              subtitle: const Text(
                'Untuk struk thermal (58mm, 80mm)',
                style: TextStyle(fontSize: 11),
              ),
              value: 'ESCPOS',
              groupValue: _selectedPrinterType,
              onChanged: _onPrinterTypeChanged,
            ),
            
            const Divider(height: 24),
            
            // ========== PAPER SIZE SELECTION ==========
            const Text(
              'Paper Size:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            
            ..._availablePresets.map((preset) {
              final isRecommended = preset.name == '58x50' || preset.name == '58-receipt';
              
              return RadioListTile<PaperPreset>(
                title: Row(
                  children: [
                    Text(
                      preset.displayName,
                      style: TextStyle(
                        fontWeight: isRecommended ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  preset.description,
                  style: const TextStyle(fontSize: 11),
                ),
                value: preset,
                groupValue: _selectedPreset,
                onChanged: _onPaperSizeChanged,
              );
            }).toList(),
            
            const SizedBox(height: 12),
            
            // ========== PREVIEW INFO ==========
            if (_selectedPreset != null)
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
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Preview Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Size: ${_selectedPreset!.width} × ${_selectedPreset!.height} mm',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Type: ${_selectedPreset!.printerType}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _selectedPreset == null
              ? null
              : () {
                  widget.onApply(
                    _selectedPrinterType,
                    _selectedPaperSize,
                    _selectedPreset!.width,
                    _selectedPreset!.height,
                  );
                  Navigator.pop(context);
                },
          icon: const Icon(Icons.check),
          label: const Text('Apply'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}