import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DatabaseManagementSection extends StatefulWidget {
  const DatabaseManagementSection({Key? key}) : super(key: key);

  @override
  State<DatabaseManagementSection> createState() => _DatabaseManagementSectionState();
}

class _DatabaseManagementSectionState extends State<DatabaseManagementSection> {
  String? _dbPath;
  int? _dbSize;
  bool _isLoading = false;
  int? _androidVersion;

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
    _checkAndroidVersion();
  }

  /// Check Android version untuk permission handling
  Future<void> _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _androidVersion = androidInfo.version.sdkInt;
        });
        debugPrint('📱 Android SDK Version: $_androidVersion');
      } catch (e) {
        debugPrint('⚠️ Cannot get Android version: $e');
      }
    }
  }

  /// Load informasi database
  Future<void> _loadDatabaseInfo() async {
    try {
      final dbPath = await getDatabasesPath();
      final filePath = path.join(dbPath, DatabaseHelper.databaseName);
      
      setState(() {
        _dbPath = filePath;
      });

      // Cek ukuran file jika ada
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        setState(() {
          _dbSize = size;
        });
      } else {
        debugPrint('⚠️ Database file not found. Initializing...');
        await DatabaseHelper.instance.database;
        await _loadDatabaseInfo();
      }

      // Load info dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      debugPrint('📊 Total SharedPreferences keys: ${keys.length}');
    } catch (e) {
      debugPrint('❌ Error loading database info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Format ukuran file ke format readable
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// ✅ IMPROVED: Request storage permission dengan handling Android 11+
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // Android 13+ (API 33+) - tidak perlu storage permission untuk app-specific directory
      if (_androidVersion != null && _androidVersion! >= 33) {
        debugPrint('✅ Android 13+: No storage permission needed');
        return true;
      }

      // Android 11-12 (API 30-32) - perlu MANAGE_EXTERNAL_STORAGE
      if (_androidVersion != null && _androidVersion! >= 30) {
        debugPrint('📱 Android 11+: Requesting MANAGE_EXTERNAL_STORAGE');
        
        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        }
        
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        }
        
        // Jika ditolak, show settings dialog
        if (status.isDenied || status.isPermanentlyDenied) {
          return await _showPermissionDialog();
        }
        
        return false;
      }

      // Android 10 dan dibawah - gunakan storage permission biasa
      debugPrint('📱 Android 10-: Requesting STORAGE permission');
      if (await Permission.storage.isGranted) {
        return true;
      }
      
      final status = await Permission.storage.request();
      return status.isGranted;
      
    } catch (e) {
      debugPrint('❌ Error requesting permission: $e');
      return false;
    }
  }

  /// Show dialog untuk open settings jika permission permanently denied
  Future<bool> _showPermissionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Permission Diperlukan'),
        content: const Text(
          'Aplikasi memerlukan izin akses storage untuk export database.\n\n'
          'Silakan aktifkan di Settings > Apps > Permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await openAppSettings();
            },
            child: const Text('Buka Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// ✅ IMPROVED: Export database dengan better error handling
  Future<void> _exportDatabase() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('📤 Starting database export...');

      // 1. Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showErrorSnackBar('❌ Permission ditolak. Tidak bisa export database.');
        return;
      }

      // 2. Get source database file
      final dbPath = await getDatabasesPath();
      final sourceFile = File(path.join(dbPath, DatabaseHelper.databaseName));

      if (!await sourceFile.exists()) {
        _showErrorSnackBar('⚠️ Database tidak ditemukan!');
        return;
      }

      debugPrint('✅ Source file found: ${sourceFile.path}');

      // 3. Determine export directory
      Directory? exportDir;
      
      if (Platform.isAndroid) {
        // Try multiple locations for Android
        final possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/sdcard/Download',
        ];
        
        for (final dirPath in possiblePaths) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            exportDir = dir;
            debugPrint('✅ Using export directory: $dirPath');
            break;
          }
        }
        
        // Fallback ke external storage directory
        exportDir ??= await getExternalStorageDirectory();
      } else {
        exportDir = await getDownloadsDirectory();
      }

      if (exportDir == null) {
        _showErrorSnackBar('❌ Tidak dapat menemukan folder export!');
        return;
      }

      // Create directory if not exists
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
        debugPrint('📁 Created export directory: ${exportDir.path}');
      }

      // 4. Generate backup filename
      final timestamp = DateTime.now().toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final backupFileName = 'tconnect_backup_$timestamp.db';
      final backupPath = path.join(exportDir.path, backupFileName);

      // 5. Copy database file
      debugPrint('📋 Copying to: $backupPath');
      final backupFile = await sourceFile.copy(backupPath);
      
      // Verify file was created
      if (!await backupFile.exists()) {
        throw Exception('Backup file tidak berhasil dibuat');
      }

      final backupSize = await backupFile.length();
      debugPrint('✅ Backup created successfully! Size: ${_formatBytes(backupSize)}');

      // 6. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Database berhasil di-export!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '📁 $backupFileName',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '📊 Size: ${_formatBytes(backupSize)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lokasi: ${exportDir.path}',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      // Reload info
      await _loadDatabaseInfo();

    } catch (e, stackTrace) {
      debugPrint('❌ Error exporting database: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorSnackBar('❌ Gagal export database: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Helper: Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// ✅ IMPROVED: Import database menggunakan native file picker
  Future<void> _importDatabase() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('📥 Starting database import...');

      // 1. Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showErrorSnackBar('❌ Permission ditolak. Tidak bisa import database.');
        return;
      }

      // 2. Show instructions dialog dengan option manual import
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 28),
              SizedBox(width: 8),
              Text('Import Database'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📋 Cara Import Database:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '1. Pastikan file backup (.db) ada di folder Download\n'
                '2. Nama file harus: tconnect_backup_XXXX.db\n'
                '3. Klik "Lanjutkan" untuk memilih file\n',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Import akan mengganti database yang ada!',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;

      // 3. Show loading dialog while scanning
if (mounted) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Scanning files...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

// 4. Try multiple download paths (PERBAIKAN UTAMA!)
List<Directory> possibleDirs = [];

// Add common download paths
possibleDirs.add(Directory('/storage/emulated/0/Download'));
possibleDirs.add(Directory('/storage/emulated/0/Downloads')); // Some devices use plural
possibleDirs.add(Directory('/sdcard/Download'));
possibleDirs.add(Directory('/sdcard/Downloads'));

// Add external storage as fallback
final externalDir = await getExternalStorageDirectory();
if (externalDir != null) {
  possibleDirs.add(externalDir);
}

debugPrint('🔍 Scanning ${possibleDirs.length} possible directories...');

// 5. Scan all directories for .db files
List<File> allDbFiles = [];

for (final dir in possibleDirs) {
  try {
    if (await dir.exists()) {
      debugPrint('📁 Scanning: ${dir.path}');
      
      final files = await dir
          .list()
          .where((entity) => 
              entity is File && 
              entity.path.toLowerCase().endsWith('.db'))
          .cast<File>()
          .toList();
      
      allDbFiles.addAll(files);
      debugPrint('  ✓ Found ${files.length} .db files');
    }
  } catch (e) {
    debugPrint('  ✗ Cannot access ${dir.path}: $e');
  }
}

// Close loading dialog
if (mounted) {
  Navigator.pop(context);
}

if (allDbFiles.isEmpty) {
  _showErrorSnackBar(
    '❌ Tidak ada file .db ditemukan!\n\n'
    'Pastikan file ada di folder Download:\n'
    '/storage/emulated/0/Download/'
  );
  return;
}

debugPrint('✅ Total found: ${allDbFiles.length} .db files');

// Rename variable untuk konsistensi
final dbFiles = allDbFiles;

      // 6. Tampilkan dialog pemilihan file
final selectedFile = await showDialog<File>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Pilih File Database (${dbFiles.length} files)'),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: dbFiles.length,
        itemBuilder: (context, index) {
          final file = dbFiles[index];
          final fileName = path.basename(file.path);
          final fileSize = file.lengthSync();
          final fileDate = file.lastModifiedSync();
          final filePath = path.dirname(file.path);

          return Card(
            child: ListTile(
              leading: const Icon(Icons.storage, color: Colors.blue),
              title: Text(
                fileName,
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatBytes(fileSize)} • ${_formatDate(fileDate)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    filePath,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              onTap: () => Navigator.pop(context, file),
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

// ✅ PERBAIKAN 1: Cek apakah user memilih file
if (selectedFile == null) {
  debugPrint('❌ Tidak ada file yang dipilih');
  return;
}

debugPrint('✅ File terpilih: ${selectedFile.path}');

// ✅ PERBAIKAN 2: Ambil nama file sekarang
final fileName = path.basename(selectedFile.path);

// 7. Tutup database yang sedang aktif
await DatabaseHelper.instance.close();
debugPrint('✅ Database ditutup');

// 8. Backup database yang ada sekarang
final dbPath = await getDatabasesPath();
final destPath = path.join(dbPath, DatabaseHelper.databaseName);
final currentDb = File(destPath);

if (await currentDb.exists()) {
  final backupPath = path.join(
    dbPath,
    'backup_before_import_${DateTime.now().millisecondsSinceEpoch}.db',
  );
  await currentDb.copy(backupPath);
  debugPrint('💾 Database lama sudah di-backup');
}

// 9. Copy file yang dipilih ke lokasi database
await selectedFile.copy(destPath);
debugPrint('✅ Database berhasil di-import');

// 10. Verifikasi database yang baru di-import
try {
  final db = await openDatabase(destPath);
  final version = await db.getVersion();
  await db.close();
  debugPrint('✅ Database terverifikasi (version: $version)');
} catch (e) {
  debugPrint('❌ Verifikasi database gagal: $e');
  _showErrorSnackBar('❌ File database tidak valid atau corrupt!');
  return;
}

// 11. Reset instance
DatabaseHelper.resetInstance();

// 12. Tampilkan pesan sukses (sekarang fileName sudah terdefinisi!)
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✅ Database berhasil di-import!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '📁 $fileName', // ← Sekarang variabel ini sudah ada!
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            '🔄 Restart aplikasi untuk melihat data yang di-import.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}

      // 13. Reload info
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadDatabaseInfo();

    } catch (e, stackTrace) {
      debugPrint('❌ Error importing database: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorSnackBar('❌ Gagal import database: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Helper: Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// ✅ IMPROVED: Reset database dengan proper cleanup
  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Reset Database'),
          ],
        ),
        content: const Text(
          'Yakin ingin menghapus SEMUA data?\n\n'
          '⚠️ Tindakan ini tidak bisa dibatalkan!\n\n'
          '💡 Sebaiknya export database terlebih dahulu untuk backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🗑️ Starting database reset...');

      // 1. Close database connection
      await DatabaseHelper.instance.close();
      debugPrint('✅ Database connection closed');

      // 2. Get database path
      final dbPath = await getDatabasesPath();
      final filePath = path.join(dbPath, DatabaseHelper.databaseName);
      
      // 3. Delete database file
      await deleteDatabase(filePath);
      debugPrint('✅ Database file deleted');

      // 4. Reset instance
      DatabaseHelper.resetInstance();
      debugPrint('✅ Database instance reset');

      // 5. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Database berhasil di-reset!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '🔄 Restart aplikasi untuk mulai fresh.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }

      // 6. Reload info
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadDatabaseInfo();

    } catch (e, stackTrace) {
      debugPrint('❌ Error resetting database: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorSnackBar('❌ Gagal reset database: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Database Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Database Info
            if (_dbPath != null) ...[
              _InfoRow(
                icon: Icons.folder,
                label: 'Lokasi',
                value: _dbPath!,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.data_usage,
                label: 'Ukuran',
                value: _dbSize != null ? _formatBytes(_dbSize!) : 'Loading...',
              ),
              if (_androidVersion != null) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.android,
                  label: 'Android SDK',
                  value: _androidVersion.toString(),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text(
                        'Processing...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Export Button
                  ElevatedButton.icon(
                    onPressed: _exportDatabase,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Database'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Import Button (disabled for now)
                  ElevatedButton.icon(
                    onPressed: _importDatabase,
                    icon: const Icon(Icons.upload),
                    label: const Text('Import Database'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Reset Button
                  OutlinedButton.icon(
                    onPressed: _resetDatabase,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Reset Database'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget helper untuk info row
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}