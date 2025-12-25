import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'utils/notification_helper.dart';            
import '../pages/visual_label_designer_page.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'widgets/database_management_section.dart';
import 'widgets/tspl_debug_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings variables
  bool isDarkMode = false;
  double fontSize = 16.0;
  String defaultUnit = 'GRAM';
  bool autoSave = false;
  bool showStabilityIndicator = false;
 
  // Notifikasi
  bool soundNotification = false;
  bool vibrationNotification = false;
 
  // Grafik
  int maxDataPoints = 50;
 
  // Cloud sync
  bool cloudSync = false;
 
  // Mode Koneksi
  String connectionMode = 'continuous'; // 'continuous' atau 'manual'
  String? defaultPrinterAddress;
  String? defaultPrinterName;
 
  // Loading state
  bool isLoading = true;
 
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDefaultPrinter();
  }
 
  Future<void> _loadSettings() async {
    setState(() => isLoading = true);
   
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        isDarkMode = prefs.getBool('darkMode') ?? false;
        fontSize = prefs.getDouble('fontSize') ?? 16.0;
        defaultUnit = prefs.getString('defaultUnit') ?? 'GRAM';
        autoSave = prefs.getBool('autoSave') ?? false;
        showStabilityIndicator = prefs.getBool('showStability') ?? false;
        soundNotification = prefs.getBool('soundNotif') ?? false;
        vibrationNotification = prefs.getBool('vibrationNotif') ?? false;
        maxDataPoints = prefs.getInt('maxDataPoints') ?? 50;
        cloudSync = prefs.getBool('cloudSync') ?? false;
        connectionMode = prefs.getString('connectionMode') ?? 'continuous';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      NotificationHelper.showError(context, 'Gagal memuat pengaturan: $e');
    }
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

Future<void> _saveDefaultPrinter(String address, String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('defaultPrinterAddress', address);
  await prefs.setString('defaultPrinterName', name);
 
  setState(() {
    defaultPrinterAddress = address;
    defaultPrinterName = name;
  });
 
  print('✅ Default printer saved: $name ($address)');
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
 
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', isDarkMode);
      await prefs.setDouble('fontSize', fontSize);
      await prefs.setString('defaultUnit', defaultUnit);
      await prefs.setBool('autoSave', autoSave);
      await prefs.setBool('showStability', showStabilityIndicator);
      await prefs.setBool('soundNotif', soundNotification);
      await prefs.setBool('vibrationNotif', vibrationNotification);
      await prefs.setInt('maxDataPoints', maxDataPoints);
      await prefs.setBool('cloudSync', cloudSync);
      await prefs.setString('connectionMode', connectionMode);
    } catch (e) {
      NotificationHelper.showError(context, 'Gagal menyimpan pengaturan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        appBar: AppBar(
          title: const Text('Pengaturan'),
          backgroundColor: Colors.lightBlue[300],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
   
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.lightBlue[300],
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _saveSettings();
              NotificationHelper.showSuccess(context, 'Pengaturan disimpan');
            },
            icon: const Icon(Icons.save, color: Colors.white, size: 18),
            label: const Text(
              'Simpan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TEMA & TAMPILAN
          _buildSectionTitle('Tema & Tampilan'),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: 'Mode Gelap',
              subtitle: 'Gunakan tema gelap',
              value: isDarkMode,
              onChanged: (val) async {
                setState(() => isDarkMode = val);
                await _saveSettings();
                NotificationHelper.showInfo(
  context,
  val ? 'Mode gelap diaktifkan' : 'Mode terang diaktifkan',
);
              },
            ),
            const Divider(height: 1),
            _buildSliderTile(
              icon: Icons.text_fields,
              title: 'Ukuran Font',
              subtitle: 'Ukuran font untuk tampilan (${fontSize.toInt()})',
              value: fontSize,
              min: 12,
              max: 24,
              onChanged: (val) {
                setState(() => fontSize = val);
              },
              onChangeEnd: (val) async {
                await _saveSettings();
                NotificationHelper.showInfo(context, 'Ukuran font diubah ke ${val.toInt()}');
              },
            ),
          ]),
         
          const SizedBox(height: 20),
         
          // PENGUKURAN
          _buildSectionTitle('Pengukuran'),
          _buildCard([
            _buildDropdownTile(
              icon: Icons.straighten,
              title: 'Satuan Default',
              subtitle: 'Satuan yang digunakan secara default',
              value: defaultUnit,
              items: ['GRAM', 'KG', 'ONS', 'POUND'],
              onChanged: (val) async {
                setState(() => defaultUnit = val!);
                await _saveSettings();
                NotificationHelper.showInfo(context, 'Unit default diubah ke $val');
              },
            ),
          ]),
         
          const SizedBox(height: 20),
         
          // KONEKSI TIMBANGAN
          _buildSectionTitle('Koneksi Timbangan'),
          _buildCard([
            ListTile(
              leading: Icon(Icons.bluetooth_connected, color: Colors.blue[700]),
              title: Text(
                'Mode Koneksi',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                connectionMode == 'continuous'
                    ? 'Data real-time otomatis'
                    : 'Ambil data dengan tombol PRINT',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.refresh, size: 18, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Continuous (Real-time)',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              subtitle: const Text(
                'Data berat update otomatis terus-menerus',
                style: TextStyle(fontSize: 11),
              ),
              value: 'continuous',
              groupValue: connectionMode,
              activeColor: Colors.green[700],
              onChanged: (value) async {
                setState(() => connectionMode = value!);
                await _saveSettings();
                NotificationHelper.showSuccess(context, 'Mode Continuous diaktifkan - Data real-time');
              },
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.touch_app, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Manual (On-Demand)',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              subtitle: const Text(
                'Tekan tombol PRINT untuk ambil data',
                style: TextStyle(fontSize: 11),
              ),
              value: 'manual',
              groupValue: connectionMode,
              activeColor: Colors.orange[700],
              onChanged: (value) async {
                setState(() => connectionMode = value!);
                await _saveSettings();
                NotificationHelper.showWarning(context, 'Mode Manual diaktifkan - Tekan PRINT untuk data');
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connectionMode == 'continuous'
                            ? 'Mode Continuous: Data berat akan update otomatis setiap kali timbangan mengirim data. Cocok untuk penimbangan cepat dan real-time.'
                            : 'Mode Manual: Data hanya diambil saat Anda menekan tombol PRINT. Cocok untuk menghemat baterai dan koneksi lebih stabil.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.blue[200] : Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
         
          const SizedBox(height: 20),
         
          // FITUR TAMBAHAN
          _buildSectionTitle('Fitur Tambahan'),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.save_alt,
              title: 'Simpan Otomatis',
              subtitle: 'Simpan hasil timbangan secara otomatis ketika stabil',
              value: autoSave,
              onChanged: (val) async {
                setState(() => autoSave = val);
                await _saveSettings();
                NotificationHelper.showInfo(
  context,
  val ? 'Auto save diaktifkan' : 'Auto save dinonaktifkan',
);
              },
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.speed,
              title: 'Indikator Stabilitas',
              subtitle: 'Tampilkan indikator stabilitas pembacaan',
              value: showStabilityIndicator,
              onChanged: (val) async {
                setState(() => showStabilityIndicator = val);
                await _saveSettings();
                NotificationHelper.showInfo(
  context,
  val ? 'Indikator stabilitas diaktifkan' : 'Indikator stabilitas dinonaktifkan',
);
              },
            ),
          ]),
         
          const SizedBox(height: 20),
         
          // NOTIFIKASI
          _buildSectionTitle('Notifikasi'),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.volume_up,
              title: 'Suara',
              subtitle: 'Aktifkan suara untuk notifikasi',
              value: soundNotification,
              onChanged: (val) async {
                setState(() => soundNotification = val);
                await _saveSettings();
                if (val) {
  await SystemSound.play(SystemSoundType.click);
  NotificationHelper.showSuccess(context, 'Notifikasi suara diaktifkan');
} else {
  NotificationHelper.showInfo(context, 'Notifikasi suara dinonaktifkan');
}
              },
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.vibration,
              title: 'Getar',
              subtitle: 'Aktifkan getaran untuk notifikasi',
              value: vibrationNotification,
              onChanged: (val) async {
                setState(() => vibrationNotification = val);
                await _saveSettings();
                if (val) {
  await HapticFeedback.mediumImpact();
  NotificationHelper.showSuccess(context, 'Notifikasi getar diaktifkan');
} else {
  NotificationHelper.showInfo(context, 'Notifikasi getar dinonaktifkan');
}
              },
            ),
          ]),
         
          const SizedBox(height: 20),
         
          // GRAFIK
          _buildSectionTitle('Grafik'),
          _buildCard([
            _buildNumberInputTile(
              icon: Icons.show_chart,
              title: 'Jumlah Data Grafik',
              subtitle: 'Jumlah titik data yang ditampilkan di grafik (10-100)',
              value: maxDataPoints,
              onChanged: (val) async {
                setState(() => maxDataPoints = val);
                await _saveSettings();
                NotificationHelper.showInfo(context, 'Jumlah data grafik diubah ke $val');
              },
            ),
          ]),
         
          const SizedBox(height: 20),
         
          // SINKRONISASI CLOUD
          _buildSectionTitle('Sinkronisasi Cloud'),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.cloud_upload,
              title: 'Sinkronisasi Cloud',
              subtitle: 'Sinkronkan data dengan cloud storage',
              value: cloudSync,
              onChanged: (val) async {
                if (val) {
                  final confirm = await _showCloudSyncDialog();
                  if (confirm == true) {
                    setState(() => cloudSync = true);
await _saveSettings();
NotificationHelper.showSuccess(context, 'Cloud sync diaktifkan');
                  }
                } else {
                  setState(() => cloudSync = false);
await _saveSettings();
NotificationHelper.showInfo(context, 'Cloud sync dinonaktifkan');
                }
              },
            ),
          ]),
         
          const SizedBox(height: 20),
         
          // MANAJEMEN DATA
          _buildSectionTitle('Manajemen Data'),
          _buildCard([
            _buildActionTile(
              icon: Icons.backup,
              title: 'Cadangkan Data',
              subtitle: 'Buat cadangan data aplikasi',
              onTap: _backupData,
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.restore,
              title: 'Pulihkan Data',
              subtitle: 'Pulihkan data dari cadangan',
              onTap: _restoreData,
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.delete_forever,
              title: 'Hapus Semua Data',
              subtitle: 'Hapus semua data aplikasi (tidak dapat dikembalikan)',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: _deleteAllData,
            ),
          ]),
         
          const SizedBox(height: 20),

_buildSectionTitle('Database Management'),
const DatabaseManagementSection(),
const SizedBox(height: 20),

          _buildSectionTitle('Printer Bluetooth'),
_buildCard([
  ListTile(
    leading: Icon(Icons.print, color: Colors.blue[700]),
    title: Text(
      'Printer Default',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    ),
    subtitle: Text(
      defaultPrinterName ?? 'Belum ada printer default',
      style: TextStyle(
        fontSize: 12,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
    ),
    trailing: Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
    ),
    onTap: () async {
      await _showPrinterSelection();
    },
  ),
  if (defaultPrinterName != null) ...[
    const Divider(height: 1),
    ListTile(
      leading: Icon(Icons.delete_outline, color: Colors.red[700]),
      title: Text(
        'Hapus Printer Default',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.red[700],
        ),
      ),
      subtitle: Text(
        'Reset ke tanpa printer default',
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Printer Default?'),
            content: Text(
              'Printer "$defaultPrinterName" akan dihapus dari default.\n\n'
              'Anda perlu memilih printer baru saat print berikutnya.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
       
        if (confirm == true) {
          await _clearDefaultPrinter();
          NotificationHelper.showSuccess(
            context,
            '✓ Printer default dihapus',
          );
        }
      },
    ),
  ],
]),

const SizedBox(height: 20),

Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue[50],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.blue[200]!),
  ),
  child: Row(
    children: [
      Icon(Icons.info_outline, color: Colors.blue[700]),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          '💡 Tip: Aplikasi sekarang bisa digunakan tanpa koneksi timbangan (Demo Mode). '
          'Hubungkan timbangan dari menu utama saat diperlukan.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue[900],
            height: 1.4,
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 20),

_buildSectionTitle('Custom Fields Configuration'),
_buildCard([
  ListTile(
    leading: Icon(Icons.restore_page, color: Colors.orange[700]),
    title: Text(
      'Reset to Default Fields',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    ),
    subtitle: Text(
      'Reset custom fields ke: Product, Batch Number, Material Code, Supplier',
      style: TextStyle(
        fontSize: 12,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
    ),
    trailing: Icon(
      Icons.chevron_right,
      size: 16,
      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
    ),
    onTap: _resetToDefaultFields,
  ),
]),

const SizedBox(height: 20),

          _buildSectionTitle('Debug & Testing'),
          _buildCard([
            ListTile(
              leading: Icon(Icons.bug_report, color: Colors.purple),
              title: Text(
                'TSPL Debug Viewer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'View & test TSPL commands untuk troubleshooting',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 16,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TSPLDebugPage(),
                  ),
                );
              },
            ),
          ]),

const SizedBox(height: 20),

          // LABEL TEMPLATE DESIGNER
          _buildSectionTitle('Label & Template'),
          _buildCard([
            ListTile(
              leading: Icon(Icons.design_services, color: Colors.blue[700]),
              title: Text(
                'Label Template Designer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Design custom receipt layout untuk print resi',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VisualLabelDesignerPage(),
                  ),
                );
              },
            ),
          ]),
         
          const SizedBox(height: 20),
         
          // INFORMASI APLIKASI
          _buildSectionTitle('Informasi Aplikasi'),
          _buildCard([
            _buildInfoTile(
              icon: Icons.info,
              title: 'Versi Aplikasi',
              subtitle: '1.0.0 (Build 1)',
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.help,
              title: 'Bantuan',
              subtitle: 'Panduan penggunaan aplikasi',
              onTap: _showHelp,
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.privacy_tip,
              title: 'Kebijakan Privasi',
              subtitle: 'Baca kebijakan privasi aplikasi',
              onTap: _showPrivacyPolicy,
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.bug_report,
              title: 'Laporkan Bug',
              subtitle: 'Laporkan masalah atau bug',
              onTap: _reportBug,
            ),
          ]),
         
          const SizedBox(height: 40),
        ],
      ),
    );
  }
 
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
 
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
 
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.blue[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue[700],
      ),
    );
  }
 
  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: (max - min).toInt(),
                  label: value.toStringAsFixed(0),
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                  activeColor: Colors.blue[700],
                ),
              ),
              Container(
                width: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: DropdownButton<String>(
          value: value,
          underline: Container(),
          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
 
  Widget _buildNumberInputTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final controller = TextEditingController(text: value.toString());
   
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (value > 10) {
                  onChanged(value - 1);
                  controller.text = (value - 1).toString();
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  int? parsed = int.tryParse(val);
                  if (parsed != null && parsed >= 10 && parsed <= 100) {
                    onChanged(parsed);
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (value < 100) {
                  onChanged(value + 1);
                  controller.text = (value + 1).toString();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.blue[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor ?? (isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
 
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
 
  // ===== ACTION METHODS =====
 
  Future<bool?> _showCloudSyncDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Cloud Sync'),
          ],
        ),
        content: Text(
          'Fitur ini akan menyinkronkan data Anda dengan cloud storage.\n\n'
          '⚠️ Catatan: Fitur ini masih dalam pengembangan.\n\n'
          'Aktifkan sekarang?',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaultFields() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      title: Row(
        children: [
          Icon(Icons.restore_page, color: Colors.orange[700]),
          const SizedBox(width: 8),
          const Text('Reset to Default?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fields akan direset ke konfigurasi default:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldItem('1. Product'),
                _buildFieldItem('2. Batch Number'),
                _buildFieldItem('3. Material Code'),
                _buildFieldItem('4. Supplier'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '⚠️ Custom fields yang ada sekarang akan diganti.',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.orange[300] : Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
          ),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
 
  if (confirmed != true) return;
 
  try {
    final prefs = await SharedPreferences.getInstance();
   
    // Hapus flag dan data existing
    await prefs.remove('hasSetDefaultFields');
    await prefs.remove('customFields');
   
    // Set default fields baru
    List<Map<String, dynamic>> defaultFields = [
      {'label': 'Product', 'value': ''},
      {'label': 'Batch Number', 'value': ''},
      {'label': 'Product Code', 'value': ''},
      {'label': 'Supplier', 'value': ''},
    ];
   
    String jsonString = jsonEncode(defaultFields);
    await prefs.setString('customFields', jsonString);
    await prefs.setBool('hasSetDefaultFields', true);
   
    await HapticFeedback.mediumImpact();
   
    if (!mounted) return;
    NotificationHelper.showSuccess(
      context,
      '✓ Custom fields direset ke default',
    );
   
    print('✅ Custom fields reset to default');
    print('   Fields: Product, Batch Number, Material Code, Supplier');
   
  } catch (e) {
    print('❌ Error resetting fields: $e');
    if (!mounted) return;
    NotificationHelper.showError(
      context,
      'Gagal reset fields: $e',
    );
  }
}

Widget _buildFieldItem(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: isDarkMode ? Colors.green[300] : Colors.green[700],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.blue[200] : Colors.blue[900],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

  Future<void> _showPrinterSelection() async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final bluetooth = FlutterBluetoothSerial.instance;
    final devices = await bluetooth.getBondedDevices();
   
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (devices.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Tidak Ada Printer'),
            ],
          ),
          content: const Text(
            'Tidak ada perangkat Bluetooth yang terpasang.\n\n'
            'Silakan:\n'
            '1. Aktifkan Bluetooth\n'
            '2. Pair printer Bluetooth di Settings → Bluetooth\n'
            '3. Kembali ke sini dan coba lagi',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show printer list
    final selectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Printer Default'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final isCurrentDefault = device.address == defaultPrinterAddress;
             
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isCurrentDefault ? Colors.blue[50] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.print,
                      color: Colors.blue[700],
                    ),
                  ),
                  title: Text(
                    device.name ?? 'Unknown Printer',
                    style: TextStyle(
                      fontWeight: isCurrentDefault
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(device.address),
                  trailing: isCurrentDefault
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'AKTIF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => Navigator.pop(context, device),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (selectedDevice != null) {
      await _saveDefaultPrinter(
        selectedDevice.address,
        selectedDevice.name ?? 'Unknown Printer',
      );
     
      if (mounted) {
        NotificationHelper.showSuccess(
          context,
          '✓ Printer default: ${selectedDevice.name}',
        );
      }
    }
  } catch (e) {
    if (!mounted) return;
    Navigator.pop(context); // Close loading if still open
   
    NotificationHelper.showError(
      context,
      'Error: $e',
    );
  }
}
 
  Future<void> _backupData() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Membuat backup...',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
   
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      Map<String, dynamic> backupData = {};
     
      for (String key in keys) {
        final value = prefs.get(key);
        backupData[key] = value;
      }
     
      // Simpan ke file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonEncode(backupData));
     
      if (!mounted) return;
      Navigator.pop(context); // Close loading
     
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Backup Berhasil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data berhasil dicadangkan!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File: $fileName',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lokasi: ${directory.path}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
     
      await HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
     
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Backup Gagal'),
            ],
          ),
          content: Text(
            'Error: $e',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
 
  Future<void> _restoreData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: Row(
          children: [
            Icon(Icons.restore, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Pulihkan Data'),
          ],
        ),
        content: Text(
          'Fitur ini akan memulihkan data dari file backup.\n\n'
          '⚠️ Data saat ini akan ditimpa dengan data backup.\n\n'
          'Lanjutkan?',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
   
    if (confirmed != true) return;
   
    try {
      // Untuk implementasi lengkap, tambahkan file_picker
      // Saat ini menampilkan demo
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      final files = dir.listSync()
          .where((f) => f.path.endsWith('.json') && f.path.contains('backup_'))
          .toList();
     
      if (files.isEmpty) {
        NotificationHelper.showWarning(context, 'Tidak ada file backup ditemukan');
        return;
      }
     
      // Tampilkan list backup files
      if (!mounted) return;
      final selectedFile = await showDialog<File>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: const Text('Pilih File Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final fileName = file.path.split('/').last;
                final timestamp = fileName.replaceAll('backup_', '').replaceAll('.json', '');
                final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
               
                return ListTile(
                  leading: Icon(Icons.file_present, color: Colors.blue[700]),
                  title: Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, File(file.path)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      );
     
      if (selectedFile == null) return;
     
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Memulihkan data...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
     
      // Restore data
      final jsonString = await selectedFile.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);
     
      final prefs = await SharedPreferences.getInstance();
      for (var entry in backupData.entries) {
        if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        } else if (entry.value is double) {
          await prefs.setDouble(entry.key, entry.value);
        } else if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        }
      }
     
      // Reload settings
      await _loadSettings();
     
      if (!mounted) return;
      Navigator.pop(context); // Close loading
     
      NotificationHelper.showSuccess(context, 'Data berhasil dipulihkan');
      await HapticFeedback.mediumImpact();
     
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading if open
      NotificationHelper.showError(context, 'Gagal memulihkan data: $e');
    }
  }
 
  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Hapus Semua Data?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERINGATAN:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Semua pengaturan dan data akan dihapus permanen!\n\n'
              '• Pengaturan aplikasi\n'
              '• Data timbangan\n'
              '• Riwayat pengukuran\n'
              '• Data barang\n\n'
              'Tindakan ini TIDAK DAPAT dibatalkan.',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
   
    if (confirmed == true) {
      // Double confirmation
      final doubleConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: const Text('Konfirmasi Terakhir'),
          content: Text(
            'Apakah Anda benar-benar yakin?\n\n'
            'Semua data akan hilang PERMANEN!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.red[300] : Colors.red[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
              ),
              child: const Text('Ya, Hapus Semuanya'),
            ),
          ],
        ),
      );
     
      if (doubleConfirm == true) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
         
          setState(() {
            isDarkMode = false;
            fontSize = 16.0;
            defaultUnit = 'GRAM';
            autoSave = false;
            showStabilityIndicator = false;
            soundNotification = false;
            vibrationNotification = false;
            maxDataPoints = 50;
            cloudSync = false;
            connectionMode = 'continuous';
          });
         
          await HapticFeedback.heavyImpact();
         
          if (!mounted) return;
          NotificationHelper.showWarning(context, 'Semua data telah dihapus');
        } catch (e) {
          NotificationHelper.showError(context, 'Gagal menghapus data: $e');
        }
      }
    }
  }
 
  void _showHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          appBar: AppBar(
            title: const Text('Bantuan'),
            backgroundColor: Colors.lightBlue[300],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                '📖 PANDUAN PENGGUNAAN APLIKASI TIMBANGAN DIGITAL\n\n'
                '🔷 KONEKSI BLUETOOTH\n'
                '1. Pastikan Bluetooth HP dan timbangan aktif\n'
                '2. Pair timbangan di Settings → Bluetooth\n'
                '3. Buka aplikasi, pilih timbangan dari list\n'
                '4. Tunggu hingga status "Terhubung" muncul\n\n'
                '🔷 MODE KONEKSI\n'
                '• Continuous: Data update real-time otomatis\n'
                '• Manual: Tekan PRINT untuk ambil data\n\n'
                '🔷 MELAKUKAN PENGUKURAN\n'
                '1. Pilih unit yang diinginkan (GRAM/KG/ONS/POUND)\n'
                '2. Letakkan barang di timbangan\n'
                '3. Tunggu hingga angka stabil\n'
                '4. Tekan tombol "Simpan" untuk menyimpan\n\n'
                '🔷 MENGGUNAKAN TARA\n'
                '1. Letakkan wadah kosong di timbangan\n'
                '2. Tekan tombol "Tara" untuk reset ke 0\n'
                '3. Letakkan barang di wadah\n'
                '4. Berat bersih akan ditampilkan\n\n'
                '🔷 MENGELOLA BARANG\n'
                '1. Tekan icon 📦 di app bar\n'
                '2. Tekan tombol ➕ untuk tambah barang\n'
                '3. Isi nama, kategori, dan harga/kg\n'
                '4. Pilih barang sebelum menimbang untuk hitung harga otomatis\n\n'
                '🔷 MELIHAT RIWAYAT\n'
                '1. Tekan icon 🕐 untuk riwayat pengukuran\n'
                '2. Tekan icon 🧾 untuk riwayat resi\n'
                '3. Export ke CSV atau PDF untuk dokumentasi\n\n'
                '🔷 PENGATURAN APLIKASI\n'
                '• Mode Gelap: Gunakan tema gelap untuk kenyamanan mata\n'
                '• Ukuran Font: Sesuaikan ukuran teks (12-24)\n'
                '• Auto Save: Simpan otomatis saat data stabil\n'
                '• Notifikasi: Aktifkan suara dan getaran\n\n'
                '🔷 BACKUP & RESTORE\n'
                '• Backup: Cadangkan data secara berkala\n'
                '• Restore: Pulihkan dari file backup\n'
                '• File disimpan di storage internal\n\n'
                '🔷 TIPS & TRIK\n'
                '• Gunakan mode "Raw Data" untuk debug koneksi\n'
                '• Kalibrasi timbangan secara berkala\n'
                '• Backup data secara rutin\n'
                '• Gunakan auto-save untuk efisiensi\n'
                '• Mode Manual hemat baterai\n\n'
                '📞 BANTUAN LEBIH LANJUT\n'
                'Email: support@timbangan.com\n'
                'WhatsApp: +62 812-3456-7890\n'
                'Website: www.timbangan.com',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDarkMode ? Colors.grey[300] : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          appBar: AppBar(
            title: const Text('Kebijakan Privasi'),
            backgroundColor: Colors.lightBlue[300],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                '📜 KEBIJAKAN PRIVASI\n'
                'Terakhir diperbarui: 21 Oktober 2024\n\n'
                '1. INFORMASI YANG KAMI KUMPULKAN\n\n'
                'Aplikasi ini mengumpulkan dan menyimpan data berikut secara LOKAL di perangkat Anda:\n\n'
                '• Hasil pengukuran timbangan (berat, unit, tanggal)\n'
                '• Data barang (nama, kategori, harga)\n'
                '• Riwayat transaksi dan resi\n'
                '• Pengaturan aplikasi (preferensi pengguna)\n'
                '• Log koneksi Bluetooth\n\n'
                '2. BAGAIMANA KAMI MENGGUNAKAN DATA\n\n'
                'Data yang dikumpulkan digunakan untuk:\n'
                '• Menyimpan riwayat pengukuran Anda\n'
                '• Menghitung total harga berdasarkan berat\n'
                '• Membuat laporan dan ekspor data\n'
                '• Meningkatkan pengalaman pengguna\n\n'
                '3. PENYIMPANAN DATA\n\n'
                '• Semua data disimpan LOKAL di perangkat Anda\n'
                '• Tidak ada data yang dikirim ke server eksternal\n'
                '• Anda memiliki kontrol penuh atas data Anda\n'
                '• Data dapat dihapus kapan saja melalui menu pengaturan\n\n'
                '4. KEAMANAN DATA\n\n'
                '• Data terenkripsi di perangkat\n'
                '• Tidak ada koneksi internet yang diperlukan\n'
                '• Backup data tersimpan di storage lokal\n\n'
                '5. BERBAGI DATA\n\n'
                'Kami TIDAK AKAN:\n'
                '• Menjual data Anda kepada pihak ketiga\n'
                '• Membagikan data tanpa izin eksplisit\n'
                '• Menggunakan data untuk iklan\n'
                '• Mengirim data ke server cloud tanpa persetujuan\n\n'
                '6. HAK ANDA\n\n'
                'Anda memiliki hak untuk:\n'
                '• Mengakses semua data Anda\n'
                '• Menghapus data kapan saja\n'
                '• Export data dalam format CSV/PDF\n'
                '• Mencabut izin aplikasi\n\n'
                '7. BLUETOOTH\n\n'
                '• Aplikasi menggunakan Bluetooth untuk koneksi timbangan\n'
                '• Tidak ada data pribadi yang dikirim via Bluetooth\n'
                '• Koneksi hanya untuk menerima data berat\n\n'
                '8. PERUBAHAN KEBIJAKAN\n\n'
                'Kami dapat memperbarui kebijakan ini sewaktu-waktu. '
                'Perubahan akan dinotifikasikan melalui update aplikasi.\n\n'
                '9. KONTAK\n\n'
                'Jika ada pertanyaan tentang kebijakan privasi:\n'
                '• Email: privacy@timbangan.com\n'
                '• Website: www.timbangan.com/privacy\n'
                '• Telepon: +62 21-1234-5678\n\n'
                '10. PERSETUJUAN\n\n'
                'Dengan menggunakan aplikasi ini, Anda menyetujui kebijakan privasi ini.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDarkMode ? Colors.grey[300] : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: Row(
          children: [
            Icon(Icons.bug_report, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Laporkan Bug'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temukan bug atau masalah?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan laporkan melalui:',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildContactItem(Icons.email, 'bug@timbangan.com'),
            _buildContactItem(Icons.phone, '+62 812-3456-7890'),
            _buildContactItem(Icons.web, 'www.timbangan.com/bug-report'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ℹ️ Mohon sertakan:\n'
                '• Deskripsi masalah\n'
                '• Langkah reproduksi\n'
                '• Screenshot (jika ada)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.blue[200] : Colors.blue[900],
                ),
              ),
            ),
          ],
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
 
  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}