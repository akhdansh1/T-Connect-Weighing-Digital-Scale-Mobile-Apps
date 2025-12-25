import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'dart:convert';

class TestTSCPrintPage extends StatefulWidget {
  const TestTSCPrintPage({Key? key}) : super(key: key);

  @override
  State<TestTSCPrintPage> createState() => _TestTSCPrintPageState();
}

class _TestTSCPrintPageState extends State<TestTSCPrintPage> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  BluetoothConnection? _connection;
  bool _isScanning = false;
  bool _isConnected = false;
  String _status = 'Not connected';
  
  @override
  void initState() {
    super.initState();
    _loadDevices();
  }
  
  Future<void> _loadDevices() async {
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
        _status = 'Error: $e';
        _isScanning = false;
      });
    }
  }
  
  Future<void> _connect() async {
    if (_selectedDevice == null) {
      _showSnackBar('Pilih printer dulu!');
      return;
    }
    
    try {
      _connection = await BluetoothConnection.toAddress(_selectedDevice!.address);
      
      setState(() {
        _isConnected = true;
        _status = 'Connected to ${_selectedDevice!.name}';
      });
      
      _showSnackBar('✓ Connected!');
    } catch (e) {
      _showSnackBar('Connection failed: $e');
    }
  }
  
  Future<void> _disconnect() async {
    await _connection?.close();
    setState(() {
      _isConnected = false;
      _status = 'Disconnected';
    });
  }
  
  Future<void> _testPrint() async {
    if (!_isConnected) {
      _showSnackBar('Connect ke printer dulu!');
      return;
    }
    
    try {
      // ✅ TSPL COMMAND PALING SIMPLE
      String tspl = '''SIZE 58 mm, 50 mm
GAP 3 mm, 0 mm
DIRECTION 0
SPEED 3
DENSITY 8
CLS
TEXT 100,100,"5",0,2,2,"TEST"
TEXT 100,200,"3",0,1,1,"TSC OK!"
PRINT 1
''';
      
      print('📄 Sending TSPL:');
      print(tspl);
      
      // Convert to bytes
      Uint8List bytes = Uint8List.fromList(utf8.encode(tspl));
      
      // Send
      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      
      // Wait
      await Future.delayed(const Duration(milliseconds: 500));
      
      _showSnackBar('✓ Test print sent! Cek printer...');
      
    } catch (e) {
      _showSnackBar('Print error: $e');
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test TSC Printer'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              color: _isConnected ? Colors.green[50] : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.error_outline,
                      size: 48,
                      color: _isConnected ? Colors.green : Colors.grey,
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
            
            // Printer selection
            const Text(
              'Select Printer:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (_isScanning)
              const Center(child: CircularProgressIndicator())
            else if (_devices.isEmpty)
              const Text('No paired devices')
            else
              DropdownButton<BluetoothDevice>(
                value: _selectedDevice,
                isExpanded: true,
                hint: const Text('Choose printer...'),
                items: _devices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text(device.name ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (device) {
                  setState(() => _selectedDevice = device);
                },
              ),
            
            const SizedBox(height: 16),
            
            // Connection buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !_isConnected ? _connect : null,
                    icon: const Icon(Icons.bluetooth_connected),
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
                    onPressed: _isConnected ? _disconnect : null,
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
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Test print button
            ElevatedButton.icon(
              onPressed: _isConnected ? _testPrint : null,
              icon: const Icon(Icons.print, size: 32),
              label: const Text(
                'TEST PRINT',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '💡 Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('1. Pilih printer TSC dari dropdown'),
                    Text('2. Tekan tombol Connect'),
                    Text('3. Tekan tombol TEST PRINT'),
                    Text('4. Cek apakah label keluar'),
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
    _connection?.dispose();
    super.dispose();
  }
}