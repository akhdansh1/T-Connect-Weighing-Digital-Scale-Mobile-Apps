// lib/widgets/manual_input_dialog.dart

import 'package:flutter/material.dart';
import '../models/label_template_model.dart';

class ManualInputDialog extends StatefulWidget {
  final LabelTemplate template;
  final Map<String, dynamic> initialData;

  const ManualInputDialog({
    Key? key,
    required this.template,
    this.initialData = const {},
  }) : super(key: key);

  @override
  State<ManualInputDialog> createState() => _ManualInputDialogState();
}

class _ManualInputDialogState extends State<ManualInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  late Map<String, dynamic> _inputData;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _inputData = Map.from(widget.initialData);
    _initControllers();
  }

  void _initControllers() {
    // Get all unique variables dari template
    final variables = widget.template.elements.map((e) => e.variable).toSet();
    
    // Buat controller untuk setiap variable yang perlu input manual
    for (var variable in variables) {
      final field = LabelFields.allFields.firstWhere(
        (f) => f.variable == variable,
        orElse: () => AvailableField(
          variable: variable,
          label: variable,
          category: 'Lainnya',
          icon: Icons.text_fields,
          type: FieldType.manual,
        ),
      );
      
      // Hanya buat controller untuk field manual atau static yang bisa diedit
      if (field.type == FieldType.manual || 
          (field.type == FieldType.static && !_isAutoField(variable))) {
        _controllers[variable] = TextEditingController(
          text: _inputData[variable]?.toString() ?? '',
        );
      }
    }
  }

  bool _isAutoField(String variable) {
    // Field yang auto-generate, tidak perlu input manual
    const autoFields = [
      'TANGGAL', 'WAKTU', 'TANGGAL_LENGKAP',
      'BERAT', 'UNIT', 'BERAT_KG',
      'TOTAL_HARGA',
    ];
    return autoFields.contains(variable);
  }

  String _getFieldLabel(String variable) {
    final field = LabelFields.allFields.firstWhere(
      (f) => f.variable == variable,
      orElse: () => AvailableField(
        variable: variable,
        label: variable,
        category: 'Lainnya',
        icon: Icons.text_fields,
      ),
    );
    return field.label;
  }

  IconData _getFieldIcon(String variable) {
    final field = LabelFields.allFields.firstWhere(
      (f) => f.variable == variable,
      orElse: () => AvailableField(
        variable: variable,
        label: variable,
        category: 'Lainnya',
        icon: Icons.text_fields,
      ),
    );
    return field.icon;
  }

  bool _isRequired(String variable) {
    // Field wajib diisi
    const requiredFields = ['NAMA_BARANG', 'OPERATOR'];
    return requiredFields.contains(variable);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kumpulkan semua data
    final result = <String, dynamic>{};
    
    for (var entry in _controllers.entries) {
      result[entry.key] = entry.value.text.trim();
    }

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers.isEmpty) {
      return AlertDialog(
        title: const Text('Input Data'),
        content: const Text(
          'Template ini tidak memiliki field yang perlu diisi manual.\n\n'
          'Semua data akan diambil dari timbangan secara otomatis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, <String, dynamic>{}),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Input Data Manual',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Isi data yang diperlukan sebelum print',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Data timbangan (berat, tanggal) akan diambil otomatis',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Input fields
                    ..._controllers.entries.map((entry) {
                      final variable = entry.key;
                      final controller = entry.value;
                      final isRequired = _isRequired(variable);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: _getFieldLabel(variable),
                            hintText: 'Masukkan ${_getFieldLabel(variable).toLowerCase()}',
                            prefixIcon: Icon(_getFieldIcon(variable)),
                            border: const OutlineInputBorder(),
                            suffixIcon: isRequired
                                ? const Icon(Icons.star, size: 12, color: Colors.red)
                                : null,
                          ),
                          validator: (value) {
                            if (isRequired && (value == null || value.trim().isEmpty)) {
                              return '${_getFieldLabel(variable)} wajib diisi';
                            }
                            return null;
                          },
                          maxLines: variable == 'KETERANGAN' ? 3 : 1,
                          keyboardType: variable == 'HARGA_PER_KG'
                              ? TextInputType.number
                              : TextInputType.text,
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 8),

                    // Required note
                    if (_controllers.keys.any(_isRequired))
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'Field wajib diisi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _onSubmit,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Lanjut ke Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function untuk show dialog
Future<Map<String, dynamic>?> showManualInputDialog(
  BuildContext context,
  LabelTemplate template, {
  Map<String, dynamic>? initialData,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ManualInputDialog(
      template: template,
      initialData: initialData ?? {},
    ),
  );
}