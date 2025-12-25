import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter/material.dart';

/// Helper class untuk manage USB Serial connection ke timbangan
///
/// Cara kerja mirip dengan Bluetooth Serial, tapi lewat USB OTG
class UsbSerialHelper {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;  // ✅ FIX: Uint8List, bukan String
 
  /// Stream controller untuk data yang diterima
  final StreamController<String> _dataController = StreamController<String>.broadcast();
 
  /// Public stream untuk listen data dari timbangan
  Stream<String> get dataStream => _dataController.stream;
 
  /// Check apakah sedang terkoneksi
  bool get isConnected => _port != null;
 
  // ═══════════════════════════════════════════════════════════════════
  // SCAN & LIST USB DEVICES
  // ═══════════════════════════════════════════════════════════════════
 
  /// Get list of available USB devices
  ///
  /// Returns: List of USB devices yang terdeteksi
  static Future<List<UsbDevice>> getAvailableDevices() async {
    try {
      debugPrint('🔍 Scanning for USB devices...');
      List<UsbDevice> devices = await UsbSerial.listDevices();
     
      debugPrint('✅ Found ${devices.length} USB device(s)');
      for (var device in devices) {
        debugPrint('   - ${device.productName ?? "Unknown"} (${device.vid}:${device.pid})');
      }
     
      return devices;
    } catch (e) {
      debugPrint('❌ Error scanning USB devices: $e');
      return [];
    }
  }
 
  // ═══════════════════════════════════════════════════════════════════
  // CONNECTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════
 
  /// Connect ke USB device
  ///
  /// Parameters:
  /// - device: UsbDevice yang mau di-connect
  ///
  /// Returns: true jika berhasil connect
  Future<bool> connect(UsbDevice device) async {
    try {
      debugPrint('🔌 Connecting to USB device: ${device.productName}');
     
      // Create USB port
      _port = await device.create();
     
      if (_port == null) {
        debugPrint('❌ Failed to create USB port');
        return false;
      }
     
      // Open port
      bool openResult = await _port!.open();
      if (!openResult) {
        debugPrint('❌ Failed to open USB port');
        return false;
      }
     
      // Set baud rate (sesuaikan dengan timbangan)
      // Biasanya: 9600, 19200, 38400, 57600, 115200
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        9600,  // Baud rate - SESUAIKAN dengan timbangan kamu
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
     
      debugPrint('✅ USB port opened successfully');
     
      // Start listening to data
      _startListening();
     
      return true;
     
    } catch (e) {
      debugPrint('❌ Error connecting to USB device: $e');
      return false;
    }
  }
 
  /// Start listening to data from USB
  void _startListening() {
    if (_port == null) return;
   
    debugPrint('👂 Start listening to USB data...');
   
    // ✅ FIX: Listen ke Uint8List, lalu convert ke String
    _subscription = _port!.inputStream?.listen(
      (Uint8List data) {
        try {
          // Convert bytes to string
          String received = String.fromCharCodes(data);
         
          debugPrint('📥 USB Data received: $received');
         
          // Kirim ke stream
          _dataController.add(received);
         
        } catch (e) {
          debugPrint('❌ Error parsing USB data: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ USB stream error: $error');
      },
      onDone: () {
        debugPrint('⚠️ USB stream closed');
      },
    );
  }
 
  /// Disconnect dari USB device
  Future<void> disconnect() async {
    try {
      debugPrint('🔌 Disconnecting USB device...');
     
      // Cancel subscription
      await _subscription?.cancel();
      _subscription = null;
     
      // Close port
      await _port?.close();
      _port = null;
     
      debugPrint('✅ USB disconnected');
     
    } catch (e) {
      debugPrint('❌ Error disconnecting USB: $e');
    }
  }
 
  // ═══════════════════════════════════════════════════════════════════
  // SEND DATA (Kalau perlu kirim command ke timbangan)
  // ═══════════════════════════════════════════════════════════════════
 
  /// Send command ke timbangan via USB
  ///
  /// Parameters:
  /// - command: String command yang mau dikirim
  ///
  /// Example: sendCommand("TARE\r\n")
  Future<bool> sendCommand(String command) async {
    if (_port == null) {
      debugPrint('❌ USB not connected');
      return false;
    }
   
    try {
      debugPrint('📤 Sending USB command: $command');
     
      // Convert string to bytes
      Uint8List data = Uint8List.fromList(command.codeUnits);
     
      // Send data
      await _port!.write(data);
     
      debugPrint('✅ USB command sent');
      return true;
     
    } catch (e) {
      debugPrint('❌ Error sending USB command: $e');
      return false;
    }
  }
 
  // ═══════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════
 
  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _dataController.close();
    _port?.close();
  }
}