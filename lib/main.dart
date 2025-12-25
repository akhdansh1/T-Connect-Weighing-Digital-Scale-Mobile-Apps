import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'bluetooth_printer_helper.dart';
import 'services/database_helper.dart';
import 'pages/database_viewer_page.dart';
import 'utils/notification_helper.dart';
import 'pages/transaction_receipt_page.dart';
import 'utils/template_print_helper.dart';  
import 'pages/visual_label_designer_page.dart';
import 'industrial_dashboard.dart';
import 'models/weighing_ticket.dart';
import 'models/label_template_model.dart';
import 'services/label_print_service.dart';
import 'widgets/responsive_app_bar.dart';
import 'splash_screen.dart';
import 'widgets/numpad_dialog.dart';
import 'models/product_model.dart';
import 'pages/product_management_page.dart';
import 'models/client_model.dart';
import 'pages/client_management_page.dart';
import 'models/id_model.dart';
import 'pages/id_management_page.dart';
import 'models/supplier.dart';
import 'pages/supplier_management_page.dart';
import 'utils/usb_serial_helper.dart';

class LastWeighingState {
  final String currentWeight;
  final String netWeight;
  final String grossWeight;
  final String tareWeight;
  final String selectedUnit;
  final double taraValue;
  
  final bool isUnitWeightSet;
  final bool isSamplingMode;
  final double unitWeight;
  final int sampleCount;
  final int calculatedQuantity;
  
  final double lowThreshold;
  final double highThreshold;
  final String weightStatus;
  
  final int weighingCounter;
  final double totalWeightKg;
  
  final DateTime savedAt;
  
  LastWeighingState({
    required this.currentWeight,
    required this.netWeight,
    required this.grossWeight,
    required this.tareWeight,
    required this.selectedUnit,
    required this.taraValue,
    required this.isUnitWeightSet,
    required this.isSamplingMode,
    required this.unitWeight,
    required this.sampleCount,
    required this.calculatedQuantity,
    required this.lowThreshold,
    required this.highThreshold,
    required this.weightStatus,
    required this.weighingCounter,
    required this.totalWeightKg,
    required this.savedAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'currentWeight': currentWeight,
      'netWeight': netWeight,
      'grossWeight': grossWeight,
      'tareWeight': tareWeight,
      'selectedUnit': selectedUnit,
      'taraValue': taraValue,
      'isUnitWeightSet': isUnitWeightSet,
      'isSamplingMode': isSamplingMode,
      'unitWeight': unitWeight,
      'sampleCount': sampleCount,
      'calculatedQuantity': calculatedQuantity,
      'lowThreshold': lowThreshold,
      'highThreshold': highThreshold,
      'weightStatus': weightStatus,
      'weighingCounter': weighingCounter,
      'totalWeightKg': totalWeightKg,
      'savedAt': savedAt.toIso8601String(),
    };
  }
  
  factory LastWeighingState.fromJson(Map<String, dynamic> json) {
    return LastWeighingState(
      currentWeight: json['currentWeight'] ?? '0.0',
      netWeight: json['netWeight'] ?? '0.000',
      grossWeight: json['grossWeight'] ?? '0.000',
      tareWeight: json['tareWeight'] ?? '0.000',
      selectedUnit: json['selectedUnit'] ?? 'GRAM',
      taraValue: json['taraValue'] ?? 0.0,
      isUnitWeightSet: json['isUnitWeightSet'] ?? false,
      isSamplingMode: json['isSamplingMode'] ?? false,
      unitWeight: json['unitWeight'] ?? 0.0,
      sampleCount: json['sampleCount'] ?? 0,
      calculatedQuantity: json['calculatedQuantity'] ?? 0,
      lowThreshold: json['lowThreshold'] ?? 0.100,
      highThreshold: json['highThreshold'] ?? 50.0,
      weightStatus: json['weightStatus'] ?? 'OK',
      weighingCounter: json['weighingCounter'] ?? 0,
      totalWeightKg: json['totalWeightKg'] ?? 0.0,
      savedAt: DateTime.parse(json['savedAt']),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T-Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/dashboard': (context) => const BluetoothPage(),  // ✅ ADD THIS - Dashboard is actually BluetoothPage without forced connection
        '/bluetooth': (context) => const BluetoothPage(),
      },
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({Key? key}) : super(key: key);

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  
  BluetoothConnection? connection;
  bool isConnecting = false;
  bool _hasSkippedConnection = false;
  bool get isConnected {
  // ✅ ALLOW DEMO MODE: Always show weight display
  // User can work without connection now
  if (connectionType == 'bluetooth') {
    return connection != null && connection!.isConnected;
  } else if (connectionType == 'usb') {
    return _usbHelper != null && _usbHelper!.isConnected;
  }
  return false;  // Not connected, but still show UI
}

// ✅ ADD NEW GETTER: Check if truly connected (for data parsing)
bool get isActuallyConnected {
  if (connectionType == 'bluetooth') {
    return connection != null && connection!.isConnected;
  } else if (connectionType == 'usb') {
    return _usbHelper != null && _usbHelper!.isConnected;
  }
  return false;
}
  
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;

  UsbSerialHelper? _usbHelper;
  List<UsbDevice> usbDevices = [];
  UsbDevice? selectedUsbDevice;
  StreamSubscription<String>? _usbDataSubscription;

  String connectionType = 'bluetooth';
  
  String currentWeight = "0.0";
  String selectedUnit = "GRAM";
  List<String> historyData = [];
  List<String> rawDataLog = [];
  final ScrollController _scrollController = ScrollController();
  final dbHelper = DatabaseHelper.instance;
  bool showRawData = false;

  ProductModel? selectedProduct;
  ClientModel? selectedClient;
  IdModel? selectedId;
  Supplier? selectedSupplier;

  Timer? _saveTimer;
  
  final Map<int, TextEditingController> _fieldControllers = {};

  void _debouncedSaveCustomFields() {
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(milliseconds: 500), () {
    _saveCustomFields();
  });
}

  String connectionMode = 'continuous';
  String? defaultPrinterAddress;
  String? defaultPrinterName;

  bool isPrintEnabled = true;
  
  @override
void initState() {
  super.initState();
  _initBluetooth();
  _initUsb();
  _loadConnectionMode();
  _loadConnectionType();
  _loadDefaultPrinter();
  _loadPrintSetting();  
  _loadDataFromDatabase();
  _initializeCustomFields();
  _loadLastWeighingState();
  _initializeFieldControllers();
}

void _initializeFieldControllers() {
    _fieldControllers.clear();
    for (int i = 0; i < customFields.length; i++) {
      _fieldControllers[i] = TextEditingController(
        text: customFields[i]['value'] ?? ''
      );
    }
  }

  Future<void> _initUsb() async {
  try {
    _usbHelper = UsbSerialHelper();
    print('✅ USB Serial Helper initialized');
    
    // Auto-scan USB devices if user previously used USB
    if (connectionType == 'usb') {
      await _scanUsbDevices();
    }
  } catch (e) {
    print('❌ Error initializing USB: $e');
  }
}

Future<void> _scanUsbDevices() async {
  try {
    print('🔍 Scanning for USB devices...');
    List<UsbDevice> foundDevices = await UsbSerialHelper.getAvailableDevices();
    
    setState(() {
      usbDevices = foundDevices;
    });
    
    print('✅ Found ${usbDevices.length} USB device(s)');
  } catch (e) {
    print('❌ Error scanning USB devices: $e');
  }
}

Future<void> _loadConnectionType() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    connectionType = prefs.getString('connectionType') ?? 'bluetooth';
  });
  print('✅ Connection type loaded: $connectionType');
}

Future<void> _saveConnectionType(String type) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('connectionType', type);
  setState(() {
    connectionType = type;
  });
  print('✅ Connection type saved: $type');
}

Future<void> _connectToUsbDevice(UsbDevice device) async {
  if (isConnecting) return;
  
  setState(() {
    isConnecting = true;
  });

  try {
    print('🔌 Connecting to USB device: ${device.productName}');
    
    bool connected = await _usbHelper!.connect(device);
    
    setState(() {
      isConnecting = false;
    });
    
    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal terhubung ke USB device'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    setState(() {
      selectedUsbDevice = device;
      connectionType = 'usb';
      
      // ✅ NEW: Reset skip flag saat connect berhasil
      _hasSkippedConnection = false;
    });
    
    await _saveConnectionType('usb');
    
    print('✅ USB connected successfully');
    print('   _hasSkippedConnection: $_hasSkippedConnection');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Terhubung ke ${device.productName ?? "USB Device"} via USB'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // ✅ Listen to USB data stream
    _usbDataSubscription = _usbHelper!.dataStream.listen((String data) {
      if (!mounted) return;
      
      setState(() {
        String timestamp = DateTime.now().toString().substring(11, 19);
        rawDataLog.add('$timestamp: $data (USB)');
        if (rawDataLog.length > 100) {
          rawDataLog.removeAt(0);
        }
      });
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
      // Parse weight dari USB data
      _parseWeight(data);
    });
    
  } catch (e) {
    setState(() {
      isConnecting = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _loadLastWeighingState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('lastWeighingState');
    
    if (jsonString != null && jsonString.isNotEmpty) {
      Map<String, dynamic> json = jsonDecode(jsonString);
      LastWeighingState state = LastWeighingState.fromJson(json);
      
      Duration timeSinceLastSave = DateTime.now().difference(state.savedAt);
      if (timeSinceLastSave.inHours > 24) {
        print('⚠️ Last weighing state too old (${timeSinceLastSave.inHours}h), skipping restore');
        return;
      }
      
      setState(() {
        currentWeight = state.currentWeight;
        netWeight = state.netWeight;
        grossWeight = state.grossWeight;
        tareWeight = state.tareWeight;
        selectedUnit = state.selectedUnit;
        taraValue = state.taraValue;
        
        isUnitWeightSet = state.isUnitWeightSet;
        isSamplingMode = state.isSamplingMode;
        unitWeight = state.unitWeight;
        sampleCount = state.sampleCount;
        calculatedQuantity = state.calculatedQuantity;
        
        lowThreshold = state.lowThreshold;
        highThreshold = state.highThreshold;
        weightStatus = state.weightStatus;
        
        weighingCounter = state.weighingCounter;
        totalWeightKg = state.totalWeightKg;
      });
      
      print('✅ Last weighing state restored');
      print('   Weight: $currentWeight $selectedUnit');
      print('   Saved: ${state.savedAt}');
      print('   Age: ${timeSinceLastSave.inMinutes} minutes ago');
      
    } else {
      print('ℹ️ No saved weighing state found');
    }
    
  } catch (e) {
    print('❌ Error loading last weighing state: $e');
  }
}

Future<void> _saveLastWeighingState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    final state = LastWeighingState(
      currentWeight: currentWeight,
      netWeight: netWeight,
      grossWeight: grossWeight,
      tareWeight: tareWeight,
      selectedUnit: selectedUnit,
      taraValue: taraValue,
      isUnitWeightSet: isUnitWeightSet,
      isSamplingMode: isSamplingMode,
      unitWeight: unitWeight,
      sampleCount: sampleCount,
      calculatedQuantity: calculatedQuantity,
      lowThreshold: lowThreshold,
      highThreshold: highThreshold,
      weightStatus: weightStatus,
      weighingCounter: weighingCounter,
      totalWeightKg: totalWeightKg,
      savedAt: DateTime.now(),
    );
    
    String jsonString = jsonEncode(state.toJson());
    await prefs.setString('lastWeighingState', jsonString);
    
    print('✅ Last weighing state saved');
    print('   Weight: $currentWeight $selectedUnit');
    print('   Mode: ${isSamplingMode ? "Sample" : (isUnitWeightSet ? "Counting" : "Normal")}');
    
  } catch (e) {
    print('❌ Error saving last weighing state: $e');
  }
}

Future<void> _loadDataFromDatabase() async {
    print('📂 Loading data from SQLite...');
    
    try {
      await dbHelper.forceUpgradeToV10();
      print('✅ Database schema check completed');
    } catch (e) {
      print('⚠️ Schema upgrade error (might already be up-to-date): $e');
    }
    
    try {
      List<Map<String, dynamic>> dbBarang = await dbHelper.readAllBarang();
      setState(() {
        barangList = dbBarang.map((item) {
          return {
            'id': item['id'],
            'nama': item['nama'],
            'kategori': item['kategori'],
            'harga': item['harga'],
            'created': item['created_at'],
          };
        }).toList();
      });
      print('✅ Loaded ${barangList.length} barang');
    
      List<Map<String, dynamic>> dbResi = await dbHelper.readAllResi();
      setState(() {
        resiList = dbResi.map((item) {
          return {
            'id': item['id'],
            'nomor': item['nomor'],
            'tanggal': item['tanggal'],
            'barang': item['barang'],
            'kategori': item['kategori'],
            'berat': item['berat'],
            'unit': item['unit'],
            'beratKg': item['beratKg'],
            'hargaPerKg': item['hargaPerKg'],
            'totalHarga': item['totalHarga'],
          };
        }).toList();
      });
      print('✅ Loaded ${resiList.length} resi');
    
      List<Map<String, dynamic>> dbPengukuran = await dbHelper.readAllPengukuran();
      setState(() {
        historyMeasurements = dbPengukuran.map((item) {
          DateTime tanggal;
          try {
            tanggal = DateTime.parse(item['tanggal']);
          } catch (e) {
            print('⚠️ Error parsing date: ${item['tanggal']} - using current time');
            tanggal = DateTime.now();
          }
          
          return {
            'tanggal': tanggal, 
            'barang': item['barang'],
            'kategori': item['kategori'],
            'berat': item['berat'],
            'unit': item['unit'],
            'beratKg': item['beratKg'],
            'hargaTotal': item['hargaTotal'],
          };
        }).toList();
      });
      print('✅ Loaded ${historyMeasurements.length} pengukuran');
    
      await dbHelper.printAllData();
      
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        barangList = [];
        resiList = [];
        historyMeasurements = [];
      });
    }
  }

Future<void> _loadConnectionMode() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    connectionMode = prefs.getString('connectionMode') ?? 'continuous';
  });
}

Future<void> _loadDefaultPrinter() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    defaultPrinterAddress = prefs.getString('defaultPrinterAddress');
    defaultPrinterName = prefs.getString('defaultPrinterName');
  });
  
  if (defaultPrinterAddress != null) {
    print('✅ Default printer loaded: $defaultPrinterName ($defaultPrinterAddress)');
  }
}

Future<void> _loadPrintSetting() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    isPrintEnabled = prefs.getBool('isPrintEnabled') ?? true;
  });
  
  print('✅ Print setting loaded: ${isPrintEnabled ? "ENABLED" : "DISABLED"}');
}

Future<void> _savePrintSetting(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isPrintEnabled', enabled);
  
  setState(() {
    isPrintEnabled = enabled;
  });
  
  print('✅ Print setting saved: ${enabled ? "ENABLED" : "DISABLED"}');
}

Future<void> _saveCustomFields() async {
  final prefs = await SharedPreferences.getInstance();
  
  List<Map<String, dynamic>> fieldsToSave = customFields.map((field) {
    return {
      'label': field['label'],
      'value': field['value'],
    };
  }).toList();
  
  String jsonString = jsonEncode(fieldsToSave);
  await prefs.setString('customFields', jsonString);
  
  print('✅ Custom fields saved: $jsonString');
}

Future<void> _loadCustomFields() async {
  final prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('customFields');
  
  if (jsonString != null && jsonString.isNotEmpty) {
    try {
      List<dynamic> decoded = jsonDecode(jsonString);
      
      setState(() {
        customFields = decoded.map((item) {
          return {
            'label': item['label'] as String,
            'value': item['value'] as String,
          };
        }).toList();
      });
      
      print('✅ Custom fields loaded: ${customFields.length} fields');
      customFields.forEach((field) {
        print('   - ${field['label']}: "${field['value']}"');
      });
    } catch (e) {
      print('⚠️ Error loading custom fields: $e');
      setState(() {
        customFields = [
          {'label': 'Product', 'value': ''},
          {'label': 'Client', 'value': ''},
          {'label': 'ID', 'value': ''},
          {'label': 'Supplier', 'value': ''},
        ];
      });
    }
  } else {
    print('ℹ️ No saved custom fields, using default');
  }
}

Future<void> _setDefaultFields() async {
  final prefs = await SharedPreferences.getInstance();
  
  bool hasSetDefault = prefs.getBool('hasSetDefaultFields') ?? false;
  
  if (!hasSetDefault) {
    List<Map<String, dynamic>> defaultFields = [
      {'label': 'Product', 'value': ''},
      {'label': 'Batch Number', 'value': ''},
      {'label': 'Product Code', 'value': ''},
      {'label': 'Supplier', 'value': ''},
    ];
    
    String jsonString = jsonEncode(defaultFields);
    await prefs.setString('customFields', jsonString);
    await prefs.setBool('hasSetDefaultFields', true);
    
    print('✅ Default fields configuration saved!');
    print('   Fields: Product, Batch Number, Material Code, Supplier');
  }
}

Future<void> _initializeCustomFields() async {
  await _setDefaultFields();  
  await _loadCustomFields();  
  
  print('📋 Custom fields initialized');
  print('   Total fields: ${customFields.length}');
  customFields.forEach((field) {
    print('   - ${field['label']}: "${field['value']}"');
  });
}

Future<void> _clearDefaultPrinter() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('defaultPrinterAddress');
  await prefs.remove('defaultPrinterName');
  
  setState(() {
    defaultPrinterAddress = null;
    defaultPrinterName = null;
  });
  
  print('🗑️ Default printer cleared');
}
  
  double taraValue = 0.0;
  double preTareValue = 0.0;
  double calibrationFactor = 1.0; 
  bool isDisplayCleared = false;
  
  List<Map<String, dynamic>> barangList = [];
  Map<String, dynamic>? selectedBarang;
  
  List<Map<String, dynamic>> resiList = [];
  int resiCounter = 1;
  
  String dataMode = "manual";
  List<String> printLog = [];

  List<Map<String, dynamic>> historyMeasurements = [];

BluetoothPrinterHelper? printerHelper;

double unitWeight = 0.0;           
int calculatedQuantity = 0;        
bool isUnitWeightSet = false;      
bool isSamplingMode = false;       
int sampleCount = 0;               
double sampleTotalWeight = 0.0;    

String netWeight = "0.000";     
String grossWeight = "0.000";   
String tareWeight = "0.000";    

String weightStatus = "OK";     
double lowThreshold = 0.100;    
double highThreshold = 50.0;

int currentDecimalPlaces = 2;

int weighingCounter = 0;
double totalWeightKg = 0.0;

List<Map<String, String>> customFields = [
  {'label': 'Product', 'value': ''},
  {'label': 'Client', 'value': ''},
  {'label': 'ID', 'value': ''},
  {'label': 'Supplier', 'value': ''},
];

bool isStatisticalSession = false;  
int statisticalWeighingCount = 0;   
List<double> statisticalWeights = []; 
DateTime? statisticalSessionStart;  

final List<String> availableFieldOptions = [
  'Product',
  'Client',
  'ID',
  'Supplier',
  'Batch Number',
  'Product Code',
  'SKU',
  'Location',
  'Operator',
  'Notes',
  'Custom',
];

Future<void> _printResi(Map<String, dynamic> resi) async {
  try {
    final ticket = WeighingTicket(
      ticketNumber: resi['nomor'],
      weighingDate: DateTime.parse(resi['tanggal']),
      operatorCode: 'OP-001',
      operatorName: 'System',
      materialCode: 'MAT-001',
      materialName: resi['barang'],
      category: resi['kategori'],
      netWeight: double.parse(resi['berat'].toString()),
      unit: resi['unit'],
      status: 'Completed',
      createdAt: DateTime.parse(resi['tanggal']),
    );

    final success = await TemplatePrintHelper.printWeighingTicket(
      context: context,
      ticket: ticket,
      showPreview: true, 
    );

    if (success) {
      print('✅ Resi printed successfully with template: ${resi['nomor']}');
    } else {
      print('⚠️ Print cancelled by user');
    }

  } catch (e) {
    print('❌ Print error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

  Future<void> _initBluetooth() async {
    await _requestPermissions();
    _bluetoothState = await _bluetooth.state;
    
    _bluetooth.onStateChanged().listen((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    
    if (_bluetoothState == BluetoothState.STATE_ON) {
      _getPairedDevices();
    }
    
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> _getPairedDevices() async {
    try {
      List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
      setState(() {
        devices = bondedDevices;
      });
    } catch (e) {
      print('Error getting paired devices: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
  print('\n🔵 ═══════════════════════════════════════════════════');
  print('📱 BLUETOOTH CONNECTION ATTEMPT');
  print('   Device: ${device.name}');
  print('   Address: ${device.address}');
  print('   Current connectionType: $connectionType');
  print('═══════════════════════════════════════════════════\n');
  
  if (isConnecting) {
    print('⚠️ Already connecting, skip');
    return;
  }
  
  setState(() {
    isConnecting = true;
  });

  try {
    print('🔌 Connecting to ${device.address}...');
    connection = await BluetoothConnection.toAddress(device.address);
    
    print('✅ Connection established!');
    
    // ✅ FIX: Set connectionType to 'bluetooth' and save it
    setState(() {
      isConnecting = false;
      selectedDevice = device;
      connectionType = 'bluetooth';  // ✅ CRITICAL FIX!
      
      // ✅ NEW: Reset skip flag saat connect berhasil
      _hasSkippedConnection = false;
    });
    
    // ✅ FIX: Save to SharedPreferences
    await _saveConnectionType('bluetooth');
    
    print('\n🎯 CONNECTION STATE:');
    print('   selectedDevice: ${selectedDevice?.name}');
    print('   connectionType: $connectionType');
    print('   connection.isConnected: ${connection?.isConnected}');
    print('   isConnected getter: $isConnected');
    print('   _hasSkippedConnection: $_hasSkippedConnection');  // ✅ NEW DEBUG
    print('');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Terhubung ke ${device.name}\n'
            '📡 Mode: ${connectionMode == 'continuous' ? 'Real-time' : 'Manual'}'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // ✅ Setup listener based on connection mode
    if (connectionMode == 'continuous') {
      print('📊 Mode: CONTINUOUS (Real-time)');
      
      connection!.input!.listen((Uint8List data) {
        if (!mounted) return;
        
        String received = ascii.decode(data).trim();
        
        setState(() {
          String timestamp = DateTime.now().toString().substring(11, 19);
          rawDataLog.add('$timestamp: $received (CONTINUOUS MODE)');
          if (rawDataLog.length > 100) {
            rawDataLog.removeAt(0);
          }
        });
        
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        
        _parseWeight(received);
      }).onDone(() {
        print('⚠️ Connection lost (onDone triggered)');
        
        if (mounted) {
          setState(() {
            selectedDevice = null;
            currentWeight = "0.0";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Koneksi terputus'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
      
    } else {
      // MANUAL MODE
      print('📊 Mode: MANUAL (Request-based)');
      
      connection!.input!.listen((Uint8List data) {
        String received = ascii.decode(data).trim();
        
        if (mounted) {
          setState(() {
            String timestamp = DateTime.now().toString().substring(11, 19);
            rawDataLog.add('$timestamp: $received (MANUAL MODE - RECEIVED)');
            if (rawDataLog.length > 100) {
              rawDataLog.removeAt(0);
            }
          });
        }
        
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        
        _parseWeight(received);
        
        // Auto-save in manual mode
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          
          double? weight = double.tryParse(currentWeight);
          if (weight != null && weight > 0.05) { 
            print('✓ Mode Manual - Auto-save triggered: $weight $selectedUnit');
            _autoSaveAndPrintManual();
          } else {
            print('⚠️ Mode Manual - Skip save (weight too low or invalid): $currentWeight');
          }
        });
        
      }).onDone(() {
        print('⚠️ Connection lost (onDone triggered)');
        
        if (mounted) {
          setState(() {
            selectedDevice = null;
            currentWeight = "0.0";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Koneksi terputus'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }
    
    print('✅ Listener setup completed');
    print('🎯 UI should now switch to weight display');
    print('═══════════════════════════════════════════════════\n');
    
  } catch (e) {
    print('\n❌ ═══════════════════════════════════════════════════');
    print('CONNECTION FAILED');
    print('   Error: $e');
    print('═══════════════════════════════════════════════════\n');
    
    setState(() {
      isConnecting = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal terhubung: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void _parseWeight(String data) {
  if (!isActuallyConnected) {
    // Demo mode - don't parse
    print('⚠️ Demo Mode: Ignoring weight data (not connected)');
    return;
  }

  try {
    String cleanData = data.trim();
    
    // Extract Tare dari raw data (jika ada)
    if (cleanData.contains('T.W.:')) {
      final tareMatch = RegExp(r'T\.W\.:?\s*([+-]?\d+\.?\d*)').firstMatch(cleanData);
      if (tareMatch != null) {
        String tareStr = tareMatch.group(1)!.replaceAll('+', '');
        double tareFromScale = double.parse(tareStr);
        
        double tareInGrams = tareFromScale;
        if (cleanData.toLowerCase().contains('kg')) {
          tareInGrams = tareFromScale * 1000;
        }
        
        setState(() {
          taraValue = tareInGrams;
        });
        
        print('✅ Tare extracted from raw data: $tareFromScale kg → ${tareInGrams}g');
      }
    }
    
    final numbers = RegExp(r'[+-]?\d+\.?\d*').firstMatch(cleanData);
    if (numbers != null) {
      String weight = numbers.group(0)!;
      weight = weight.replaceAll('+', '');
      
      if (weight.isNotEmpty && weight != '-' && weight != '.') {
        double rawWeight = double.parse(weight);
        
        if (weight.contains('.')) {
          String decimalPart = weight.split('.')[1];
          currentDecimalPlaces = decimalPart.length;
        } else {
          currentDecimalPlaces = 0;
        }
        
        if (isDisplayCleared) {
          double weightInKg = _convertToKg(rawWeight);
          if (weightInKg < 0.05) {
            setState(() {
              isDisplayCleared = false;
              print('❄️ Display unfrozen - weight returned to zero');
            });
          }
          return;
        }
        
        setState(() {
          double rawWeightInKg = _convertToKg(rawWeight);
          
          print('\n🔧 PARSE WEIGHT DEBUG:');
          print('   Raw from scale: $rawWeight $selectedUnit');
          print('   Raw in KG: ${rawWeightInKg.toStringAsFixed(6)} kg');
          
          // ✅ STEP 1: Hitung Net Weight (Gross - Tara)
          double netWeightAfterTare = _applyTara(rawWeight);
          double netWeightInKg = _convertToKg(netWeightAfterTare);
          print('   Net after Tara: ${netWeightInKg.toStringAsFixed(3)} kg');
          print('   Tara Value: ${taraValue.toStringAsFixed(3)} g\n');

          // ✅ STEP 2: Apply Pre-Tare
          double finalNetWeight = _applyPreTare(netWeightInKg);
          print('   Final Net (after Pre-Tare): ${finalNetWeight.toStringAsFixed(3)} kg\n');

          // ✅ STEP 3: COUNTING MODE - Hitung Quantity dari FINAL NET WEIGHT
          if ((isUnitWeightSet || isSamplingMode) && unitWeight > 0) {
            // 🎯 PERUBAHAN UTAMA: Gunakan finalNetWeight (Net) bukan rawWeightInKg (Gross)
            calculatedQuantity = (finalNetWeight / unitWeight).round();
            
            print('📊 COUNTING MODE (NET-BASED):');
            print('   Final Net Weight: ${finalNetWeight.toStringAsFixed(3)} kg');
            print('   Unit Weight: ${unitWeight.toStringAsFixed(6)} kg/pcs');
            print('   Calculated Qty: $calculatedQuantity pcs');
            print('   Formula: ${finalNetWeight.toStringAsFixed(3)} kg ÷ ${unitWeight.toStringAsFixed(6)} kg/pcs = $calculatedQuantity pcs');
            
            // Convert to display unit for info
            double netInDisplayUnit = _convertFromKg(finalNetWeight, selectedUnit);
            double unitWeightInDisplayUnit = _convertFromKg(unitWeight, selectedUnit);
            print('   (In $selectedUnit: ${netInDisplayUnit.toStringAsFixed(3)} ÷ ${unitWeightInDisplayUnit.toStringAsFixed(4)} = $calculatedQuantity pcs)');
            
          } else {
            calculatedQuantity = 0;
          }

          // Update display values
          double grossForDisplay = _convertFromKg(rawWeightInKg, selectedUnit);
          if (currentDecimalPlaces > 0) {
            grossWeight = grossForDisplay.toStringAsFixed(currentDecimalPlaces);
          } else {
            grossWeight = grossForDisplay.toStringAsFixed(0);
          }

          double netForDisplay = _convertFromKg(finalNetWeight, selectedUnit);
          if (currentDecimalPlaces > 0) {
            netWeight = netForDisplay.toStringAsFixed(currentDecimalPlaces);
          } else {
            netWeight = netForDisplay.toStringAsFixed(0);
          }

          double taraInKg = taraValue / 1000;
          double tareForDisplay = _convertFromKg(taraInKg, selectedUnit);
          if (currentDecimalPlaces > 0) {
            tareWeight = tareForDisplay.toStringAsFixed(currentDecimalPlaces);
          } else {
            tareWeight = tareForDisplay.toStringAsFixed(0);
          }

          currentWeight = netWeight;

          // Weight status check
          if (finalNetWeight < lowThreshold) {
            weightStatus = "Low";
          } else if (finalNetWeight > highThreshold) {
            weightStatus = "High";
          } else {
            weightStatus = "OK";
          }
          
          // Unit detection
          String lowerData = cleanData.toLowerCase();
          if (lowerData.contains('kg')) {
            selectedUnit = "KG";
          } else if (lowerData.contains('lb')) {
            selectedUnit = "POUND";
          } else if (lowerData.contains('oz')) {
            selectedUnit = "ONS";
          } else if (lowerData.contains('mg')) {
            selectedUnit = "MG";
          } else if (lowerData.contains('g')) {
            selectedUnit = "GRAM";
          }
        });
      }
    }
  } catch (e) {
    print('Error parsing weight: $e - Data: $data');
  }
}

void _startStatisticalSession() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.analytics, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Text('Start Statistical Session'),
        ],
      ),
      content: const Text(
        'Mode Statistik akan:\n\n'
        '1️⃣ Print header pada penimbangan pertama\n'
        '2️⃣ Print hanya berat untuk penimbangan berikutnya\n'
        '3️⃣ Otomatis append ke hasil sebelumnya\n\n'
        'Cocok untuk batch weighing dengan banyak item!',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              isStatisticalSession = true;
              statisticalWeighingCount = 0;
              statisticalWeights = [];
              statisticalSessionStart = DateTime.now();
            });
            
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '✅ Statistical Session Started\n'
                  '💡 Penimbangan pertama akan print header + berat\n'
                  '💡 Penimbangan selanjutnya hanya print berat',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Session'),
        ),
      ],
    ),
  );
}

void _endStatisticalSession() {
  if (!isStatisticalSession) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tidak ada session aktif'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.summarize, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Text('End Session?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Total Weighings: $statisticalWeighingCount'),
          Text('⚖️ Total Weight: ${statisticalWeights.fold(0.0, (a, b) => a + b).toStringAsFixed(3)} kg'),
          if (statisticalWeights.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('📈 Average: ${(statisticalWeights.reduce((a, b) => a + b) / statisticalWeights.length).toStringAsFixed(3)} kg'),
            Text('⬆️ Max: ${statisticalWeights.reduce((a, b) => a > b ? a : b).toStringAsFixed(3)} kg'),
            Text('⬇️ Min: ${statisticalWeights.reduce((a, b) => a < b ? a : b).toStringAsFixed(3)} kg'),
          ],
          const SizedBox(height: 12),
          const Text(
            '💡 Tip: Jika belum print summary, gunakan button "Stat" sebelum end session',
            style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              isStatisticalSession = false;
              statisticalWeighingCount = 0;
              statisticalWeights = [];
              statisticalSessionStart = null;
            });
            
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Statistical session ended'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.stop),
          label: const Text('End Session'),
        ),
      ],
    ),
  );
}

void _showStatisticalWeighingDialog() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[700], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Statistical Weighing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isStatisticalSession ? Colors.green[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isStatisticalSession ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isStatisticalSession ? Icons.check_circle : Icons.info_outline,
                  color: isStatisticalSession ? Colors.green[700] : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStatisticalSession ? 'Session Active' : 'No Active Session',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isStatisticalSession ? Colors.green[900] : Colors.grey[700],
                        ),
                      ),
                      if (isStatisticalSession) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Weighings: $statisticalWeighingCount',  
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (statisticalWeights.isNotEmpty)
                          Text(
                            'Total: ${statisticalWeights.fold(0.0, (a, b) => a + b).toStringAsFixed(2)} kg',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (!isStatisticalSession)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startStatisticalSession();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Statistical Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _endStatisticalSession();
                },
                icon: const Icon(Icons.stop),
                label: const Text('End Statistical Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Cara Kerja:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text('1️⃣ Start session', style: TextStyle(fontSize: 11)),
                const Text('2️⃣ Timbang item #1 → tap Save → data tersimpan', style: TextStyle(fontSize: 11)),
                const Text('3️⃣ Timbang item #2 → tap Save → data tersimpan', style: TextStyle(fontSize: 11)),
                const Text('4️⃣ Ulangi untuk semua item...', style: TextStyle(fontSize: 11)),
                const Text('5️⃣ Tap "Stat" button → Print Summary + Reset counter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                const Text('6️⃣ End session (opsional)', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}



Future<void> _printLastWeighing() async {
  if (!isStatisticalSession) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ Statistical session not active\n'
          '💡 Start session from menu (⋮) → Statistical Session'
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }
  
  if (statisticalWeights.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Belum ada data untuk di-print\n💡 Timbang minimal 1 item terlebih dahulu'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }
  
  // ✅ Store values before reset
  final int countBeforePrint = statisticalWeighingCount;
  final List<double> weightsBeforePrint = List.from(statisticalWeights);
  
  try {
    print('\n📊 PRINT STATISTICAL SUMMARY');
    print('   Total Weighings: $statisticalWeighingCount');
    
    final template = await dbHelper.getActiveLabelTemplate();
    if (template == null) {
      _showError('No active label template');
      return;
    }
    
    String? operatorName;
    int operatorIndex = customFields.indexWhere((f) => f['label'] == 'Operator');
    if (operatorIndex != -1) {
      operatorName = customFields[operatorIndex]['value'];
    }
    
    String? productName;
    if (selectedProduct != null) {
      productName = selectedProduct!.productName;
    } else {
      int productIndex = customFields.indexWhere((f) => f['label'] == 'Product');
      if (productIndex != -1) {
        productName = customFields[productIndex]['value'];
      }
    }
    
    String summaryContent = LabelPrintService.renderStatisticalSummary(
      template,
      weightsBeforePrint,
      operatorName: operatorName,
      productName: productName,
      unit: selectedUnit,
      decimalPlaces: currentDecimalPlaces,
    );

    if (summaryContent.isEmpty) {
      _showError('Failed to generate summary');
      return;
    }
    
    await _printSummaryWithTemplate(template, summaryContent);
    
    // ✅ FIX #4: Reset counter IMMEDIATELY after print
    setState(() {
      statisticalWeighingCount = 0;
      statisticalWeights.clear();
      print('✅ Statistical counter RESET to 0');
      print('✅ Weights list CLEARED');
      print('✅ Session TETAP AKTIF - ready for next weighing');
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Statistical Summary printed!\n'
            '📊 ${weightsBeforePrint.length} items\n'
            '⚖️ Total: ${weightsBeforePrint.fold(0.0, (a, b) => a + b).toStringAsFixed(3)} kg\n'
            '🔄 Counter reset to 0\n'
            '💡 Session masih aktif - lanjut timbang!'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    
  } catch (e) {
    print('❌ Error printing summary: $e');
    
    // ✅ Even on error, reset counter
    setState(() {
      statisticalWeighingCount = 0;
      statisticalWeights.clear();
      print('✅ Counter RESET to 0 (after error)');
    });
    
    if (mounted) {
      _showError('Error: $e\n\nCounter has been reset to 0.');
    }
  }
}

String _getOperatorName() {
  int operatorIndex = customFields.indexWhere((f) => f['label'] == 'Operator');
  return operatorIndex != -1 ? customFields[operatorIndex]['value']! : '-';
}

Map<String, String> _getCustomFieldsMap() {
  final map = <String, String>{};
  for (var field in customFields) {
    String key = field['label']!.toLowerCase().replaceAll(' ', '_');
    map[key] = field['value']!.isEmpty ? '-' : field['value']!;
  }
  return map;
}

  void _saveWeight() async {
  if (currentWeight != "0.0") {
    try {
      print('💾 Saving weight: $currentWeight $selectedUnit');
      
      final template = await dbHelper.getActiveLabelTemplate();
      
      if (template == null) {
        _showError('Tidak ada template label aktif.\nBuat template di Label Designer.');
        return;
      }
      
      final Map<String, String> customFieldsMap = {};
      for (var field in customFields) {
        String label = field['label']!;
        String value = field['value']!;
        customFieldsMap[label] = value;
      }

      final printData = LabelPrintService.prepareDataForPrint(
        berat: double.parse(currentWeight),
        unit: selectedUnit,
        namaBarang: selectedBarang?['nama'],
        kategori: selectedBarang?['kategori'],
        operator: 'Operator',  
        hargaPerKg: selectedBarang?['harga'],
        quantity: calculatedQuantity > 0 ? calculatedQuantity : null,
        unitWeight: isUnitWeightSet ? unitWeight : null,
        sampleCount: isSamplingMode ? sampleCount : null,
        customFieldsData: customFieldsMap,
      );

      if (isStatisticalSession) {
        setState(() {
          statisticalWeighingCount++;
          statisticalWeights.add(_convertToKg(double.parse(currentWeight)));
        });
        
        print('📊 Statistical Session: Weighing #$statisticalWeighingCount');
        print('   Saving data (print will be weight-only if enabled)');
      }

      setState(() {
        weighingCounter++;
        totalWeightKg += _convertToKg(double.parse(currentWeight));
      });

      await _executePrintAndSave(
        template, 
        printData,
        isStatistical: isStatisticalSession,  
      );
      
    } catch (e, stackTrace) {
      print('❌ Error in _saveWeight: $e');
      print('Stack trace: $stackTrace');
      _showError('Error menyimpan: $e');
    }
  } else {
    _showError('Berat masih 0. Tunggu data dari timbangan.');
  }
}

Future<void> _printFirstWeighingWithHeader() async {
  if (!isStatisticalSession) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ Statistical session not active\n'
          '💡 Start session from menu (⋮) → Statistical Session'
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  if (currentWeight == "0.0" || currentWeight == "0.00") {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Berat masih 0. Tunggu data dari timbangan.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  try {
    print('\n📊 ═══════════════════════════════════════════════════');
    print('PRINT FIRST WEIGHING + HEADER (Statistical Session)');
    print('   Weight: $currentWeight $selectedUnit');
    print('═══════════════════════════════════════════════════\n');

    final template = await dbHelper.getActiveLabelTemplate();
    if (template == null) {
      _showError('Tidak ada template label aktif.');
      return;
    }

    Map<String, String> activeFields = {};
    for (var field in customFields) {
      if (field['value']!.isNotEmpty) {
        activeFields[field['label']!] = field['value']!;
      }
    }

    final Map<String, String> customFieldsMap = {};
    for (var field in customFields) {
      customFieldsMap[field['label']!] = field['value']!;
    }

    final printData = LabelPrintService.prepareDataForPrint(
      berat: double.parse(currentWeight),
      unit: selectedUnit,
      namaBarang: selectedBarang?['nama'],
      kategori: selectedBarang?['kategori'],
      operator: customFieldsMap['Operator'] ?? '-',
      hargaPerKg: selectedBarang?['harga'],
      quantity: calculatedQuantity > 0 ? calculatedQuantity : null,
      unitWeight: isUnitWeightSet ? unitWeight : null,
      sampleCount: isSamplingMode ? sampleCount : null,
      customFieldsData: customFieldsMap,
    );

    String nomorResi = 'STAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    Map<String, dynamic> resi = {
      'nomor': nomorResi,
      'tanggal': DateTime.now().toString(),
      'barang': printData['NAMA_BARANG'] ?? 'Tanpa Nama',
      'kategori': printData['KATEGORI'] ?? '-',
      'berat': currentWeight,
      'unit': selectedUnit,
      'beratKg': _convertToKg(double.parse(currentWeight)),
      'hargaPerKg': 0,
      'totalHarga': 0,
    };

    Map<String, dynamic> pengukuran = {
      'tanggal': DateTime.now().toString(),
      'barang': printData['NAMA_BARANG'] ?? 'Tanpa Nama',
      'kategori': printData['KATEGORI'] ?? '-',
      'berat': currentWeight,
      'unit': selectedUnit,
      'beratKg': _convertToKg(double.parse(currentWeight)),
      'hargaTotal': 0,
      'gross_weight': double.parse(grossWeight),
      'tare_weight': taraValue,
      'quantity': calculatedQuantity > 0 ? calculatedQuantity : null,
      'unit_weight': isUnitWeightSet ? unitWeight : null,
      'product': customFieldsMap['Product'],
      'client': customFieldsMap['Client'],
      'id_field': customFieldsMap['ID'],
      'supplier': customFieldsMap['Supplier'],
      'batch_number': customFieldsMap['Batch Number'],
      'material_code': customFieldsMap['Product Code'],
      'sku': customFieldsMap['SKU'],
      'location': customFieldsMap['Location'],
      'operator': customFieldsMap['Operator'],
      'notes': customFieldsMap['Notes'],
      'custom': customFieldsMap['Custom'],
    };

    int resiId = await dbHelper.createResi(resi);
    await dbHelper.createPengukuran(pengukuran);
    
    resi['id'] = resiId;

    setState(() {
      resiList.insert(0, resi);
      historyMeasurements.insert(0, {
        'tanggal': DateTime.now(),
        'barang': printData['NAMA_BARANG'] ?? 'Tanpa Nama',
        'kategori': printData['KATEGORI'] ?? '-',
        'berat': currentWeight,
        'unit': selectedUnit,
        'beratKg': _convertToKg(double.parse(currentWeight)),
        'hargaTotal': 0,
        'quantity': calculatedQuantity > 0 ? calculatedQuantity : null,
        'unit_weight': isUnitWeightSet ? unitWeight : null,
        ...pengukuran,
      });

      statisticalWeighingCount = 1;  
      statisticalWeights.add(_convertToKg(double.parse(currentWeight)));
      weighingCounter++;
      totalWeightKg += _convertToKg(double.parse(currentWeight));

      String timestamp = DateTime.now().toString().substring(11, 19);
      historyData.insert(0, '$timestamp - Statistical #1 - $currentWeight ${selectedUnit.toLowerCase()}');
      
      if (historyData.length > 50) {
        historyData.removeLast();
      }
    });

    print('✅ Data tersimpan ke SQLite dengan ID: $resiId');
    await _saveLastWeighingState();

    if (isPrintEnabled) {
      if (defaultPrinterAddress == null || defaultPrinterAddress!.isEmpty) {
        print('⚠️ Print enabled but no printer configured');
        NotificationHelper.showSuccess(
          context,
          '✓ Data tersimpan!\n⚠️ Printer belum dikonfigurasi'
        );
      } else {
        print('🖨️ Printing FIRST weighing WITH FULL HEADER...');
        
        String headerContent = LabelPrintService.generateStatisticalFirstWeighing(
          template: template,
          activeFields: activeFields,
          weight: currentWeight,
          unit: selectedUnit,
          quantity: calculatedQuantity > 0 ? calculatedQuantity : null,
          unitWeight: isUnitWeightSet ? unitWeight : null,
          decimalPlaces: currentDecimalPlaces,
          counterNumber: 1,  
        );
        
        await _printStatisticalContent(template, headerContent);
        
        NotificationHelper.showSuccess(
          context,
          '✓ Tersimpan & Header dicetak!\n'
          '📊 Statistical: Counter #$statisticalWeighingCount\n'
          '💡 Gunakan tombol Save untuk penimbangan berikutnya'
        );
      }
    } else {
      print('🔇 Printing disabled, data saved only');
      NotificationHelper.showSuccess(
        context,
        '✓ Data tersimpan!\n🔇 Printing: OFF\n'
        '📊 Statistical: Counter #$statisticalWeighingCount'
      );
    }

  } catch (e, stackTrace) {
    print('❌ Error in _printFirstWeighingWithHeader: $e');
    print('Stack trace: $stackTrace');
    _showError('Error: $e');
  }
}

Future<void> _printStatisticalContent(
  LabelTemplate template,
  String content,
) async {
  if (defaultPrinterAddress == null || defaultPrinterAddress!.isEmpty) {
    return;
  }

  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  try {
    printerHelper = BluetoothPrinterHelper();
    bool connected = await printerHelper!.connect(
      defaultPrinterAddress!,
      printerName: defaultPrinterName,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal koneksi ke $defaultPrinterName'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success = await printerHelper!.printFromTemplate(content);

    await printerHelper!.disconnect();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Statistical header printed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

  } catch (e) {
    print('❌ Error: $e');
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _printStatisticalHeader(
  LabelTemplate template,
  Map<String, dynamic> headerData,
) async {
  if (defaultPrinterAddress == null || defaultPrinterAddress!.isEmpty) {
    return;
  }

  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  try {
    String printerName = (defaultPrinterName ?? '').toUpperCase();
    bool isTSPL = printerName.contains('PS-6E1A5A') ||
                  printerName.contains('TSC') ||
                  printerName.contains('ALPHA') ||
                  printerName.contains('LABEL');

    String printContent;
    if (isTSPL) {
      printContent = _generateStatisticalHeaderTSPL(template, headerData);
    } else {
      printContent = _generateStatisticalHeaderESCPOS(headerData);
    }

    print('\n📄 PRINT CONTENT (First Weighing + Header):');
    print('─' * 60);
    if (isTSPL) {
      print('TSPL Format:');
      LabelPrintService.debugTSPL(printContent);
    } else {
      print('ESC/POS Format:');
      print(printContent);
    }
    print('─' * 60);

    printerHelper = BluetoothPrinterHelper();
    bool connected = await printerHelper!.connect(
      defaultPrinterAddress!,
      printerName: defaultPrinterName,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal koneksi ke $defaultPrinterName'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success = false;
    if (isTSPL) {
      success = await printerHelper!.printRawTSPL(printContent);
    } else {
      success = await printerHelper!.printFromTemplate(printContent);
    }

    await printerHelper!.disconnect();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Statistical header + first weight printed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

  } catch (e) {
    print('❌ Error: $e');
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

String _generateStatisticalHeaderTSPL(
  LabelTemplate template,
  Map<String, dynamic> data,
) {
  String output = '''
SIZE ${template.width} mm, ${template.height} mm
GAP 3 mm, 0 mm
DIRECTION 0
REFERENCE 0,0
OFFSET 0 mm
DENSITY 8
SPEED 4
CLS
''';

  int yPos = 20;
  int labelWidth = (template.width * 8).round() - 20;

  output += 'TEXT 10,$yPos,"4",0,2,2,"T-CONNECT"\n';
  yPos += 50;
  output += 'BAR 10,$yPos,$labelWidth,2\n';
  yPos += 15;

  String timestamp = data['TIMESTAMP'] ?? DateTime.now().toString().substring(0, 19);
  String operator = data['OPERATOR'] ?? '-';
  
  output += 'TEXT 10,$yPos,"2",0,1,1,"Time: $timestamp"\n';
  yPos += 25;
  output += 'TEXT 10,$yPos,"2",0,1,1,"Operator: $operator"\n';
  yPos += 30;
  output += 'BAR 10,$yPos,$labelWidth,2\n';
  yPos += 15;

  Map<String, String> activeFields = Map<String, String>.from(data['ACTIVE_FIELDS'] ?? {});
  for (var entry in activeFields.entries) {
    String label = entry.key;
    String value = entry.value;
    
    if (value.length > 20) {
      value = value.substring(0, 20) + '...';
    }
    
    output += 'TEXT 10,$yPos,"2",0,1,1,"$label: $value"\n';
    yPos += 25;
  }

  yPos += 5;
  output += 'BAR 10,$yPos,$labelWidth,2\n';
  yPos += 15;

  String weight = data['BERAT'] ?? '0.00';
  String unit = data['UNIT'] ?? 'kg';
  
  output += 'TEXT 10,$yPos,"4",0,2,2,"$weight $unit"\n';
  yPos += 50;

  if (data['QUANTITY'] != null) {
    String qty = data['QUANTITY']!;
    String uw = data['UNIT_WEIGHT'] ?? '-';
    output += 'TEXT 10,$yPos,"2",0,1,1,"Qty: $qty pcs (UW: $uw g/pcs)"\n';
    yPos += 25;
  }

  output += 'TEXT 10,$yPos,"2",0,1,1,"G:${data['GROSS_WEIGHT']} | T:${data['TARE_WEIGHT']} | N:${data['NET_WEIGHT']}"\n';

  output += '\nPRINT 1,1\n';
  return output;
}

String _generateStatisticalHeaderESCPOS(Map<String, dynamic> data) {
  String output = '';

  const String ESC = '\x1B';
  const String GS = '\x1D';
  const String INIT = '$ESC@';
  const String CENTER = '$ESC\x61\x01';
  const String LEFT = '$ESC\x61\x00';
  const String BOLD_ON = '$ESC\x45\x01';
  const String BOLD_OFF = '$ESC\x45\x00';

  output += INIT;
  output += CENTER;

  output += BOLD_ON;
  output += '$GS\x21\x00'; 
  output += 'T-CONNECT\n';
  output += BOLD_OFF;
  output += '$GS\x21\x00'; 

  output += '================================\n';

  output += LEFT;
  String timestamp = data['TIMESTAMP'] ?? DateTime.now().toString().substring(0, 19);
  String operator = data['OPERATOR'] ?? '-';

  output += 'Time    : $timestamp\n';
  output += 'Operator: $operator\n';
  output += '================================\n';

  Map<String, String> activeFields = Map<String, String>.from(data['ACTIVE_FIELDS'] ?? {});
  for (var entry in activeFields.entries) {
    String label = entry.key.padRight(10);
    String value = entry.value;
    
    if (value.length > 20) {
      value = value.substring(0, 20) + '...';
    }
    
    output += '$label: $value\n';
  }

  output += '================================\n';

  String weight = data['BERAT'] ?? '0.00';
  String unit = data['UNIT'] ?? 'kg';

  output += CENTER;
  output += BOLD_ON;
  output += '$GS\x21\x00'; 
  output += '$weight $unit\n';
  output += BOLD_OFF;
  output += '$GS\x21\x00'; 

  if (data['QUANTITY'] != null) {
    String qty = data['QUANTITY']!;
    String uw = data['UNIT_WEIGHT'] ?? '-';
    output += 'Qty: $qty pcs\n';
    output += 'Unit Weight: $uw g/pcs\n';
  }

  output += LEFT;
  output += '================================\n';

  output += '\n\n';
  return output;
}

Future<void> _executePrintAndSave(
  LabelTemplate template,
  Map<String, dynamic> data,
  {bool isStatistical = false}
) async {
  try {
    String nomorResi = 'RESI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    Map<String, String> customFieldsData = {};
    for (var field in customFields) {
      String label = field['label']!.toLowerCase().replaceAll(' ', '_');
      String value = field['value']!.isEmpty ? '-' : field['value']!;
      customFieldsData[label] = value;
    }
    
    // ✅ FIX: Safe parsing of current weight
    double currentWeightValue;
    try {
      currentWeightValue = double.parse(currentWeight);
    } catch (e) {
      print('❌ Error parsing currentWeight: $currentWeight - $e');
      currentWeightValue = 0.0;
    }
    
    double beratKg = _convertToKg(currentWeightValue);
    
    Map<String, dynamic> resi = {
      'nomor': nomorResi,
      'tanggal': DateTime.now().toString(),
      'barang': data['NAMA_BARANG'] ?? 'Tanpa Nama',
      'kategori': data['KATEGORI'] ?? '-',
      'berat': currentWeight,
      'unit': selectedUnit,
      'beratKg': beratKg,
      'hargaPerKg': selectedBarang != null ? selectedBarang!['harga'] : 0,
      'totalHarga': selectedBarang != null && selectedBarang!['harga'] > 0 
          ? (beratKg * selectedBarang!['harga']).round()
          : 0,
    };
    
    Map<String, dynamic> pengukuran = {
      'tanggal': DateTime.now().toString(),
      'barang': data['NAMA_BARANG'] ?? 'Tanpa Nama',
      'kategori': data['KATEGORI'] ?? '-',
      'berat': currentWeight,
      'unit': selectedUnit,
      'beratKg': beratKg,
      'hargaTotal': selectedBarang != null && selectedBarang!['harga'] > 0 
          ? (beratKg * selectedBarang!['harga']).round()
          : 0,
      'gross_weight': double.tryParse(grossWeight) ?? 0.0,
      'tare_weight': taraValue / 1000,  // Convert gram to kg
      'quantity': calculatedQuantity > 0 ? calculatedQuantity : null,
      'unit_weight': isUnitWeightSet ? unitWeight : null,
      'product': customFieldsData['product'],
      'client': customFieldsData['client'],
      'id_field': customFieldsData['id'],
      'supplier': customFieldsData['supplier'],
      'batch_number': customFieldsData['batch_number'],
      'material_code': customFieldsData['product_code'],
      'sku': customFieldsData['sku'],
      'location': customFieldsData['location'],
      'operator': customFieldsData['operator'],
      'notes': customFieldsData['notes'],
      'custom': customFieldsData['custom'],
    };
    
    int resiId = await dbHelper.createResi(resi);
    await dbHelper.createPengukuran(pengukuran);
    
    resi['id'] = resiId;
    
    setState(() {
      resiList.insert(0, resi);
      historyMeasurements.insert(0, {
        'tanggal': DateTime.now(),
        'barang': data['NAMA_BARANG'] ?? 'Tanpa Nama',
        'kategori': data['KATEGORI'] ?? '-',
        'berat': currentWeight,
        'unit': selectedUnit,
        'beratKg': beratKg,
        'hargaTotal': selectedBarang != null && selectedBarang!['harga'] > 0 
            ? (beratKg * selectedBarang!['harga']).round()
            : 0,
        'quantity': calculatedQuantity > 0 ? calculatedQuantity : null,
        'unit_weight': isUnitWeightSet ? unitWeight : null,
        'gross_weight': double.tryParse(grossWeight) ?? 0.0,
        'tare_weight': taraValue / 1000,
        ...pengukuran,
      });
      
      String barangInfo = data['NAMA_BARANG'] != null 
          ? '${data['NAMA_BARANG']} - ' 
          : '';
      String timestamp = DateTime.now().toString().substring(11, 19);
      historyData.insert(0, '$timestamp - $barangInfo$currentWeight ${selectedUnit.toLowerCase()}');
      
      if (historyData.length > 50) {
        historyData.removeLast();
      }
    });
    
    print('✅ Data tersimpan ke SQLite dengan ID: $resiId');
    await _saveLastWeighingState();
  
    if (isPrintEnabled) {
      if (defaultPrinterAddress == null || defaultPrinterAddress!.isEmpty) {
        print('⚠️ Print enabled but no printer configured');
        if (mounted) {
          NotificationHelper.showSuccess(
            context, 
            '✓ Data tersimpan!\n⚠️ Printer belum dikonfigurasi'
          );
        }
      } else {
        if (isStatistical) {
          print('🖨️ Statistical mode: Printing weight only (no header)');
          await _printWeightOnlyStatistical(template, data);
          
          if (mounted) {
            NotificationHelper.showSuccess(
              context, 
              '✓ Tersimpan & Weight printed!\n📊 Statistical: #$statisticalWeighingCount'
            );
          }
        } else {
          print('🖨️ Normal mode: Printing full label');
          await _printWithTemplate(template, data);
          
          if (mounted) {
            NotificationHelper.showSuccess(
              context, 
              '✓ Tersimpan & Sedang mencetak...'
            );
          }
        }
      }
    } else {
      print('🔇 Printing disabled, data saved only');
      if (mounted) {
        NotificationHelper.showSuccess(
          context, 
          '✓ Data tersimpan!\n🔇 Printing: OFF'
        );
      }
    }
    
  } catch (e, stackTrace) {
    print('❌ Error saving & printing: $e');
    print('Stack trace: $stackTrace');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _printWeightOnlyStatistical(
  LabelTemplate template,
  Map<String, dynamic> data,
) async {
  if (defaultPrinterAddress == null || defaultPrinterAddress!.isEmpty) {
    return;
  }

  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  try {
  final bool isStatisticalSummary = data.containsKey('IS_STATISTICAL_SUMMARY');
  
  final String printerName = (defaultPrinterName ?? '').toUpperCase();
  final bool isTSPL = printerName.contains('PS-6E1A5A') ||
      printerName.contains('TSC') ||
      printerName.contains('ALPHA') ||
      printerName.contains('LABEL');

  final bool useESCPOS = isStatisticalSummary || !isTSPL;

  final String printContent = useESCPOS
      ? LabelPrintService.renderWeightOnlyESCPOS(template, data)
      : LabelPrintService.renderWeightOnly(template, data);

    _logPrintContent(data);

    printerHelper = BluetoothPrinterHelper();
    final bool connected = await printerHelper!.connect(
      defaultPrinterAddress!,
      printerName: defaultPrinterName,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (!connected) {
      _showErrorMessage('Gagal koneksi ke $defaultPrinterName');
      return;
    }

    final bool success = isTSPL
        ? await printerHelper!.printRawTSPL(printContent)
        : await printerHelper!.printFromTemplate(printContent);

    await printerHelper!.disconnect();

    if (success && mounted) {
      _showSuccessMessage(
        'Weight #$statisticalWeighingCount printed (append mode)',
      );
    }
  } catch (e) {
    print('❌ Print Error: $e');
    
    if (mounted) {
      Navigator.pop(context);
      _showErrorMessage('Error: $e');
    }
  }
}

void _logPrintContent(Map<String, dynamic> data) {
  print('\n📄 PRINT CONTENT (Weight Only - Statistical):');
  print('─' * 60);
  print('Weight: ${data['BERAT']} ${data['UNIT']}');
  if (data['QUANTITY'] != null) {
    print('Qty: ${data['QUANTITY']}');
  }
  print('─' * 60);
}

void _showErrorMessage(String message) {
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ $message'),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}

void _showSuccessMessage(String message) {
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✓ $message'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<void> _printWithTemplate(
  LabelTemplate template,
  Map<String, dynamic> data,
) async {
  if (defaultPrinterAddress == null || defaultPrinterAddress!.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Printer tidak dikonfigurasi\n'
            '💡 Set printer di Settings atau disable printing di menu'
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return;  
  }

  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  try {
    String printerName = (defaultPrinterName ?? '').toUpperCase();
    String printerAddress = (defaultPrinterAddress ?? '').toUpperCase();

    print('');
    print('═' * 60);
    print('🔍 PRINTER DETECTION');
    print('═' * 60);
    print('📱 Name: $printerName');
    print('📍 Address: $printerAddress');
    print('─' * 60);

    bool isTSPLPrinter = printerName.contains('PS-6E1A5A') ||    
                         printerName.contains('VSC') ||
                         printerName.contains('Q108') ||
                         printerName.contains('TSC') ||
                         printerName.contains('ALPHA') ||
                         printerName.contains('TTP-244') ||      
                         printerName.contains('TTP-245') ||
                         printerName.contains('LABEL PRINTER') ||
                         printerAddress.startsWith('66:32:3D');  

    bool isTSPL = isTSPLPrinter;

    print('🔬 Detection Result:');
    print('   TSPL patterns: ${isTSPLPrinter ? "✅ MATCH" : "❌"}');
    print('─' * 60);
    print('🏷️ Detected Type: ${isTSPL ? "TSPL (Label)" : "ESC/POS (Receipt)"}');
    print('═' * 60);
    print('');

    String printContent;
    
    if (isTSPL) {
      print('📄 Generating FULL LABEL (TSPL)');
      printContent = LabelPrintService.renderTemplateToText(template, data);
      
      print('╔═══════════════════════════════════════════════════════╗');
      print('║       📄 TSPL: NORMAL LABEL                          ║');
      print('╚═══════════════════════════════════════════════════════╝');
      LabelPrintService.debugTSPL(printContent);
    } else {
      print('📄 Generating FULL RECEIPT (ESC/POS)');
      printContent = LabelPrintService.renderTemplateToESCPOS(template, data);
    }

    print('');
    print('🔌 Connecting to printer...');
    print('   Target: $defaultPrinterName');
    print('   Address: $defaultPrinterAddress');
    
    printerHelper = BluetoothPrinterHelper();
    bool connected = await printerHelper!.connect(
      defaultPrinterAddress!,
      printerName: defaultPrinterName,
    );

    if (!mounted) return;
    Navigator.pop(context); 

    if (!connected) {
      print('❌ Connection FAILED');
      print('   Possible reasons:');
      print('   - Printer is OFF or out of range');
      print('   - Bluetooth pairing issue');
      print('   - Printer already connected to another device');
      print('');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal koneksi ke $defaultPrinterName\nCek: Printer ON, jarak dekat, tidak terkoneksi ke device lain'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    print('✅ Connection SUCCESS');
    print('');

    print('🖨️ Sending print job...');
    print('   Method: ${isTSPL ? "printRawTSPL()" : "printFromTemplate()"}');
    print('   Data size: ${printContent.length} bytes');
    
    bool success = false;

    if (isTSPL) {
      success = await printerHelper!.printRawTSPL(printContent);
    } else {
      success = await printerHelper!.printFromTemplate(printContent);
    }

    print('   Result: ${success ? "✅ SUCCESS" : "⚠️ UNCERTAIN"}');
    print('');

    print('🔌 Disconnecting from printer...');
    await printerHelper!.disconnect();
    print('✅ Disconnected');
    print('');

    if (success && mounted) {
      print('═' * 60);
      print('✅ PRINT JOB COMPLETED SUCCESSFULLY');
      print('═' * 60);
      print('');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Label berhasil dicetak\nPrinter: $defaultPrinterName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      print('═' * 60);
      print('⚠️ PRINT JOB STATUS UNCERTAIN');
      print('═' * 60);
      print('Kemungkinan penyebab:');
      print('- Kertas habis atau tidak terpasang benar');
      print('- Printer buffer penuh');
      print('- Ukuran label tidak sesuai setting');
      print('');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Print job dikirim, tapi status tidak pasti.\nCek printer: kertas, gap sensor, hasil print'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
    
  } catch (e, stackTrace) {
    print('');
    print('═' * 60);
    print('❌ PRINT ERROR - EXCEPTION CAUGHT');
    print('═' * 60);
    print('Error Type: ${e.runtimeType}');
    print('Error Message: $e');
    print('');
    print('Stack Trace:');
    print(stackTrace);
    print('═' * 60);
    print('');
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error print: $e\n\nCek console untuk detail lengkap'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

void _showError(String message) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
  
  double _convertToKg(double weight) {
  if (selectedUnit == "KG") return weight;
  if (selectedUnit == "GRAM") return weight / 1000;
  if (selectedUnit == "ONS") return weight / 10;
  if (selectedUnit == "POUND") return weight * 0.453592;
  if (selectedUnit == "MG") return weight / 1000000;  
  return weight;
}
  
  Widget _buildResiRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
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
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showResiList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Daftar Resi',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (resiList.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep),
                          color: Colors.red,
                          onPressed: () {
                            _clearAllResi();
                            Navigator.pop(context);
                          },
                          tooltip: 'Hapus Semua',
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${resiList.length} resi',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (resiList.isNotEmpty)
                    Text(
                      'Total Pendapatan: Rp ${_getTotalPendapatan()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: resiList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Belum ada resi', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: resiList.length,
                      itemBuilder: (context, index) {
                        var resi = resiList[index];
                        DateTime tanggal = DateTime.parse(resi['tanggal']);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showResiDetail(resi),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              resi['nomor'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[700],
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${tanggal.day}/${tanggal.month}/${tanggal.year} ${tanggal.hour}:${tanggal.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton(
                                        icon: const Icon(Icons.more_vert, size: 20),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            child: const Row(
                                              children: [
                                                Icon(Icons.visibility, size: 18),
                                                SizedBox(width: 8),
                                                Text('Detail'),
                                              ],
                                            ),
                                            onTap: () {
                                              Future.delayed(Duration.zero, () {
                                                _showResiDetail(resi);
                                              });
                                            },
                                          ),
                                          PopupMenuItem(
  child: const Row(
    children: [
      Icon(Icons.print, size: 18, color: Colors.blue),
      SizedBox(width: 8),
      Text('Print Resi', style: TextStyle(color: Colors.blue)),
    ],
  ),
  onTap: () {
    Future.delayed(Duration.zero, () {
      _printResi(resi);
    });
  },
),
                                          PopupMenuItem(
                                            child: const Row(
                                              children: [
                                                Icon(Icons.delete, size: 18, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Hapus', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                            onTap: () {
                                              _deleteResi(index);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          resi['barang'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${resi['berat']} ${resi['unit']}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      if (resi['totalHarga'] > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Rp ${resi['totalHarga']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showResiDetail(Map<String, dynamic> resi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Detail Resi'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResiRow('No. Resi', resi['nomor'], bold: true),
              const Divider(),
              _buildResiRow('Tanggal', DateTime.parse(resi['tanggal']).toString().substring(0, 19)),
              _buildResiRow('Barang', resi['barang']),
              _buildResiRow('Kategori', resi['kategori']),
              const Divider(),
              _buildResiRow('Berat', '${resi['berat']} ${resi['unit']}', bold: true),
              _buildResiRow('Berat (kg)', '${resi['beratKg'].toStringAsFixed(3)} kg'),
              if (resi['totalHarga'] > 0) ...[
                const Divider(),
                _buildResiRow('Harga/kg', 'Rp ${resi['hargaPerKg']}'),
                _buildResiRow(
                  'TOTAL HARGA', 
                  'Rp ${resi['totalHarga']}', 
                  bold: true,
                  color: Colors.green[700],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
  
  String _getTotalPendapatan() {
    int total = 0;
    for (var resi in resiList) {
      total += (resi['totalHarga'] as int);
    }
    return total.toString();
  }
  
  void _deleteResi(int index) async {
  var resi = resiList[index];
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus Resi?'),
      content: Text('Apakah Anda yakin ingin menghapus resi "${resi['nomor']}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await dbHelper.deleteResi(resi['id']);
              
              setState(() {
                resiList.removeAt(index);
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resi berhasil dihapus!'),
                  backgroundColor: Colors.orange,
                ),
              );
            } catch (e) {
              print('❌ Error: $e');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}
  
  void _clearAllResi() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus Semua Resi?'),
      content: Text('${resiList.length} resi akan dihapus. Lanjutkan?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await dbHelper.deleteAllResi();
              
              setState(() {
                resiList.clear();
              });
              
              Navigator.pop(context); 
              Navigator.pop(context); 
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Semua resi berhasil dihapus'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              print('❌ Error: $e');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error menghapus resi: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Hapus Semua'),
        ),
      ],
    ),
  );
}
  
  void _showHistoryMeasurements() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Riwayat Pengukuran',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _showExportDialog(),
                      tooltip: 'Ekspor Data',
                      color: Colors.green[700],
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _showFilterDialog(),
                      tooltip: 'Filter Data',
                    ),
                    if (historyMeasurements.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        color: Colors.red,
                        onPressed: () {
                          _clearAllHistory();
                          Navigator.pop(context);
                        },
                        tooltip: 'Hapus Semua',
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${historyMeasurements.length} pengukuran',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: historyMeasurements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat pengukuran', 
                          style: TextStyle(color: Colors.grey[600])
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: historyMeasurements.length,
                    itemBuilder: (context, index) {
                      var measurement = historyMeasurements[index];
                      DateTime tanggal = measurement['tanggal'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${tanggal.day.toString().padLeft(2, '0')}/${tanggal.month.toString().padLeft(2, '0')}/${tanggal.year}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}:${tanggal.second.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          measurement['unit'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      measurement['barang'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${measurement['berat']} ${measurement['unit']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        ' (${measurement['beratKg'].toStringAsFixed(3)} kg)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (measurement['hargaTotal'] > 0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Harga:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                      Text(
                                        'Rp ${measurement['hargaTotal']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ], 
                          ), 
                        ), 
                      ); 
                    }, 
                  ), 
          ), 
        ], 
      ), 
    ), 
  ); 
} 

  void _showFilterDialog() {
    DateTime? startDate;
    DateTime? endDate;
    String? selectedFilterUnit;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal Mulai',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        startDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          startDate != null
                              ? '${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}'
                              : 'Pilih tanggal',
                          style: TextStyle(
                            color: startDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Tanggal Akhir',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        endDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          endDate != null
                              ? '${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}'
                              : 'Pilih tanggal',
                          style: TextStyle(
                            color: endDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Unit',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedFilterUnit,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  hint: const Text('GRAM'),
                  items: ['GRAM', 'KG', 'ONS', 'POUND']
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedFilterUnit = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filter direset'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                _applyFilter(startDate, endDate, selectedFilterUnit);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilter(DateTime? startDate, DateTime? endDate, String? unit) {
    List<Map<String, dynamic>> filtered = historyMeasurements;
    
    if (startDate != null) {
      filtered = filtered.where((m) {
        DateTime date = m['tanggal'];
        return date.isAfter(startDate.subtract(const Duration(days: 1)));
      }).toList();
    }
    
    if (endDate != null) {
      filtered = filtered.where((m) {
        DateTime date = m['tanggal'];
        return date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }
    
    if (unit != null) {
      filtered = filtered.where((m) => m['unit'] == unit).toList();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filter diterapkan: ${filtered.length} data ditemukan'),
        backgroundColor: Colors.green,
      ),
    );
    
    _showHistoryMeasurements();
  }
  
  void _clearAllHistory() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus Semua Riwayat?'),
      content: Text('${historyMeasurements.length} pengukuran akan dihapus. Lanjutkan?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await dbHelper.deleteAllPengukuran();
              
              setState(() {
                historyMeasurements.clear();
              });
              
              Navigator.pop(context); 
              Navigator.pop(context); 
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Semua riwayat berhasil dihapus'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              print('❌ Error: $e');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error menghapus riwayat: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Hapus Semua'),
        ),
      ],
    ),
  );
}
  
  void _showExportDialog() {
    if (historyMeasurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk diekspor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ekspor Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih format ekspor:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildExportButton(
                  icon: Icons.table_chart,
                  label: 'CSV',
                  color: Colors.green,
                  onPressed: () {
                    Navigator.pop(context);
                    _exportToCSV();
                  },
                ),
                _buildExportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(context);
                    _exportToPDF();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV() async {
  try {
    List<List<dynamic>> rows = [];
    
    rows.add([
      'No',
      'Tanggal',
      'Waktu',
      'Product',
      'Product Code',  
      'Gross (kg)',    
      'Tare (kg)',     
      'Net (kg)',      
      'Unit',
      'Quantity (pcs)',
      'Unit Weight (kg/pcs)',
      'Client',
      'ID',
      'Supplier',
      'Batch Number',
      'SKU',
      'Location',
      'Operator',
      'Notes',
      'Custom',
      'Total Harga (Rp)',
    ]);
    
    for (int i = 0; i < historyMeasurements.length; i++) {
      var m = historyMeasurements[i];
      DateTime dt = m['tanggal'];
      
      rows.add([
        i + 1,
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}',
        m['product'] ?? '-',
        m['material_code'] ?? '-',  
        m['gross_weight']?.toStringAsFixed(3) ?? '-',  
        m['tare_weight']?.toStringAsFixed(3) ?? '-',   
        m['berat'] ?? '-',  
        m['unit'] ?? '-',
        m['quantity']?.toString() ?? '-',
        m['unit_weight']?.toStringAsFixed(4) ?? '-',
        m['client'] ?? '-',
        m['id_field'] ?? '-',
        m['supplier'] ?? '-',
        m['batch_number'] ?? '-',
        m['sku'] ?? '-',
        m['location'] ?? '-',
        m['operator'] ?? '-',
        m['notes'] ?? '-',
        m['custom'] ?? '-',
        m['hargaTotal'] ?? 0,
      ]);
    }
    
    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/riwayat_pengukuran_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ File disimpan: $path'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Buka',
          textColor: Colors.white,
          onPressed: () {
            OpenFile.open(path);
          },
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error ekspor CSV: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _exportToPDF() async {
  try {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'RIWAYAT PENGUKURAN TIMBANGAN',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Pengukuran: ${historyMeasurements.length}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Dicetak: ${DateTime.now().toString().substring(0, 19)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.4),   
                1: const pw.FlexColumnWidth(0.8),   
                2: const pw.FlexColumnWidth(1.0),   
                3: const pw.FlexColumnWidth(0.8),   
                4: const pw.FlexColumnWidth(0.5),   
                5: const pw.FlexColumnWidth(0.5),   
                6: const pw.FlexColumnWidth(0.5),   
                7: const pw.FlexColumnWidth(0.4),   
                8: const pw.FlexColumnWidth(0.5),   
                9: const pw.FlexColumnWidth(0.6),   
                10: const pw.FlexColumnWidth(0.8),  
                11: const pw.FlexColumnWidth(0.6),  
                12: const pw.FlexColumnWidth(0.8),  
                13: const pw.FlexColumnWidth(0.8),  
                14: const pw.FlexColumnWidth(0.6),  
                15: const pw.FlexColumnWidth(0.7),  
                16: const pw.FlexColumnWidth(0.7),  
                17: const pw.FlexColumnWidth(0.8),  
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    _buildPdfCell('No', isHeader: true),
                    _buildPdfCell('Tanggal\nWaktu', isHeader: true),
                    _buildPdfCell('Product', isHeader: true),
                    _buildPdfCell('Product\nCode', isHeader: true),
                    _buildPdfCell('Gross\n(kg)', isHeader: true),
                    _buildPdfCell('Tare\n(kg)', isHeader: true),
                    _buildPdfCell('Net\n(kg)', isHeader: true),
                    _buildPdfCell('Unit', isHeader: true),
                    _buildPdfCell('Qty\n(pcs)', isHeader: true),
                    _buildPdfCell('UW\n(kg/pcs)', isHeader: true),
                    _buildPdfCell('Client', isHeader: true),
                    _buildPdfCell('ID', isHeader: true),
                    _buildPdfCell('Supplier', isHeader: true),
                    _buildPdfCell('Batch No', isHeader: true),
                    _buildPdfCell('SKU', isHeader: true),
                    _buildPdfCell('Location', isHeader: true),
                    _buildPdfCell('Operator', isHeader: true),
                    _buildPdfCell('Notes', isHeader: true),
                  ],
                ),
                
                ...historyMeasurements.asMap().entries.map((entry) {
                  int index = entry.key;
                  var m = entry.value;
                  DateTime dt = m['tanggal'];
                  
                  return pw.TableRow(
                    children: [
                      _buildPdfCell('${index + 1}'),
                      _buildPdfCell(
                        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}\n'
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                      ),
                      _buildPdfCell(m['product'] ?? '-'),
                      _buildPdfCell(m['material_code'] ?? '-'),
                      _buildPdfCell(m['gross_weight']?.toStringAsFixed(3) ?? '-'),
                      _buildPdfCell(m['tare_weight']?.toStringAsFixed(3) ?? '-'),
                      _buildPdfCell(m['berat']?.toString() ?? '-'),
                      _buildPdfCell(m['unit'] ?? '-'),
                      _buildPdfCell(m['quantity']?.toString() ?? '-'),
                      _buildPdfCell(
                        m['unit_weight'] != null 
                          ? (m['unit_weight'] as double).toStringAsFixed(4)
                          : '-'
                      ),
                      _buildPdfCell(m['client'] ?? '-'),
                      _buildPdfCell(m['id_field'] ?? '-'),
                      _buildPdfCell(m['supplier'] ?? '-'),
                      _buildPdfCell(m['batch_number'] ?? '-'),
                      _buildPdfCell(m['sku'] ?? '-'),
                      _buildPdfCell(m['location'] ?? '-'),
                      _buildPdfCell(m['operator'] ?? '-'),
                      _buildPdfCell(m['notes'] ?? '-'),
                    ],
                  );
                }).toList(),
              ],
            ),
            
            pw.SizedBox(height: 12),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text(
                    'Total Records: ${historyMeasurements.length}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Total Gross: ${_calculateTotalGross().toStringAsFixed(3)} kg',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                  pw.Text(
                    'Total Tare: ${_calculateTotalTare().toStringAsFixed(3)} kg',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange,
                    ),
                  ),
                  pw.Text(
                    'Total Net: ${totalWeightKg.toStringAsFixed(3)} kg',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    
    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/riwayat_pengukuran_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ PDF disimpan: $path'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Buka',
          textColor: Colors.white,
          onPressed: () {
            OpenFile.open(path);
          },
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error ekspor PDF: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

pw.Widget _buildPdfCell(String text, {bool isHeader = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(3),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: isHeader ? 8 : 7,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );
}
  
  void _sendCommand(String command) {
    if (!isActuallyConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ Demo Mode: Timbangan tidak terhubung\n'
          '💡 Hubungkan timbangan via Settings untuk kirim command'
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  if (connectionType == 'bluetooth') {
    if (connection != null && connection!.isConnected) {
      try {
        connection!.output.add(Uint8List.fromList(command.codeUnits));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perintah dikirim (Bluetooth): $command'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        print('Error sending Bluetooth command: $e');
      }
    }
  } else if (connectionType == 'usb') {
    if (_usbHelper != null && _usbHelper!.isConnected) {
      _usbHelper!.sendCommand(command).then((success) {
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Perintah dikirim (USB): $command'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }
}
  
  void _showCommandDialog() {
    TextEditingController commandController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Perintah ke Timbangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Perintah umum timbangan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• TARE → Tare'),
            const Text('• ZERO → Reset nol'),
            const Text('• PRINT → Minta kirim data'),
            const Text('• UNIT:KG → Ganti ke kg'),
            const SizedBox(height: 16),
            TextField(
              controller: commandController,
              decoration: const InputDecoration(
                labelText: 'Perintah',
                hintText: 'Contoh: TARE',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    commandController.text = 'TARE';
                  },
                  child: const Text('TARE'),
                ),
                ElevatedButton(
                  onPressed: () {
                    commandController.text = 'ZERO';
                  },
                  child: const Text('ZERO'),
                ),
                ElevatedButton(
                  onPressed: () {
                    commandController.text = 'PRINT';
                  },
                  child: const Text('PRINT'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              String cmd = commandController.text.trim();
              if (cmd.isNotEmpty) {
                _sendCommand('$cmd\r\n');
              }
              Navigator.pop(context);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
  
  void _requestData() {
    if (!isActuallyConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ Demo Mode: Timbangan tidak terhubung\n'
          '💡 Hubungkan timbangan via Settings untuk request data'
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  if (connection != null && connection!.isConnected) {
    try {
      connection!.output.add(Uint8List.fromList('PRINT\r\n'.codeUnits));
      
      String timestamp = DateTime.now().toString().substring(11, 19);
      setState(() {
        printLog.add('$timestamp - PRINT sent ${connectionMode == 'manual' ? '(Manual Mode - Waiting for data...)' : ''}');
        rawDataLog.add('$timestamp: >> PRINT SENT');
        
        if (printLog.length > 50) {
          printLog.removeAt(0);
        }
      });
      
      NotificationHelper.showInfo(context, 'PRINT dikirim');
    } catch (e) {
      print('Error sending PRINT: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timbangan tidak terhubung'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

void _autoSaveAndPrintManual() async {
  if (!mounted) return;
  
  if (currentWeight == "0.0" || currentWeight == "0.00" || currentWeight.isEmpty) {
    return;
  }
  
  double? weightValue = double.tryParse(currentWeight);
  if (weightValue == null || weightValue <= 0) {
    return;
  }

  try {
    final template = await dbHelper.getActiveLabelTemplate();
    
    if (template == null) {
      print('⚠️ No active template - skip auto-print');
      return;
    }

    final autoData = LabelPrintService.prepareDataForPrint(
  berat: double.parse(currentWeight),
  unit: selectedUnit,
  namaBarang: selectedBarang?['nama'] ?? 'Tanpa Nama',
  kategori: selectedBarang?['kategori'] ?? '-',
  operator: 'Auto',
  hargaPerKg: selectedBarang?['harga'],
  
  quantity: calculatedQuantity > 0 ? calculatedQuantity : null,
  unitWeight: isUnitWeightSet ? unitWeight : null,
  sampleCount: isSamplingMode ? sampleCount : null,
);

    String nomorResi = 'AUTO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    Map<String, dynamic> resi = {
      'nomor': nomorResi,
      'tanggal': DateTime.now().toString(),
      'barang': selectedBarang != null ? selectedBarang!['nama'] : 'Tanpa Nama',
      'kategori': selectedBarang != null ? selectedBarang!['kategori'] : '-',
      'berat': currentWeight,
      'unit': selectedUnit,
      'beratKg': _convertToKg(double.parse(currentWeight)),
      'hargaPerKg': selectedBarang != null ? selectedBarang!['harga'] : 0,
      'totalHarga': selectedBarang != null && selectedBarang!['harga'] > 0 
          ? int.parse(_calculatePrice()) 
          : 0,
    };
    
    Map<String, dynamic> pengukuran = {
      'tanggal': DateTime.now().toString(),
      'barang': selectedBarang != null ? selectedBarang!['nama'] : 'Tanpa Nama',
      'kategori': selectedBarang != null ? selectedBarang!['kategori'] : '-',
      'berat': currentWeight,
      'unit': selectedUnit,
      'beratKg': _convertToKg(double.parse(currentWeight)),
      'hargaTotal': selectedBarang != null && selectedBarang!['harga'] > 0 
          ? int.parse(_calculatePrice()) 
          : 0,
    };
    
    int resiId = await dbHelper.createResi(resi);
    await dbHelper.createPengukuran(pengukuran);
    
    resi['id'] = resiId;
    
    setState(() {
      resiList.insert(0, resi);
      
      historyMeasurements.insert(0, {
        'tanggal': DateTime.now(),
        'barang': selectedBarang != null ? selectedBarang!['nama'] : 'Tanpa Nama',
        'kategori': selectedBarang != null ? selectedBarang!['kategori'] : '-',
        'berat': currentWeight,
        'unit': selectedUnit,
        'beratKg': _convertToKg(double.parse(currentWeight)),
        'hargaTotal': selectedBarang != null && selectedBarang!['harga'] > 0 
            ? int.parse(_calculatePrice()) 
            : 0,
      });
      
      String barangInfo = selectedBarang != null 
          ? '${selectedBarang!['nama']} - ' 
          : '';
      String timestamp = DateTime.now().toString().substring(11, 19);
      historyData.insert(0, '$timestamp - $barangInfo$currentWeight ${selectedUnit.toLowerCase()} (AUTO-MANUAL)');
      
      if (historyData.length > 50) {
        historyData.removeLast();
      }
    });
    
    setState(() {
      String timestamp = DateTime.now().toString().substring(11, 19);
      rawDataLog.add('$timestamp: >> AUTO-SAVE & AUTO-PRINT (Mode Manual)');
    });
    
    print('✅ Data tersimpan ke SQLite dengan ID: $resiId');
    
    await _printWithTemplate(template, autoData);
    
  } catch (e) {
    print('❌ Error auto-save manual mode: $e');
    if (mounted) {
      setState(() {
        String timestamp = DateTime.now().toString().substring(11, 19);
        rawDataLog.add('$timestamp: >> ERROR auto-save: $e');
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menyimpan data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  void _showPrintLog() {
    showDialog( 
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log PRINT'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: printLog.isEmpty
              ? const Center(child: Text('Belum ada log'))
              : ListView.builder(
                  itemCount: printLog.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        printLog[printLog.length - 1 - index],
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          if (printLog.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  printLog.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('Hapus Log'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
  
  void _showBarangList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Barang',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Colors.green,
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddBarangDialog();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: barangList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Belum ada barang', style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddBarangDialog();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Barang'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: barangList.length,
                      itemBuilder: (context, index) {
                        var barang = barangList[index];
                        bool isSelected = selectedBarang == barang;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isSelected ? Colors.blue[50] : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                barang['nama'][0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            title: Text(
                              barang['nama'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kategori: ${barang['kategori']}'),
                                if (barang['harga'] != null && barang['harga'] > 0)
                                  Text('Harga: Rp ${barang['harga']}/kg'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.check, size: 20),
                                          SizedBox(width: 8),
                                          Text('Pilih'),
                                        ],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedBarang = barang;
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Barang dipilih: ${barang['nama']}'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                      onTap: () {
                                        Future.delayed(Duration.zero, () {
                                          Navigator.pop(context);
                                          _showEditBarangDialog(index);
                                        });
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Hapus', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                      onTap: () {
                                        _deleteBarang(index);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddBarangDialog() {
  TextEditingController namaController = TextEditingController();
  TextEditingController kategoriController = TextEditingController();
  TextEditingController hargaController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tambah Barang'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang *',
                hintText: 'Contoh: Beras Premium',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kategoriController,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                hintText: 'Contoh: Sembako',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga per kg (Opsional)',
                hintText: 'Contoh: 15000',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (namaController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nama barang harus diisi!'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            Map<String, dynamic> newBarang = {
              'nama': namaController.text.trim(),
              'kategori': kategoriController.text.trim().isEmpty 
                  ? 'Umum' 
                  : kategoriController.text.trim(),
              'harga': hargaController.text.trim().isEmpty 
                  ? 0 
                  : int.tryParse(hargaController.text.trim()) ?? 0,
            };
            
            try {
              int id = await dbHelper.createBarang(newBarang);
              newBarang['id'] = id;
              newBarang['created'] = DateTime.now().toIso8601String();
              
              setState(() {
                barangList.add(newBarang);
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Barang berhasil ditambahkan'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              print('❌ Error: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
  
  void _showEditBarangDialog(int index) {
    var barang = barangList[index];
    TextEditingController namaController = TextEditingController(text: barang['nama']);
    TextEditingController kategoriController = TextEditingController(text: barang['kategori']);
    TextEditingController hargaController = TextEditingController(
      text: barang['harga'] > 0 ? barang['harga'].toString() : '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Barang'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kategoriController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga per kg',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (namaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama barang harus diisi!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              setState(() {
                barangList[index] = {
                  'nama': namaController.text.trim(),
                  'kategori': kategoriController.text.trim().isEmpty 
                      ? 'Umum' 
                      : kategoriController.text.trim(),
                  'harga': hargaController.text.trim().isEmpty 
                      ? 0 
                      : int.tryParse(hargaController.text.trim()) ?? 0,
                  'created': barang['created'],
                  'updated': DateTime.now().toString(),
                };
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Barang berhasil diupdate!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
  
  void _deleteBarang(int index) async {  
  var barang = barangList[index];
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus Barang?'),
      content: Text('Apakah Anda yakin ingin menghapus "${barang['nama']}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {  
            try {
              await dbHelper.deleteBarang(barang['id']);
              
              setState(() {
                if (selectedBarang == barang) {
                  selectedBarang = null;
                }
                barangList.removeAt(index);
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Barang berhasil dihapus!'),
                  backgroundColor: Colors.orange,
                ),
              );
            } catch (e) {
              print('❌ Error: $e');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}

void _setTara() {
  if (!isActuallyConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ Demo Mode: Timbangan tidak terhubung\n'
          '💡 Hubungkan timbangan via Settings untuk menggunakan fitur ini'
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  if (connection != null && connection!.isConnected) {
    try {
      double currentWeightValue = double.parse(currentWeight);
      
      if (taraValue > 0.001) {
        setState(() {
          taraValue = 0.0;
        });
        
        connection!.output.add(Uint8List.fromList('ZERO\r\n'.codeUnits));
        
        setState(() {
          String timestamp = DateTime.now().toString().substring(11, 19);
          rawDataLog.add('$timestamp: >> TARE RESET (ZERO sent)');
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Tara direset ke 0'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          taraValue = currentWeightValue;
        });
        
        connection!.output.add(Uint8List.fromList('TARE\r\n'.codeUnits));
        
        setState(() {
          String timestamp = DateTime.now().toString().substring(11, 19);
          rawDataLog.add('$timestamp: >> TARE set: $currentWeightValue $selectedUnit');
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ TARE: $currentWeightValue $selectedUnit'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('Error toggling TARE: $e');
      _setTaraSoftware();
    }
  } else {
    _setTaraSoftware();
  }
}

// ✅ FIXED VERSION - _editManualInput function
// Perbaikan: undefined 'modeType', missing brackets, notification consistency

void _editManualInput(int index) {
  String fieldLabel = customFields[index]['label']!;
  
  bool hasDatabase = ['Product', 'Client', 'ID', 'Supplier'].contains(fieldLabel);
  
  if (hasDatabase) {
    if (fieldLabel == 'Product') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductManagementPage(
            onProductSelected: (product) async {
              print('\n🎯 ═══════════════════════════════════════════════');
              print('📦 PRODUCT SELECTED: ${product.productName}');
              print('   Product Code: ${product.productCode ?? "-"}');
              print('   Unit Weight: ${product.unitWeight ?? 0.0} kg/pcs');
              print('   Pre-Tare: ${product.preTare ?? 0.0} kg');
              print('   Target: ${product.targetValue ?? 0.0} kg');
              print('   Low Limit: ${product.lowLimit ?? 0.0} kg');
              print('   Hi Limit: ${product.hiLimit ?? 0.0} kg');
              print('═══════════════════════════════════════════════\n');
              
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 150));
              
              if (!mounted) return;
              
              setState(() {
                selectedProduct = product;
                
                // ✅ Update Product field
                int productFieldIndex = customFields.indexWhere((f) => f['label'] == 'Product');
                if (productFieldIndex != -1) {
                  customFields[productFieldIndex]['value'] = product.productName;
                }
                
                // ✅ Auto-fill Product Code if exists
                int productCodeIndex = customFields.indexWhere((f) => f['label'] == 'Product Code');
                if (productCodeIndex != -1 && (product.productCode?.isNotEmpty ?? false)) {
                  customFields[productCodeIndex]['value'] = product.productCode!;
                  print('✅ Product Code auto-filled: ${product.productCode}');
                }
                
                // ✅ Apply Pre-Tare if exists
                if (product.preTare != null && product.preTare! > 0) {
                  preTareValue = product.preTare!;
                  print('\n🔧 PRE-TARE APPLIED');
                  print('   Pre-Tare Value: ${preTareValue} kg');
                  print('   This will be deducted from Net Weight automatically\n');
                } else {
                  preTareValue = 0.0;
                  print('\nℹ️ No Pre-Tare set for this product\n');
                }
                
                // ✅ Activate Counting Mode if ready
                if (product.isReadyForBasicCountingMode) {
                  print('\n🔥 ACTIVATING COUNTING MODE...');
                  
                  unitWeight = product.unitWeight ?? 0.0;
                  isUnitWeightSet = unitWeight > 0;
                  isSamplingMode = false;
                  
                  // ✅ Determine mode type
                  String modeType = product.isReadyForFullCountingMode ? 'FULL' : 'BASIC';
                  
                  if (product.isReadyForFullCountingMode) {
                    print('   Mode: FULL COUNTING (with thresholds)');
                    lowThreshold = product.lowLimit ?? 0.1;
                    highThreshold = product.hiLimit ?? 50.0;
                  } else {
                    print('   Mode: BASIC COUNTING (UW only, no thresholds)');
                  }
                  
                  print('   ✅ unitWeight: ${(unitWeight * 1000).toStringAsFixed(4)} g/pcs');
                  print('   ✅ preTareValue: $preTareValue kg');
                  print('   ✅ isUnitWeightSet: $isUnitWeightSet');
                  
                  // ✅ Calculate quantity from current weight
                  try {
                    double? currentWeightValue = double.tryParse(currentWeight);
                    if (currentWeightValue != null) {
                      double currentWeightKg = _convertToKg(currentWeightValue);
                      
                      // Check weight status
                      if (currentWeightKg < lowThreshold) {
                        weightStatus = 'Low';
                      } else if (currentWeightKg > highThreshold) {
                        weightStatus = 'High';
                      } else {
                        weightStatus = 'OK';
                      }
                      
                      // Calculate quantity
                      if (unitWeight > 0) {
                        calculatedQuantity = (currentWeightKg / unitWeight).round();
                        print('   ✅ calculatedQuantity: $calculatedQuantity pcs');
                      }
                    }
                  } catch (e) {
                    print('   ⚠️ Error calculating: $e');
                    calculatedQuantity = 0;
                  }
                  
                  print('✅ COUNTING MODE ACTIVATED!\n');
                  
                  // ✅ Show success notification
                  if (mounted) {
                    String thresholdInfo = product.isReadyForFullCountingMode 
                        ? '🎯 Threshold: ${product.lowLimit} - ${product.hiLimit} kg\n'
                        : '⚠️ Threshold: Using default\n';
                    
                    String preTareInfo = (product.preTare != null && product.preTare! > 0)
                        ? '🔧 Pre-Tare: ${product.preTare} kg (will be deducted automatically)\n'
                        : '';
                    
                    NotificationHelper.showSuccess(
                      context,
                      '✅ COUNTING MODE AKTIF! ($modeType)\n'
                      '📦 Product: ${product.productName}\n'
                      '📝 Product Code: ${product.productCode?.isNotEmpty ?? false ? product.productCode : "-"}\n'
                      '⚖️ Unit Weight: ${(unitWeight * 1000).toStringAsFixed(4)} g/pcs\n'
                      '$preTareInfo'
                      '$thresholdInfo'
                      '💡 Letakkan barang untuk hitung quantity',
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ COUNTING MODE ($modeType): ${product.productName}\n'
                          '⚖️ UW: ${(unitWeight * 1000).toStringAsFixed(1)} g/pcs'
                          '${(product.preTare != null && product.preTare! > 0) ? "\n🔧 Pre-Tare: ${product.preTare} kg" : ""}'
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  
                } else {
                  // ✅ Product doesn't have Unit Weight
                  isUnitWeightSet = false;
                  isSamplingMode = false;
                  unitWeight = 0.0;
                  calculatedQuantity = 0;
                  
                  print('⚠️ Product incomplete: Unit Weight not set');
                  
                  if (mounted) {
                    NotificationHelper.showInfo(
                      context,
                      '📦 Product selected: ${product.productName}\n'
                      '⚠️ Unit Weight: NOT SET\n'
                      '💡 Set Unit Weight di Product Management untuk enable Counting Mode',
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '📦 Product: ${product.productName}\n'
                          '⚠️ Counting Mode: OFF (Incomplete data)'
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              });
              
              // ✅ Save custom fields
              await _saveCustomFields();
              
              if (!mounted) return;
              
              // ✅ Force UI refresh to show Pre-Tare
              await Future.delayed(const Duration(milliseconds: 200));
              
              if (!mounted) return;
              
              setState(() {
                print('🔄 UI REFRESH - Pre-Tare should now be visible');
                print('   preTareValue: $preTareValue kg');
                print('   Display should show: "${preTareValue > 0 ? "Pre-Tare" : "UW"}"');
              });
            },
          ),
        ),
      );
      
    } else if (fieldLabel == 'Client') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientManagementPage(
            onClientSelected: (client) async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (!mounted) return;
              
              int clientFieldIndex = customFields.indexWhere((f) => f['label'] == 'Client');
              
              setState(() {
                selectedClient = client;
                if (clientFieldIndex != -1) {
                  customFields[clientFieldIndex]['value'] = client.displayName;
                }
              });
              
              await _saveCustomFields();
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Client selected: ${client.displayName}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
      
    } else if (fieldLabel == 'ID') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IdManagementPage(
            onIdSelected: (id) async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (!mounted) return;
              
              int idFieldIndex = customFields.indexWhere((f) => f['label'] == 'ID');
              
              setState(() {
                selectedId = id;
                if (idFieldIndex != -1) {
                  customFields[idFieldIndex]['value'] = id.displayFull;
                }
              });
              
              await _saveCustomFields();
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ ID selected: ${id.displayFull}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
      
    } else if (fieldLabel == 'Supplier') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SupplierManagementPage(
            onSupplierSelected: (supplier) async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (!mounted) return;
              
              int supplierFieldIndex = customFields.indexWhere((f) => f['label'] == 'Supplier');
              
              setState(() {
                selectedSupplier = supplier;
                if (supplierFieldIndex != -1) {
                  customFields[supplierFieldIndex]['value'] = supplier.supplierName;
                }
              });
              
              await _saveCustomFields();
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Supplier selected: ${supplier.supplierName}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}

void _showFieldOptionsMenu(int index) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Field: ${customFields[index]['label']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Edit Value'),
            onTap: () {
              Navigator.pop(context);
              _editManualInput(index);
            },
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.orange),
            title: const Text('Change Field To...'),
            onTap: () {
              Navigator.pop(context);
              _showChangeFieldDialog(index);
            },
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.green),
            title: const Text('Add New Field'),
            onTap: () {
              Navigator.pop(context);
              _addNewField();
            },
          ),
          const Divider(),
          
          if (customFields.length > 1)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Field'),
              onTap: () {
                Navigator.pop(context);
                _removeField(index);
              },
            ),
        ],
      ),
    ),
  );
}

void _showChangeFieldDialog(int index) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Change Field To'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableFieldOptions.length,
          itemBuilder: (context, i) {
            String option = availableFieldOptions[i];
            bool isCurrentlyUsed = customFields.any((f) => f['label'] == option);
            
            return ListTile(
              title: Text(option),
              trailing: isCurrentlyUsed
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                if (option == 'Custom') {
                  Navigator.pop(context);
                  _showCustomFieldNameDialog(index);
                } else {
                  setState(() {
                    customFields[index]['label'] = option;
                    customFields[index]['value'] = '';
                  });
                  _saveCustomFields();  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Field changed to: $option'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

void _showCustomFieldNameDialog(int index) {
  TextEditingController nameController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Custom Field Name'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'e.g., Batch Number',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isNotEmpty) {
              setState(() {
                customFields[index]['label'] = nameController.text.trim();
                customFields[index]['value'] = '';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Custom field created: ${nameController.text}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

void _addNewField() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Field'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableFieldOptions.length,
            itemBuilder: (context, i) {
              String option = availableFieldOptions[i];
              bool isAlreadyUsed = customFields.any((f) => f['label'] == option);
              
              return ListTile(
                title: Text(option),
                trailing: isAlreadyUsed
                    ? const Icon(Icons.check, color: Colors.grey)
                    : const Icon(Icons.add, color: Colors.green),
                enabled: !isAlreadyUsed,
                onTap: () {
                  if (option == 'Custom') {
                    Navigator.pop(context);
                    _addCustomField();
                  } else {
                    setState(() {
                      int newIndex = customFields.length;
                      customFields.add({'label': option, 'value': ''});
                      
                      _fieldControllers[newIndex] = TextEditingController(text: '');
                    });
                    _saveCustomFields();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added field: $option'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

void _addCustomField() {
  TextEditingController nameController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New Custom Field'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Field name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isNotEmpty) {
              setState(() {
                customFields.add({
                  'label': nameController.text.trim(),
                  'value': '',
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Custom field added: ${nameController.text}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

void _removeField(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Field?'),
        content: Text('Remove "${customFields[index]['label']}" field?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _fieldControllers[index]?.dispose();
                
                customFields.removeAt(index);
                
                final newControllers = <int, TextEditingController>{};
                for (int i = 0; i < customFields.length; i++) {
                  if (i < index) {
                    newControllers[i] = _fieldControllers[i]!;
                  } else {
                    newControllers[i] = _fieldControllers[i + 1]!;
                  }
                }
                _fieldControllers.clear();
                _fieldControllers.addAll(newControllers);
              });
              _saveCustomFields();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Field removed'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  double _convertFromKg(double weightInKg, String unit) {
  if (unit == "KG") return weightInKg;
  if (unit == "GRAM") return weightInKg * 1000;
  if (unit == "ONS") return weightInKg * 10;
  if (unit == "POUND") return weightInKg / 0.453592;
  if (unit == "MG") return weightInKg * 1000000;
  return weightInKg;
}

double _applyTara(double rawWeight) {
  if (taraValue == 0.0) return rawWeight;
  
  double taraInKg = taraValue / 1000;
  
  double rawWeightInKg = _convertToKg(rawWeight);
  
  double netWeightInKg = rawWeightInKg - taraInKg;
  
  double netWeightInDisplayUnit = _convertFromKg(netWeightInKg, selectedUnit);
  
  print('🔧 Tara Applied:');
  print('   Raw Weight: ${rawWeight.toStringAsFixed(3)} $selectedUnit');
  print('   Raw Weight (kg): ${rawWeightInKg.toStringAsFixed(3)} kg');
  print('   Tara Value: ${taraValue.toStringAsFixed(3)} g');
  print('   Tara in KG: ${taraInKg.toStringAsFixed(3)} kg');
  print('   Net Weight (kg): ${netWeightInKg.toStringAsFixed(3)} kg');
  print('   Net Weight ($selectedUnit): ${netWeightInDisplayUnit.toStringAsFixed(3)} $selectedUnit');
  
  return netWeightInDisplayUnit < 0 ? 0.0 : netWeightInDisplayUnit;
}

double _applyPreTare(double netWeightInKg) {
  if (preTareValue == 0.0) {
    print('ℹ️ No Pre-Tare set (preTareValue = 0)');
    return netWeightInKg;
  }
  
  double totalPreTare = 0.0;
  
  if (calculatedQuantity > 0) {
    totalPreTare = preTareValue * calculatedQuantity;
  } else {
    totalPreTare = preTareValue;
  }
  
  double result = netWeightInKg - totalPreTare;
  
  print('🔧 Pre-Tare Applied:');
  print('   Net Before: ${netWeightInKg.toStringAsFixed(3)} kg');
  print('   Pre-Tare/pcs: ${preTareValue.toStringAsFixed(4)} kg');
  print('   Quantity: ${calculatedQuantity > 0 ? calculatedQuantity : 1} pcs');
  print('   Total Pre-Tare: ${totalPreTare.toStringAsFixed(3)} kg');
  print('   Net After: ${result.toStringAsFixed(3)} kg');
  
  return result < 0 ? 0.0 : result;
}

void _setTaraSoftware() {
  try {
    double current = double.parse(currentWeight);
    
    double taraInGrams = current;
    if (selectedUnit == "KG") {
      taraInGrams = current * 1000;
    } else if (selectedUnit == "ONS") {
      taraInGrams = current * 100;
    } else if (selectedUnit == "POUND") {
      taraInGrams = current * 453.592;
    } else if (selectedUnit == "MG") {
      taraInGrams = current / 1000;
    }
    
    setState(() {
      taraValue = taraInGrams;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ Tara Virtual: ${current.toStringAsFixed(currentDecimalPlaces)} $selectedUnit'
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    print('Error setting tara: $e');
  }
}

Future<void> _printStatisticalSummary() async {
    if (!isStatisticalSession || statisticalWeights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Tidak ada data statistik untuk di-print'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      final template = await dbHelper.getActiveLabelTemplate();
      
      if (template == null) {
        _showError('Tidak ada template label aktif.');
        return;
      }
      
      String? operatorName;
      int operatorIndex = customFields.indexWhere((f) => f['label'] == 'Operator');
      if (operatorIndex != -1) {
        operatorName = customFields[operatorIndex]['value'];
      }
      
      String? productName;
      if (selectedProduct != null) {
        productName = selectedProduct!.productName;
      } else {
        int productIndex = customFields.indexWhere((f) => f['label'] == 'Product');
        if (productIndex != -1) {
          productName = customFields[productIndex]['value'];
        }
      }
      
      print('\n🖨️ ═══════════════════════════════════════════════════');
      print('📊 PRINTING STATISTICAL SUMMARY');
      print('   Weights: ${statisticalWeights.length}');
      print('   Operator: ${operatorName ?? "-"}');
      print('   Product: ${productName ?? "-"}');
      print('═══════════════════════════════════════════════════\n');
      
      String summaryContent = LabelPrintService.renderStatisticalSummary(
  template,
  statisticalWeights,
  operatorName: operatorName,
  productName: productName,
  unit: selectedUnit,                    
  decimalPlaces: currentDecimalPlaces,   
);

print('📊 Summary Format Settings:');
print('   Unit: $selectedUnit (current weighing unit)');
print('   Decimals: $currentDecimalPlaces (from raw timbangan)');
      
      if (summaryContent.isEmpty) {
        _showError('Gagal generate summary');
        return;
      }
      
      await _printSummaryWithTemplate(template, summaryContent);
      
    } catch (e) {
      print('❌ Error printing statistical summary: $e');
      _showError('Error: $e');
    }
  }

  Future<void> _printSummaryWithTemplate(
    LabelTemplate template,
    String summaryContent,
  ) async {
    if (defaultPrinterAddress == null || defaultPrinterAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Printer tidak dikonfigurasi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    try {
      print('\n🔍 ═══════════════════════════════════════════════════');
      print('📊 STATISTICAL SUMMARY PRINT MODE');
      print('   ⚠️ Forcing ESC/POS (receipt printer)');
      print('   Ignoring template.printerType for this job');
      print('═══════════════════════════════════════════════════════\n');
      
      bool isTSPL = false; 
      
      print('🖨️ Connecting to printer: $defaultPrinterName');
      
      printerHelper = BluetoothPrinterHelper();
      bool connected = await printerHelper!.connect(
        defaultPrinterAddress!,
        printerName: defaultPrinterName,
      );
      
      if (!mounted) return;
      Navigator.pop(context);
      
      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal koneksi ke printer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      print('📄 Sending statistical summary as ESC/POS format...');
      bool success = await printerHelper!.printFromTemplate(summaryContent);
      
      await printerHelper!.disconnect();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Statistical Summary berhasil dicetak'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearRawLog() {
    setState(() {
      rawDataLog.clear();
    });
  }

  Future<void> _disconnect() async {
  print('\n🔌 DISCONNECT called');
  print('   connectionType: $connectionType');
  print('   _hasSkippedConnection: $_hasSkippedConnection');
  
  if (connectionType == 'bluetooth') {
    if (connection != null) {
      await connection!.close();
      setState(() {
        selectedDevice = null;
        connection = null;
        currentWeight = "0.0";
        
        // ✅ NEW: JANGAN reset _hasSkippedConnection
        // Biar user tidak kembali ke device list
        print('   ℹ️ Keeping _hasSkippedConnection = $_hasSkippedConnection (demo mode tetap aktif)');
      });
    }
  } else if (connectionType == 'usb') {
    await _usbDataSubscription?.cancel();
    await _usbHelper?.disconnect();
    setState(() {
      selectedUsbDevice = null;
      currentWeight = "0.0";
      
      // ✅ NEW: JANGAN reset _hasSkippedConnection
      print('   ℹ️ Keeping _hasSkippedConnection = $_hasSkippedConnection (demo mode tetap aktif)');
    });
  }
  
  print('✅ Disconnected');
  print('   _hasSkippedConnection: $_hasSkippedConnection');
  print('   User akan tetap di weight display (tidak kembali ke device list)\n');
  
  // ✅ NEW: Show notification
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ Disconnected from scale\n'
          '💡 Demo mode masih aktif - data tidak akan diparse'
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

  @override
  void dispose() {
    _saveTimer?.cancel();
    connection?.dispose();
    _scrollController.dispose();

    _usbDataSubscription?.cancel();
  _usbHelper?.dispose();
    
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    _fieldControllers.clear();
    
    super.dispose();
  }


void _resetCounter() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset Counter?'),
      content: Text('Counter: $weighingCounter\nTotal: ${totalWeightKg.toStringAsFixed(3)} kg\n\nReset data ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              weighingCounter = 0;
              totalWeightKg = 0.0;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Counter direset'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
}

void _setThreshold() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Set Threshold'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pilih threshold mana yang ingin diubah:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                
                String initialValue;
                if (selectedProduct != null && selectedProduct!.lowLimit > 0) {
                  initialValue = selectedProduct!.lowLimit.toString();
                  print('🎯 Auto-fill Low Limit from Product: ${selectedProduct!.lowLimit} kg');
                } else {
                  initialValue = lowThreshold.toString();
                  print('ℹ️ Using current Low Limit: $lowThreshold kg');
                }
                
                final result = await showNumpadDialog(
                  context: context,
                  title: 'Input Low Limit',
                  initialValue: initialValue,
                  unit: 'kg',
                );
                
                if (result != null && result.isNotEmpty) {
                  setState(() {
                    lowThreshold = double.tryParse(result) ?? 0.100;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Low Threshold: $lowThreshold kg'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.arrow_downward),
              label: const Text('Low Limit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[900],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('OK Value tidak perlu diubah.\nIni adalah range antara Low dan High.'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('OK Value'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[900],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                
                String initialValue;
                if (selectedProduct != null && selectedProduct!.hiLimit > 0) {
                  initialValue = selectedProduct!.hiLimit.toString();
                  print('🎯 Auto-fill High Limit from Product: ${selectedProduct!.hiLimit} kg');
                } else {
                  initialValue = highThreshold.toString();
                  print('ℹ️ Using current High Limit: $highThreshold kg');
                }
                
                final result = await showNumpadDialog(
                  context: context,
                  title: 'Input High Limit',
                  initialValue: initialValue,
                  unit: 'kg',
                );
                
                if (result != null && result.isNotEmpty) {
                  setState(() {
                    highThreshold = double.tryParse(result) ?? 50.0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ High Threshold: $highThreshold kg'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.arrow_upward),
              label: const Text('High Limit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[900],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    ),
  );
}

void _onStatusButtonTap(String status) async {
  if (status == 'Low') {
  String initialValue;
  if (selectedProduct != null && selectedProduct!.lowLimit > 0) {
    initialValue = selectedProduct!.lowLimit.toStringAsFixed(2);
    print('🎯 Auto-fill Low Limit from Product: ${selectedProduct!.lowLimit} kg');
  } else if (lowThreshold > 0.001) {
    initialValue = lowThreshold.toStringAsFixed(2);
    print('ℹ️ Using current Low Limit: $initialValue kg');
  } else {
    initialValue = '0.00';  
    print('ℹ️ Using default Low Limit: 0.00 kg');
  }
    
    final result = await showNumpadDialog(
      context: context,
      title: 'Input Low Limit',
      initialValue: initialValue,
      unit: 'kg',
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        lowThreshold = double.tryParse(result) ?? 0.100;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Low Threshold: $lowThreshold kg'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
  } else if (status == 'High') {
  String initialValue;
  if (selectedProduct != null && selectedProduct!.hiLimit > 0) {
    initialValue = selectedProduct!.hiLimit.toStringAsFixed(2);
    print('🎯 Auto-fill High Limit from Product: ${selectedProduct!.hiLimit} kg');
  } else if (highThreshold > 0.001) {
    initialValue = highThreshold.toStringAsFixed(2);
    print('ℹ️ Using current High Limit: $initialValue kg');
  } else {
    initialValue = '0.00';  
    print('ℹ️ Using default High Limit: 0.00 kg');
  }
    
    final result = await showNumpadDialog(
      context: context,
      title: 'Input High Limit',
      initialValue: initialValue,
      unit: 'kg',
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        highThreshold = double.tryParse(result) ?? 50.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ High Threshold: $highThreshold kg'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status OK: $lowThreshold kg - $highThreshold kg'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    resizeToAvoidBottomInset: true,
    appBar: ResponsiveAppBar(
  title: 'T-Connect',
  isConnected: isConnected,
  showRawData: showRawData,
  deviceName: selectedDevice?.name ?? (selectedUsbDevice?.productName ?? 'USB Device'),  // ✅ GABUNGKAN JADI SATU
  connectionMode: connectionMode,
  defaultPrinterName: defaultPrinterName,
  historyCount: historyMeasurements.length,
  receiptsCount: resiList.length,

      isPrintEnabled: isPrintEnabled,
      onTogglePrint: () {
        _savePrintSetting(!isPrintEnabled);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPrintEnabled 
                ? '🖨️ Printing ENABLED\nData will be printed after save' 
                : '🔇 Printing DISABLED\nData will be saved only'
            ),
            backgroundColor: isPrintEnabled ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      
      onToggleRawData: () {
        setState(() {
          showRawData = !showRawData;
        });
      },
      onDatabaseViewer: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DatabaseViewerPage(),
          ),
        );
      },
      onBarangList: _showBarangList,
      onHistory: _showHistoryMeasurements,
      onReceipts: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TransactionReceiptPage(),
          ),
        );
      },
      onDashboard: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const IndustrialDashboard(),
          ),
        );
      },
      onLabelDesigner: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VisualLabelDesignerPage(),
          ),
        );
      },
      
      onSettings: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
        
        print('🔄 User returned from Settings, reloading printer...');
        await _loadDefaultPrinter();
        
        if (mounted) {
          setState(() {});  
        }
        
        print('✅ Printer settings reloaded: $defaultPrinterName');
      },

      onStatisticalSession: _showStatisticalWeighingDialog,
      
      onRequestPrint: _requestData,
      onPrintLog: _showPrintLog,
      onSendCommand: _showCommandDialog,
      onChangePrinter: () async {
        await _clearDefaultPrinter();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Printer default dihapus. Pilih ulang saat print berikutnya.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    ),
    body: _shouldShowDeviceList() 
        ? _buildDeviceList()       // Show device list
        : _buildWeightDisplay(),   // Show weight display (demo atau connected)
  );
}

bool _shouldShowDeviceList() {
  print('🔍 _shouldShowDeviceList called:');
  print('   _hasSkippedConnection: $_hasSkippedConnection');
  print('   selectedDevice: $selectedDevice');
  print('   selectedUsbDevice: $selectedUsbDevice');
  print('   isConnected: $isConnected');

  if (_hasSkippedConnection) {
    print('   → Result: false (user skipped)');
    return false;
  }
  
  if (isConnected) {
    print('   → Result: false (connected)');
    return false;
  }
  
  // Show device list jika belum skip dan belum connect
  print('   → Result: true (show device list)');
  return true;
}

  Widget _buildDeviceList() {
  return DefaultTabController(
    length: 2,
    initialIndex: connectionType == 'usb' ? 1 : 0,
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.lightBlue[300],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.devices, size: 60, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
  'Pilih Perangkat Timbangan',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
),
const SizedBox(height: 8),
const Text(
  'Atau skip untuk demo mode',
  style: TextStyle(
    fontSize: 14,
    color: Colors.white70,
  ),
),
const SizedBox(height: 16),

ElevatedButton.icon(
  onPressed: () {
    print('🎯 Skip button pressed - activating demo mode');
    
    setState(() {
      // ✅ SET FLAG!
      _hasSkippedConnection = true;
      
      // Pastikan tidak ada device selected
      selectedDevice = null;
      selectedUsbDevice = null;
      
      print('✅ Demo mode activated:');
      print('   _hasSkippedConnection: $_hasSkippedConnection');
      print('   _shouldShowDeviceList(): ${_shouldShowDeviceList()}');
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ Demo Mode Aktif\n'
          '💡 Anda bisa eksplorasi semua fitur\n'
          '⚙️ Hubungkan timbangan via Settings kapan saja'
        ),
        backgroundColor: Colors.green,  // ✅ Ganti ke green (success)
        duration: Duration(seconds: 4),
      ),
    );
  },
  icon: const Icon(Icons.touch_app, size: 20),
  label: const Text(
    'Skip - Masuk Tanpa Koneksi',
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.blue[700],
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
  ),
),

const SizedBox(height: 16),
              
              // ✅ TABS: Bluetooth vs USB
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.blue[700],
                  unselectedLabelColor: Colors.white,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.bluetooth),
                      text: 'Bluetooth',
                    ),
                    Tab(
                      icon: Icon(Icons.usb),
                      text: 'USB',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        Expanded(
          child: TabBarView(
            children: [
              // ✅ TAB 1: BLUETOOTH DEVICES
              _buildBluetoothDeviceList(),
              
              // ✅ TAB 2: USB DEVICES
              _buildUsbDeviceList(),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildBluetoothDeviceList() {
  if (devices.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Tidak ada perangkat terpasang',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _getPairedDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: devices.length,
    itemBuilder: (context, index) {
      BluetoothDevice device = devices[index];
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.lightBlue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bluetooth, color: Colors.lightBlue[400], size: 28),
          ),
          title: Text(
            device.name ?? 'Unknown Device',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            device.address,
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: isConnecting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_ios, size: 18),
          onTap: () => _connectToDevice(device),
        ),
      );
    },
  );
}

Widget _buildUsbDeviceList() {
  if (usbDevices.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.usb_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Tidak ada USB device terdeteksi',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan timbangan terhubung via USB OTG',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _scanUsbDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan USB Devices'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: usbDevices.length,
    itemBuilder: (context, index) {
      UsbDevice device = usbDevices[index];
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.usb, color: Colors.green[400], size: 28),
          ),
          title: Text(
            device.productName ?? 'USB Device',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'VID: ${device.vid} | PID: ${device.pid}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: isConnecting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_ios, size: 18),
          onTap: () => _connectToUsbDevice(device),
        ),
      );
    },
  );
}

void _toggleGrossNet() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Toggle Gross/Net - Feature coming soon'),
      backgroundColor: Colors.blue,
    ),
  );
}

Future<void> _showSampleDialog() async {
  if (currentWeight == "0.0" || currentWeight == "0.00") {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ Letakkan barang di timbangan terlebih dahulu\n'
          '💡 Sample membutuhkan berat untuk menghitung Unit Weight'
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  final result = await showNumpadDialog(
    context: context,
    title: 'Sample Quantity',
    initialValue: '0',
    unit: 'pcs',
  );
  
  if (result == null || result.isEmpty) {
    return;
  }
  
  int quantity = int.tryParse(result) ?? 0;
  
  if (quantity <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Quantity harus lebih dari 0'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    // ✅ PERUBAHAN: Gunakan NET WEIGHT untuk hitung Unit Weight
    double netWeightValue = double.parse(netWeight);
    double netWeightInKg = _convertToKg(netWeightValue);
    
    // Hitung Unit Weight dari Net Weight
    double calculatedUW = netWeightInKg / quantity;
    
    setState(() {
      isSamplingMode = true;
      sampleCount = quantity;
      unitWeight = calculatedUW;
      isUnitWeightSet = true;
      sampleTotalWeight = netWeightInKg;
      calculatedQuantity = quantity;
    });
    
    print('\n✅ SAMPLE MODE ACTIVATED (NET-BASED)');
    print('   Net Weight: ${netWeightInKg.toStringAsFixed(3)} kg');
    print('   Quantity: $quantity pcs');
    print('   Unit Weight: ${(calculatedUW * 1000).toStringAsFixed(4)} g/pcs (${calculatedUW.toStringAsFixed(6)} kg/pcs)');
    print('   Formula: ${netWeightInKg.toStringAsFixed(3)} kg ÷ $quantity pcs = ${(calculatedUW * 1000).toStringAsFixed(4)} g/pcs');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Sample Mode Aktif\n'
          '📦 Quantity: $quantity pcs\n'
          '⚖️ Unit Weight: ${(calculatedUW * 1000).toStringAsFixed(4)} g/pcs\n'
          '📊 Net Weight: ${netWeightInKg.toStringAsFixed(3)} kg\n'
          '💡 UW dihitung dari NET Weight (setelah Tara)'
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
    
  } catch (e) {
    print('❌ Error calculating sample: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _exitSampleMode() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Exit Sample Mode?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quantity: $sampleCount pcs'),
          Text('Unit Weight: ${unitWeight.toStringAsFixed(4)} kg/pcs'),
          const SizedBox(height: 12),
          const Text('Data Unit Weight akan tetap tersimpan untuk penimbangan berikutnya.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isSamplingMode = false;
            });
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Sample Mode dinonaktifkan\n💡 Unit Weight masih tersimpan untuk penimbangan berikutnya'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Exit'),
        ),
      ],
    ),
  );
}

Future<void> _manualInputUnitWeight() async {
  final result = await showNumpadDialog(
    context: context,
    title: 'Input Unit Weight',
    initialValue: unitWeight > 0 
        ? (unitWeight * 1000).toStringAsFixed(4)
        : '0.0000',
    unit: 'g/pcs',
  );
  
  if (result != null && result.isNotEmpty) {
    double uwInGram = double.tryParse(result) ?? 0.0;
    
    if (uwInGram > 0) {
      double uwInKg = uwInGram / 1000;
      setState(() {
        unitWeight = uwInKg;
        isUnitWeightSet = true;
        isSamplingMode = false;
        sampleCount = 0;
        sampleTotalWeight = 0.0;
      });
      
      try {
        // ✅ PERUBAHAN: Gunakan NET WEIGHT untuk hitung quantity
        double netWeightValue = double.parse(netWeight);
        double netWeightInKg = _convertToKg(netWeightValue);
        
        if (netWeightInKg > 0) {
          int qty = (netWeightInKg / uwInKg).round();
          
          setState(() {
            calculatedQuantity = qty;
          });
          
          print('\n✅ MANUAL UNIT WEIGHT SET (NET-BASED)');
          print('   Unit Weight: ${uwInGram.toStringAsFixed(4)} g/pcs (${uwInKg.toStringAsFixed(6)} kg/pcs)');
          print('   Current Net: ${netWeightInKg.toStringAsFixed(3)} kg');
          print('   Calculated Quantity: $qty pcs');
          print('   Formula: ${netWeightInKg.toStringAsFixed(3)} kg ÷ ${uwInKg.toStringAsFixed(6)} kg/pcs = $qty pcs');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Unit Weight: ${uwInGram.toStringAsFixed(4)} g/pcs\n'
                '📦 Calculated Quantity: $qty pcs\n'
                '⚖️ Current Net: ${netWeightInKg.toStringAsFixed(3)} kg\n'
                '💡 Quantity dihitung dari NET Weight'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          setState(() {
            calculatedQuantity = 0;
          });
          
          print('\n✅ MANUAL UNIT WEIGHT SET');
          print('   Unit Weight: ${uwInGram.toStringAsFixed(4)} g/pcs (${uwInKg.toStringAsFixed(6)} kg/pcs)');
          print('   Waiting for weight...');
          print('   Calculated Quantity: 0 pcs (no weight on scale)');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Unit Weight: ${uwInGram.toStringAsFixed(4)} g/pcs\n'
                '💡 Letakkan barang di timbangan untuk hitung Quantity'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('⚠️ Error calculating quantity: $e');
        setState(() {
          calculatedQuantity = 0;
        });
      }
    }
  }
}

Widget _buildWeightDisplay() {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  
  final isVerySmallScreen = screenHeight < 650;
  final isSmallScreen = screenHeight < 750;
  
  final weightFontSize = isVerySmallScreen ? 40.0 : (isSmallScreen ? 48.0 : 56.0);
  final statusBarHeight = isVerySmallScreen ? 6.0 : (isSmallScreen ? 8.0 : 10.0);
  final fieldPadding = isVerySmallScreen ? 6.0 : (isSmallScreen ? 8.0 : 10.0);
  final buttonHeight = isVerySmallScreen ? 42.0 : (isSmallScreen ? 45.0 : 48.0);
  final iconSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 14.0 : 16.0);
  final labelSize = isVerySmallScreen ? 7.0 : (isSmallScreen ? 8.0 : 9.0);
  
  return SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          if (!isActuallyConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                border: Border(
                  bottom: BorderSide(color: Colors.orange[300]!, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo Mode: Timbangan tidak terhubung',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                      
                      // Reload after settings
                      await _loadDefaultPrinter();
                      if (mounted) setState(() {});
                    },
                    icon: Icon(Icons.settings, size: 16, color: Colors.blue[700]),
                    label: Text(
                      'Connect',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.all(fieldPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 
                    (showRawData ? (isVerySmallScreen ? 120 : 160) : 0) - 
                    (isVerySmallScreen ? 130 : 160) - 
                    (statusBarHeight * 2 + 10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[900]!, Colors.blue[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          if (isSamplingMode || isUnitWeightSet)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[700],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.science, color: Colors.white, size: 11),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      isSamplingMode 
                                                          ? 'SAMPLING • ${sampleCount} pcs'
                                                          : selectedProduct != null && selectedProduct!.isReadyForCountingMode
                                                              ? 'COUNTING • ${selectedProduct!.productName}'
                                                              : 'COUNTING • UW: ${(unitWeight * 1000).toStringAsFixed(1)} g/pcs',
                                                      style: const TextStyle(
                                                        color: Colors.white, 
                                                        fontSize: 9, 
                                                        fontWeight: FontWeight.bold
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          
                                          // ✅ FIX: Show correct label based on mode
                                          Text(
                                            (isSamplingMode || isUnitWeightSet) ? 'Quantity' : 'Net',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          
                                          // ✅ FIX: Show correct value based on mode
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              (isSamplingMode || isUnitWeightSet) 
                                                  ? calculatedQuantity.toString()
                                                  : netWeight,
                                              style: TextStyle(
                                                fontSize: weightFontSize, 
                                                fontWeight: FontWeight.bold, 
                                                color: Colors.white, 
                                                height: 1, 
                                                letterSpacing: -1,
                                              ),
                                            ),
                                          ),
                                          
                                          // ✅ FIX: Show correct unit based on mode
                                          Text(
                                            (isSamplingMode || isUnitWeightSet) ? 'pcs' : selectedUnit.toLowerCase(),
                                            style: const TextStyle(
                                              fontSize: 13, 
                                              fontWeight: FontWeight.w600, 
                                              color: Colors.white70
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    IconButton(
                                      onPressed: _clearDisplay,
                                      icon: const Icon(Icons.clear, color: Colors.white70),
                                      iconSize: 24,
                                      tooltip: 'Clear Display',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Bottom row with Tare/UW/Pre-Tare and Gross
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              children: [
                                // ✅ Left side: Shows Tare, UW, or Pre-Tare
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          preTareValue > 0 
                                            ? 'Pre-Tare'
                                            : (isSamplingMode || isUnitWeightSet 
                                                ? 'UW' 
                                                : 'Tare'),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 9,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            preTareValue > 0 
                                              ? _convertFromKg(preTareValue, selectedUnit).toStringAsFixed(currentDecimalPlaces)
                                              : (isSamplingMode || isUnitWeightSet 
                                                  ? (unitWeight * 1000).toStringAsFixed(4)
                                                  : tareWeight),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          preTareValue > 0 
                                            ? selectedUnit.toLowerCase()
                                            : (isSamplingMode || isUnitWeightSet 
                                                ? 'g/pcs' 
                                                : selectedUnit.toLowerCase()),
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // ✅ Right side: Always shows Gross (GS)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('GS', style: TextStyle(color: Colors.white70, fontSize: 9)),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            grossWeight,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          selectedUnit.toLowerCase(),
                                          style: const TextStyle(fontSize: 8, color: Colors.white60),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: fieldPadding),

                    Row(
                      children: [
                        Expanded(child: _buildStatusButton('Low', weightStatus == 'Low', Colors.orange)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatusButton('OK', weightStatus == 'OK', Colors.green)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildStatusButton('High', weightStatus == 'High', Colors.red)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _setThreshold,
                            icon: const Icon(Icons.settings, size: 11),
                            label: const Text('Set', style: TextStyle(fontSize: 9)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: fieldPadding),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Count', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$weighingCounter',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: Colors.grey[300]),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${totalWeightKg.toStringAsFixed(2)} kg',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _resetCounter,
                            icon: const Icon(Icons.refresh, size: 16),
                            color: Colors.orange,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: fieldPadding),

                    Container(
                      constraints: BoxConstraints(
                        minHeight: 100,
                        maxHeight: isSmallScreen ? 200 : 300,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: customFields.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('No fields yet', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _addNewField,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Field', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: customFields.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                String fieldLabel = customFields[index]['label']!;
                                String fieldValue = customFields[index]['value']!;
                                bool hasDatabase = ['Product', 'Client', 'ID', 'Supplier'].contains(fieldLabel);
                                
                                final controller = _fieldControllers[index];
                                
                                if (controller != null && controller.text != fieldValue) {
                                  controller.text = fieldValue;
                                  controller.selection = TextSelection.fromPosition(
                                    TextPosition(offset: controller.text.length),
                                  );
                                }
                                
                                return Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _editManualInput(index),
                                      onLongPress: () => _showFieldOptionsMenu(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue[200]!, width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              fieldLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue[900],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.touch_app, size: 12, color: Colors.blue[700]),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(': ', style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 6),
                                  
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: controller,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                              decoration: InputDecoration(
                                                hintText: hasDatabase ? 'Tap button or type' : 'Type here',
                                                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              onChanged: (value) {
                                                customFields[index]['value'] = value;
                                                _debouncedSaveCustomFields();
                                              },
                                            ),
                                          ),
                                          
                                          if (fieldLabel == 'Product Code' && 
                                              fieldValue.isNotEmpty && 
                                              selectedProduct != null && 
                                              selectedProduct!.materialCode == fieldValue)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle, size: 10, color: Colors.green[700]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Auto',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.green[700],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          
                                          if (fieldLabel == 'Product Code' &&
                                              fieldValue.isNotEmpty && 
                                              selectedProduct != null && 
                                              selectedProduct!.productCode == fieldValue)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle, size: 10, color: Colors.green[700]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Auto',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.green[700],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          
                                          if (fieldLabel == 'Product' && 
                                              fieldValue.isNotEmpty && 
                                              selectedProduct != null && 
                                              selectedProduct!.productName == fieldValue)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle, size: 10, color: Colors.green[700]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Auto',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.green[700],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    
                    SizedBox(height: fieldPadding),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallScreen ? 4 : 6, 
              vertical: isVerySmallScreen ? 2 : 3
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.save, 
                      label: 'Save', 
                      onPressed: _saveWeight, 
                      color: Colors.green,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                    SizedBox(width: isVerySmallScreen ? 3 : 4),
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.refresh, 
                      label: 'Tara', 
                      onPressed: _setTara, 
                      color: Colors.blue,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                    SizedBox(width: isVerySmallScreen ? 3 : 4),
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.looks_one,
                      label: '1st',
                      onPressed: _printFirstWeighingWithHeader,
                      color: isStatisticalSession ? Colors.purple : null,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                  ],
                ),
                SizedBox(height: isVerySmallScreen ? 1 : 2),
                Row(
                  children: [
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.science, 
                      label: 'Sample', 
                      onPressed: _showSampleDialog,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                    SizedBox(width: isVerySmallScreen ? 3 : 4),
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.calculate, 
                      label: 'UW', 
                      onPressed: _manualInputUnitWeight,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                    SizedBox(width: isVerySmallScreen ? 3 : 4),
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.analytics,
                      label: 'Stat',
                      onPressed: _printLastWeighing,
                      color: isStatisticalSession ? Colors.blue : null,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                  ],
                ),
                SizedBox(height: isVerySmallScreen ? 2 : 3),
                Row(
                  children: [
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.clear, 
                      label: 'Clear', 
                      onPressed: _clearDisplay, 
                      color: Colors.orange,      
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                    SizedBox(width: isVerySmallScreen ? 3 : 4),
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.input_outlined, 
                      label: 'I/O', 
                      onPressed: _requestData,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                    SizedBox(width: isVerySmallScreen ? 3 : 4),
                    Expanded(child: _buildBottomNavButton(
                      icon: Icons.calculate_outlined, 
                      label: 'Total', 
                      onPressed: _showTotalSummaryDialog, 
                      color: Colors.amber,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      height: buttonHeight,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLandscapeLayout() {
  return Row(
    children: [
      Expanded(
        flex: 4,
        child: Container(
          color: Colors.grey[100],
          child: Column(
            children: [
              if (!isConnected || selectedDevice == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Timbangan Tidak Terhubung',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: Colors.green[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 14),
                      const SizedBox(width: 6),
                      Text(
                        selectedDevice?.name ?? "Unknown",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: connectionMode == 'continuous' 
                              ? Colors.blue[700] 
                              : Colors.orange[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          connectionMode == 'continuous' ? 'REAL-TIME' : 'MANUAL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (showRawData)
                Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.black87,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Raw Data Log',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: _clearRawLog,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: rawDataLog.isEmpty
                            ? const Center(
                                child: Text(
                                  'Waiting for data...',
                                  style: TextStyle(color: Colors.grey, fontSize: 9),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: rawDataLog.length,
                                itemBuilder: (context, index) {
                                  String log = rawDataLog[index];
                                  bool isSent = log.contains('>>');
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isSent ? '→' : '←',
                                          style: TextStyle(
                                            color: isSent 
                                                ? Colors.orangeAccent 
                                                : Colors.lightBlueAccent,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            log,
                                            style: TextStyle(
                                              color: isSent 
                                                  ? Colors.orange[200] 
                                                  : Colors.lightGreenAccent,
                                              fontSize: 8,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[900]!, Colors.blue[700]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: Column(
                                children: [
                                  if (isSamplingMode || isUnitWeightSet)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[700],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isSamplingMode 
                                            ? 'Sample Mode: $sampleCount pcs'
                                            : 'Unit Weight: ${unitWeight.toStringAsFixed(3)} kg',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  
                                  const Text(
                                    'Net',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
    
if (isSamplingMode || (isUnitWeightSet && calculatedQuantity > 0))
  Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        Text(
          calculatedQuantity.toString(), 
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
            height: 1,
          ),
        ),
        const Text(
          'PCS',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange,
          ),
        ),
      ],
    ),
  ),
                                      
                                      Column(
                                        children: [
                                          Text(
                                            double.parse(netWeight).toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontSize: 56,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                          Text(
                                            selectedUnit.toLowerCase(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      if (isUnitWeightSet)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'U/W',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              Text(
                                                unitWeight.toStringAsFixed(3),
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.lightBlue,
                                                  height: 1,
                                                ),
                                              ),
                                              const Text(
                                                'kg',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.lightBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Row(
                                children: [
                                  Expanded(
  child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
  preTareValue > 0 
    ? 'Pre-Tare'
    : (isSamplingMode || isUnitWeightSet 
        ? 'UW' 
        : 'Tare'),
  style: const TextStyle(
    color: Colors.white70,
    fontSize: 9,
  ),
),
        const SizedBox(height: 2),
        Text(
  preTareValue > 0 
    ? (preTareValue * 1000).toStringAsFixed(currentDecimalPlaces)
    : (isSamplingMode || isUnitWeightSet
        ? (unitWeight * 1000).toStringAsFixed(4)
        : double.parse(tareWeight).toStringAsFixed(currentDecimalPlaces)),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
  preTareValue > 0 
    ? 'g'
    : (isSamplingMode || isUnitWeightSet 
        ? 'g/pcs' 
        : selectedUnit.toLowerCase()),
  style: const TextStyle(
    fontSize: 8,
    color: Colors.white60,
  ),
),
      ],
    ),
  ),
),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'GS',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 9,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            double.parse(grossWeight).toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            selectedUnit.toLowerCase(),
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _buildStatusButton('Low', weightStatus == 'Low', Colors.orange),
                          const SizedBox(width: 6),
                          _buildStatusButton('OK', weightStatus == 'OK', Colors.green),
                          const SizedBox(width: 6),
                          _buildStatusButton('High', weightStatus == 'High', Colors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _setThreshold,
                              icon: const Icon(Icons.settings, size: 12),
                              label: const Text('Set', style: TextStyle(fontSize: 10)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Count',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    '$weighingCounter',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    '${totalWeightKg.toStringAsFixed(2)} kg',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _resetCounter,
                              icon: const Icon(Icons.refresh, size: 18),
                              color: Colors.orange,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      Expanded(
        flex: 6,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.blue[100]!, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Manual Input Fields',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _addNewField,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Field'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: customFields.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No fields yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _addNewField,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Your First Field'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: customFields.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () => _editManualInput(index),
                            onLongPress: () => _showFieldOptionsMenu(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.blue[300]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          customFields[index]['label']!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.touch_app,
                                          size: 18,
                                          color: Colors.blue[700],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    ':',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  // Value
                                  Expanded(
                                    child: Text(
                                      customFields[index]['value']!.isEmpty
                                          ? 'Tap to edit'
                                          : customFields[index]['value']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: customFields[index]['value']!.isEmpty
                                            ? Colors.grey[400]
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.save,
                            label: 'Simpan',
                            onPressed: _saveWeight,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.refresh,
                            label: 'Tara',
                            onPressed: _setTara,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.swap_horiz,
                            label: '1st',  
  onPressed: _printFirstWeighingWithHeader,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
  children: [
    Expanded(
      child: _buildBottomNavButton(
        icon: Icons.science,
        label: isSamplingMode ? 'Exit\nSample' : 'Sample',  
        onPressed: isSamplingMode ? _exitSampleMode : _showSampleDialog,
        color: isSamplingMode ? Colors.red : null,
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: _buildBottomNavButton(
        icon: Icons.calculate,
        label: 'UW',
        onPressed: _manualInputUnitWeight,  
      ),
    ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.restaurant,
                            label: 'Feed',
                            onPressed: _showHistoryMeasurements,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.clear,
                            label: 'Clear ID',
                            onPressed: _resetCounter,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.input_outlined,
                            label: 'I/O',
                            onPressed: _requestData,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBottomNavButton(
                            icon: Icons.calculate_outlined,
                            label: 'Total',
                            onPressed: _showTotalSummaryDialog,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildBottomNavButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
  Color? color,
  double iconSize = 18,
  double labelSize = 9,
  double height = 60,
}) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color != null 
            ? color.withOpacity(0.1) 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color ?? Colors.grey[300]!,
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            size: iconSize, 
            color: color ?? Colors.blue[700],
          ),
          SizedBox(height: height < 55 ? 2 : 3),
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              color: color ?? Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatusButton(String label, bool isActive, Color color) {
  return Expanded(
    child: InkWell(
      onTap: () => _onStatusButtonTap(label),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? color : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.black54,
            fontSize: 11,
          ),
        ),
      ),
    ),
  );
}

DateTime? _totalFilterStartDate;
DateTime? _totalFilterEndDate;

void _showTotalSummaryDialog() {
  _totalFilterStartDate = null;
  _totalFilterEndDate = null;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        // ✅ FIX: Ensure historyMeasurements has data
        if (historyMeasurements.isEmpty) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text('No Data'),
              ],
            ),
            content: const Text(
              'Belum ada data pengukuran.\n\n'
              'Lakukan penimbangan terlebih dahulu untuk melihat summary.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        }
        
        // Filter data
        List<Map<String, dynamic>> filteredData = historyMeasurements.where((item) {
          DateTime itemDate = item['tanggal'];
          
          if (_totalFilterStartDate != null && itemDate.isBefore(_totalFilterStartDate!)) {
            return false;
          }
          
          if (_totalFilterEndDate != null && itemDate.isAfter(_totalFilterEndDate!.add(const Duration(days: 1)))) {
            return false;
          }
          
          return true;
        }).toList();
        
        // ✅ FIX: Safe calculation with null checks
        int filteredCount = filteredData.length;
        double filteredGross = filteredData.fold<double>(0.0, (sum, item) {
          var grossValue = item['gross_weight'];
          if (grossValue == null) return sum;
          return sum + (grossValue is double ? grossValue : double.tryParse(grossValue.toString()) ?? 0.0);
        });
        
        double filteredTare = filteredData.fold<double>(0.0, (sum, item) {
          var tareValue = item['tare_weight'];
          if (tareValue == null) return sum;
          return sum + (tareValue is double ? tareValue : double.tryParse(tareValue.toString()) ?? 0.0);
        });
        
        double filteredNet = filteredData.fold<double>(0.0, (sum, item) {
          var netValue = item['beratKg'];
          if (netValue == null) return sum;
          return sum + (netValue is double ? netValue : double.tryParse(netValue.toString()) ?? 0.0);
        });
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.summarize, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('Total Summary'),
            ],
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date filter section...
                // (keep existing date filter code)
                
                const SizedBox(height: 12),
                
                // Summary cards
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Count', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('$filteredCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(width: 1, height: 30, color: Colors.grey[300]),
                          Column(
                            children: [
                              const Text('Total Weight', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('${filteredNet.toStringAsFixed(2)} kg', 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeightSummaryChip('Gross', filteredGross, Colors.blue),
                          _buildWeightSummaryChip('Tare', filteredTare, Colors.orange),
                          _buildWeightSummaryChip('Net', filteredNet, Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Data table
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Text('No', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 90, child: Text('Product', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        SizedBox(width: 55, child: Text('Gross', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        SizedBox(width: 55, child: Text('Tare', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        SizedBox(width: 55, child: Text('Net', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        SizedBox(width: 35, child: Text('Unit', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 110, child: Text('Timestamp', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
                
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: filteredData.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20), 
                          child: Text('No data', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredData.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (context, index) {
                            var item = filteredData[index];
                            DateTime dt = item['tanggal'];
                            
                            String product = item['product'] ?? item['barang'] ?? '-';
                            String gross = (item['gross_weight'] is double 
                                ? item['gross_weight'].toStringAsFixed(2) 
                                : (item['gross_weight']?.toString() ?? '-'));
                            String tare = (item['tare_weight'] is double 
                                ? item['tare_weight'].toStringAsFixed(2) 
                                : (item['tare_weight']?.toString() ?? '-'));
                            String net = item['berat']?.toString() ?? '-';
                            String unit = item['unit'] ?? '-';
                            String timestamp = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 9), textAlign: TextAlign.center)),
                                    SizedBox(width: 90, child: Text(product, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                    SizedBox(width: 55, child: Text(gross, style: const TextStyle(fontSize: 9), textAlign: TextAlign.right)),
                                    SizedBox(width: 55, child: Text(tare, style: const TextStyle(fontSize: 9), textAlign: TextAlign.right)),
                                    SizedBox(width: 55, child: Text(net, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                    SizedBox(width: 35, child: Text(unit, style: const TextStyle(fontSize: 8), textAlign: TextAlign.center)),
                                    SizedBox(width: 110, child: Text(timestamp, style: const TextStyle(fontSize: 8))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (filteredData.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showExportDialog();
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    ),
  );
}

Widget _buildWeightSummaryChip(String label, double value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(2)} kg',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

double _calculateTotalGross() {
  return historyMeasurements.fold<double>(
    0.0,
    (sum, item) => sum + (item['gross_weight'] ?? 0.0),
  );
}

double _calculateTotalTare() {
  return historyMeasurements.fold<double>(
    0.0,
    (sum, item) => sum + (item['tare_weight'] ?? 0.0),
  );
}

void _clearDisplay() {
  print('🧹 CLEAR DISPLAY called');
  
  if (isSamplingMode || isUnitWeightSet) {
    print('🔓 EXIT COUNTING MODE triggered');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Exit Counting Mode?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSamplingMode) ...[
              Text('Sample Mode:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900])),
              Text('  • Quantity: $sampleCount pcs'),
              Text('  • Unit Weight: ${(unitWeight * 1000).toStringAsFixed(2)} g/pcs'),
            ] else if (isUnitWeightSet) ...[
              Text('Counting Mode:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
              Text('  • Unit Weight: ${(unitWeight * 1000).toStringAsFixed(2)} g/pcs'),
              if (preTareValue > 0)
                Text('  • Pre-Tare: ${preTareValue.toStringAsFixed(2)} g'),
              if (selectedProduct != null && selectedProduct!.isReadyForCountingMode)
                Text('  • Product: ${selectedProduct!.productName}'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Display akan di-clear dan kembali ke mode penimbangan normal.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                isSamplingMode = false;
                isUnitWeightSet = false;
                sampleCount = 0;
                sampleTotalWeight = 0.0;
                unitWeight = 0.0;
                calculatedQuantity = 0;
                 preTareValue = 0.0;
                
                isDisplayCleared = true;
                currentWeight = "0.0";
                netWeight = "0.000";
                grossWeight = "0.000";
                tareWeight = "0.000";
                taraValue = 0.0;
                weightStatus = "OK";
                
                for (var field in customFields) {
                  field['value'] = '';
                }
                
                selectedProduct = null;
                selectedClient = null;
                selectedId = null;
                selectedSupplier = null;
                
                String timestamp = DateTime.now().toString().substring(11, 19);
                rawDataLog.add('$timestamp: >> EXIT COUNTING MODE + DISPLAY CLEARED + FIELDS CLEARED');
              });
              
              _saveCustomFields();
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '✓ Counting Mode dinonaktifkan\n'
                    '✓ Display di-clear\n'
                    '✓ Custom fields di-clear\n'
                    '💡 Angkat barang untuk mulai penimbangan baru'
                  ),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Exit & Clear'),
          ),
        ],
      ),
    );
    
    return; 
  }
  
  print('   Before: currentWeight=$currentWeight, net=$netWeight, gross=$grossWeight');
  
  setState(() {
    isDisplayCleared = true;
    
    currentWeight = "0.0";
    netWeight = "0.000";
    grossWeight = "0.000";
    tareWeight = "0.000";
    taraValue = 0.0;
    preTareValue = 0.0;
    calculatedQuantity = 0;
    weightStatus = "OK";
    
    for (var field in customFields) {
      field['value'] = '';
    }
    
    selectedProduct = null;
    selectedClient = null;
    selectedId = null;
    selectedSupplier = null;
    
    String timestamp = DateTime.now().toString().substring(11, 19);
    rawDataLog.add('$timestamp: >> DISPLAY CLEARED + FIELDS CLEARED (permanent until weight < 0.05kg)');
  });
  
  _saveCustomFields();
  
  print('   After: currentWeight=$currentWeight, net=$netWeight, gross=$grossWeight');
  print('✅ Display cleared - will ignore all data until weight returns to zero');
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        '✓ Display cleared\n'
        '✓ Custom fields cleared\n'
        '💡 Angkat barang untuk mulai penimbangan baru'
      ),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 3),
    ),
  );
}
  
   String _calculatePrice() {
    if (selectedBarang == null || selectedBarang!['harga'] == 0) {
      return '0';
    }
    
    try {
      double weight = double.parse(currentWeight);
      int hargaPerKg = selectedBarang!['harga'];
      
      double weightInKg = weight;
      if (selectedUnit == "GRAM") {
        weightInKg = weight / 1000;
      } else if (selectedUnit == "ONS") {
        weightInKg = weight / 10;
      } else if (selectedUnit == "POUND") {
        weightInKg = weight * 0.453592;
      }
      
      double total = weightInKg * hargaPerKg;
      return total.toStringAsFixed(0);
    } catch (e) {
      return '0';
    }
  }
}