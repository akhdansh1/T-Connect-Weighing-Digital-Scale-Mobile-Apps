import 'package:flutter/material.dart';

class NumpadDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String unit;

  const NumpadDialog({
    Key? key,
    required this.title,
    this.initialValue = '',
    this.unit = 'kg',
  }) : super(key: key);

  @override
  State<NumpadDialog> createState() => _NumpadDialogState();
}

class _NumpadDialogState extends State<NumpadDialog> {
  String displayValue = '';

  @override
  void initState() {
    super.initState();
    displayValue = widget.initialValue;
  }

  void _onNumberTap(String number) {
    setState(() {
      // Cegah multiple decimal point
      if (number == '.' && displayValue.contains('.')) {
        return;
      }
      displayValue += number;
    });
  }

  void _onClear() {
    setState(() {
      displayValue = '';
    });
  }

  void _onOk() {
    if (displayValue.isEmpty) {
      Navigator.pop(context, null);
    } else {
      Navigator.pop(context, displayValue);
    }
  }

  Widget _buildNumButton(String text, {bool isZero = false}) {
    return Expanded(
      flex: isZero ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _onNumberTap(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.black87,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: Colors.black87,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Display Screen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    displayValue.isEmpty ? '0.000' : displayValue,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: displayValue.isEmpty ? Colors.grey[400] : Colors.black87,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.unit,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Numpad Grid
            Column(
              children: [
                // Row 1: 7 8 9
                Row(
                  children: [
                    _buildNumButton('7'),
                    _buildNumButton('8'),
                    _buildNumButton('9'),
                  ],
                ),

                // Row 2: 4 5 6
                Row(
                  children: [
                    _buildNumButton('4'),
                    _buildNumButton('5'),
                    _buildNumButton('6'),
                  ],
                ),

                // Row 3: 1 2 3
                Row(
                  children: [
                    _buildNumButton('1'),
                    _buildNumButton('2'),
                    _buildNumButton('3'),
                  ],
                ),

                // Row 4: 0 . CE
                Row(
                  children: [
                    _buildNumButton('0', isZero: true),
                    _buildNumButton('.'),
                    _buildActionButton('CE', _onClear, color: Colors.orange[100]),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 5: Back & OK
                Row(
                  children: [
                    _buildActionButton('Back', () => Navigator.pop(context), 
                      color: Colors.red[100]),
                    _buildActionButton('OK', _onOk, 
                      color: Colors.green[100]),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ FUNGSI HELPER untuk show dialog dengan animasi
Future<String?> showNumpadDialog({
  required BuildContext context,
  required String title,
  String initialValue = '',
  String unit = 'kg',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => NumpadDialog(
      title: title,
      initialValue: initialValue,
      unit: unit,
    ),
  );
}