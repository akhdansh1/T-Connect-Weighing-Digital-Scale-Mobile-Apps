import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/weighing_ticket.dart';
import '../services/label_print_service.dart';
import '../bluetooth_printer_helper.dart';

class TSPLDebugPage extends StatefulWidget {
  final WeighingTicket? testTicket;
  
  const TSPLDebugPage({Key? key, this.testTicket}) : super(key: key);

  @override
  State<TSPLDebugPage> createState() => _TSPLDebugPageState();
}

class _TSPLDebugPageState extends State<TSPLDebugPage> {
  String _generatedTSPL = '';
  String _status = 'Ready';
  bool _isGenerating = false;
  
  final BluetoothPrinterHelper _printerHelper = BluetoothPrinterHelper();

  @override
  void initState() {
    super.initState();
    if (widget.testTicket != null) {
      _generateFromTicket();
    } else {
      _generateSample();
    }
  }

  void _generateSample() {
    setState(() {
      _isGenerating = true;
      _status = 'Generating sample TSPL...';
    });

    // Generate sample TSPL
    String tspl = LabelPrintService.generateSimpleTSPLLabel(
      berat: 125.50,
      unit: 'KG',
      namaBarang: 'Besi Bekas',
      kategori: 'Scrap Metal',
      operator: 'John Doe',
    );

    setState(() {
      _generatedTSPL = tspl;
      _status = 'Sample TSPL generated (${tspl.split('\n').length} lines)';
      _isGenerating = false;
    });
  }

  void _generateFromTicket() {
    if (widget.testTicket == null) return;
    
    setState(() {
      _isGenerating = true;
      _status = 'Generating TSPL from ticket...';
    });

    final ticket = widget.testTicket!;
    
    String tspl = LabelPrintService.generateSimpleTSPLLabel(
      berat: ticket.netWeight,
      unit: ticket.unit,
      namaBarang: ticket.materialName,
      kategori: ticket.category,
      operator: ticket.operatorName,
    );

    setState(() {
      _generatedTSPL = tspl;
      _status = 'TSPL generated from ${ticket.ticketNumber} (${tspl.split('\n').length} lines)';
      _isGenerating = false;
    });
  }

  Future<void> _testPrint() async {
    if (_generatedTSPL.isEmpty) {
      _showMessage('No TSPL to print!', Colors.red);
      return;
    }

    // Check if connected
    if (!_printerHelper.isConnected) {
      _showMessage('Please connect to printer first', Colors.orange);
      return;
    }

    setState(() {
      _status = 'Sending to printer...';
    });

    try {
      bool success = await _printerHelper.printRawTSPL(_generatedTSPL);
      
      setState(() {
        _status = success ? '✅ Print SUCCESS!' : '❌ Print FAILED!';
      });

      _showMessage(
        success ? '✅ Print sent successfully' : '❌ Print failed',
        success ? Colors.green : Colors.red,
      );
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
      _showMessage('Error: $e', Colors.red);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedTSPL));
    _showMessage('✓ TSPL copied to clipboard', Colors.blue);
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TSPL Debug Viewer'),
        backgroundColor: Colors.purple[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateSample,
            tooltip: 'Regenerate sample',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _status.contains('SUCCESS') 
              ? Colors.green[100]
              : _status.contains('FAILED') || _status.contains('Error')
                ? Colors.red[100]
                : Colors.blue[50],
            child: Row(
              children: [
                Icon(
                  _isGenerating 
                    ? Icons.hourglass_empty
                    : _status.contains('SUCCESS')
                      ? Icons.check_circle
                      : _status.contains('FAILED')
                        ? Icons.error
                        : Icons.info,
                  color: _status.contains('SUCCESS')
                    ? Colors.green[700]
                    : _status.contains('FAILED')
                      ? Colors.red[700]
                      : Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _status.contains('SUCCESS')
                        ? Colors.green[900]
                        : _status.contains('FAILED')
                          ? Colors.red[900]
                          : Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TSPL Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[300]!),
              ),
              child: _isGenerating
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: SelectableText(
                      _generatedTSPL.isEmpty 
                        ? 'No TSPL generated yet' 
                        : _generatedTSPL,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Colors.greenAccent,
                        height: 1.5,
                      ),
                    ),
                  ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy TSPL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generatedTSPL.isEmpty ? null : _testPrint,
                        icon: const Icon(Icons.print),
                        label: const Text('Test Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[700]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[900], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lines: ${_generatedTSPL.split('\n').length} | '
                          'Size: ${_generatedTSPL.length} bytes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _printerHelper.disconnect();
    super.dispose();
  }
}