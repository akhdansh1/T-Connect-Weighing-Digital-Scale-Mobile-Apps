import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../bluetooth_printer_helper.dart';
import '../models/printer_type.dart';
import 'tspl_debug_page.dart';

class PrinterTestWidget extends StatefulWidget {
  const PrinterTestWidget({Key? key}) : super(key: key);

  @override
  State<PrinterTestWidget> createState() => _PrinterTestWidgetState();
}

class _PrinterTestWidgetState extends State<PrinterTestWidget> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isPrinting = false;
  String _status = 'Not connected';
  
  final BluetoothPrinterHelper _printerHelper = BluetoothPrinterHelper();

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
  }

  Future<void> _loadPairedDevices() async {
    setState(() => _isScanning = true);
    
    try {
      final bluetooth = FlutterBluetoothSerial.instance;
      final devices = await bluetooth.getBondedDevices();
      
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading devices: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _connectPrinter() async {
    if (_selectedDevice == null) {
      _showSnackBar('Please select a printer first', Colors.orange);
      return;
    }

    setState(() {
      _isConnecting = true;
      _status = 'Connecting to ${_selectedDevice!.name}...';
    });

    try {
      final connected = await _printerHelper.connect(
        _selectedDevice!.address,
        printerName: _selectedDevice!.name,
      );

      if (connected) {
        // Detect printer type
        final config = PrinterConfig.fromDeviceName(_selectedDevice!.name ?? '');
        
        setState(() {
          _status = 'Connected to ${_selectedDevice!.name}\nType: ${config.typeName}';
          _isConnecting = false;
        });
        
        _showSnackBar('✓ Connected: ${config.typeName}', Colors.green);
      } else {
        setState(() {
          _status = 'Failed to connect';
          _isConnecting = false;
        });
        _showSnackBar('Connection failed', Colors.red);
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isConnecting = false;
      });
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _disconnectPrinter() async {
    await _printerHelper.disconnect();
    setState(() {
      _status = 'Disconnected';
    });
    _showSnackBar('Disconnected', Colors.blue);
  }

  Future<void> _testPrint() async {
    if (!_printerHelper.isConnected) {
      _showSnackBar('Please connect to printer first', Colors.orange);
      return;
    }

    setState(() {
      _isPrinting = true;
      _status = 'Sending test print...';
    });

    try {
      final success = await _printerHelper.testPrintSmart();

      setState(() {
        _isPrinting = false;
        _status = success 
          ? 'Test print sent successfully ✓' 
          : 'Test print failed ✗';
      });

      _showSnackBar(
        success ? '✓ Test print sent' : '✗ Test print failed',
        success ? Colors.green : Colors.red,
      );
    } catch (e) {
      setState(() {
        _isPrinting = false;
        _status = 'Print error: $e';
      });
      _showSnackBar('Print error: $e', Colors.red);
    }
  }

  Future<void> _testTSPLCommand() async {
    if (!_printerHelper.isConnected) {
      _showSnackBar('Please connect to printer first', Colors.orange);
      return;
    }

    setState(() {
      _isPrinting = true;
      _status = 'Sending TSPL test...';
    });

    // Simple TSPL test
    String testContent = '''T-CONNECT TIMBANGAN
================================
Test Print
Date: 11/11/2025
Time: 10:30:00
================================
Material: Barang Test
Weight: 100.50 KG
================================
Terima Kasih''';

    try {
      final success = await _printerHelper.printTSCLabel(
        testContent,
        labelWidth: 72.0,
        labelHeight: 50.0,
      );

      setState(() {
        _isPrinting = false;
        _status = success 
          ? 'TSPL test sent successfully ✓' 
          : 'TSPL test failed ✗';
      });

      _showSnackBar(
        success ? '✓ TSPL test sent' : '✗ TSPL test failed',
        success ? Colors.green : Colors.red,
      );
    } catch (e) {
      setState(() {
        _isPrinting = false;
        _status = 'TSPL error: $e';
      });
      _showSnackBar('TSPL error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Test & Debug'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _printerHelper.isConnected 
                ? Colors.green[50] 
                : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _printerHelper.isConnected 
                        ? Icons.check_circle 
                        : Icons.error_outline,
                      size: 48,
                      color: _printerHelper.isConnected 
                        ? Colors.green 
                        : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Printer Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Printer:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _isScanning ? null : _loadPairedDevices,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isScanning)
                      const Center(child: CircularProgressIndicator())
                    else if (_devices.isEmpty)
                      const Text(
                        'No paired devices. Please pair printer in Bluetooth settings.',
                        style: TextStyle(color: Colors.orange),
                      )
                    else
                      DropdownButton<BluetoothDevice>(
                        value: _selectedDevice,
                        isExpanded: true,
                        hint: const Text('Choose printer...'),
                        items: _devices.map((device) {
                          return DropdownMenuItem(
                            value: device,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  device.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (device) {
                          setState(() => _selectedDevice = device);
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Connection Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isConnecting || _printerHelper.isConnected) 
                      ? null 
                      : _connectPrinter,
                    icon: _isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bluetooth_connected),
                    label: const Text('Connect'),
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
                    onPressed: _printerHelper.isConnected 
                      ? _disconnectPrinter 
                      : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Test Print Buttons
            const Text(
              'Test Print:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: (_isPrinting || !_printerHelper.isConnected) 
                ? null 
                : _testPrint,
              icon: _isPrinting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.print),
              label: const Text('Auto-Detect Test Print'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: (_isPrinting || !_printerHelper.isConnected) 
                ? null 
                : _testTSPLCommand,
              icon: _isPrinting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.label),
              label: const Text('TSPL Command Test (TSC)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 8),  // ← Line 177 (sudah ada)
            
            // ✅✅✅ TAMBAHKAN KODE BARU DI SINI (SETELAH LINE 177) ✅✅✅
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TSPLDebugPage(),
                  ),
                );
              },
              icon: const Icon(Icons.code),
              label: const Text('Open TSPL Debug Viewer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tips
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '💡 Tips:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. Pastikan printer sudah di-calibrate (tekan FEED saat power on)',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '2. Cek ukuran label di code sesuai label fisik',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '3. Lihat console log untuk debug detail',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _printerHelper.disconnect();
    super.dispose();
  }
}