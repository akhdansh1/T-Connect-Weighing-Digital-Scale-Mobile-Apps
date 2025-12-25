import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/company_info.dart';
import '../models/material.dart';
import '../models/supplier.dart';
import '../models/vehicle.dart';
import '../models/operator.dart';
import '../models/weighing_ticket.dart';
import '../models/transaction_receipt.dart';
import '../models/qc_report.dart';
import '../models/receipt_template.dart';
import '../models/label_template_model.dart';
import '../models/product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const int _databaseVersion = 10;
  static const String _databaseName = 'tconnect_industrial.db';

   static String get databaseName => _databaseName;
   static int get databaseVersion => _databaseVersion;

  // Table names
  static const String tableCompanyInfo = 'company_info';
  static const String tableMaterials = 'materials';
  static const String tableSuppliers = 'suppliers';
  static const String tableVehicles = 'vehicles';
  static const String tableOperators = 'operators';
  static const String tableWeighingTickets = 'weighing_tickets';
  static const String tableTransactionReceipts = 'transaction_receipts';
  static const String tableQCReports = 'qc_reports';
  static const String tableMeasurements = 'measurements';
  static const String tableReceiptTemplates = 'receipt_templates';
  static const String tableLabelTemplates = 'label_templates';
  static const String tableProducts = 'products';
  static const String tableClients = 'clients';
  static const String tableIds = 'ids';

  // Old table names (untuk backward compatibility)
  static const String oldTableBarang = 'barang';
  static const String oldTableResi = 'resi';
  static const String oldTablePengukuran = 'pengukuran';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // ========== CREATE DATABASE (untuk fresh install) ==========
  
  Future _createDB(Database db, int version) async {
    print('🏗️ Creating new database v$version...');

    // Tabel Company Info - SCHEMA LENGKAP
    await db.execute('''
      CREATE TABLE $tableCompanyInfo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL,
        company_id TEXT,
        address TEXT,
        address2 TEXT,
        city TEXT,
        province TEXT,
        postal_code TEXT,
        phone TEXT,
        fax TEXT,
        email TEXT,
        website TEXT,
        department TEXT,
        logo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Receipt Templates - GUNAKAN SNAKE_CASE
    await db.execute('''
      CREATE TABLE $tableReceiptTemplates (
        id TEXT PRIMARY KEY,
        template_name TEXT NOT NULL,
        fields TEXT NOT NULL,
        is_active INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        paper_size TEXT DEFAULT 'mm80',
        header_alignment TEXT DEFAULT 'center',
        enable_logo INTEGER DEFAULT 0,
        logo_path TEXT,
        paper_width INTEGER DEFAULT 48
      )
    ''');

    // Tabel Label Templates - TAMBAHKAN UNIT
    await db.execute('''
      CREATE TABLE $tableLabelTemplates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        width REAL DEFAULT 300,
        height REAL DEFAULT 500,
        unit TEXT DEFAULT 'mm',
        elements TEXT NOT NULL,
        is_active INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Materials - TIDAK BERUBAH
    await db.execute('''
      CREATE TABLE $tableMaterials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        material_code TEXT NOT NULL UNIQUE,
        material_name TEXT NOT NULL,
        category TEXT NOT NULL,
        grade TEXT,
        unit TEXT DEFAULT 'KG',
        standard_weight REAL,
        tolerance REAL DEFAULT 0.5,
        price_per_kg INTEGER DEFAULT 0,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Suppliers
    await db.execute('''
      CREATE TABLE $tableSuppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_code TEXT NOT NULL UNIQUE,
        supplier_name TEXT NOT NULL,
        company_name TEXT NOT NULL,
        contact_person TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        province TEXT NOT NULL,
        postal_code TEXT,
        tax_id TEXT,
        supplier_type TEXT DEFAULT 'Domestic',
        is_active INTEGER DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Vehicles
    await db.execute('''
      CREATE TABLE $tableVehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_number TEXT NOT NULL UNIQUE,
        vehicle_type TEXT NOT NULL,
        driver_name TEXT,
        driver_phone TEXT,
        driver_license TEXT,
        tare_weight REAL,
        company TEXT,
        is_active INTEGER DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Operators
    await db.execute('''
      CREATE TABLE $tableOperators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operator_code TEXT NOT NULL UNIQUE,
        operator_name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT,
        role TEXT DEFAULT 'Operator',
        employee_id TEXT,
        department TEXT,
        phone TEXT,
        email TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        last_login TEXT
      )
    ''');

    // Tabel Weighing Tickets
    await db.execute('''
      CREATE TABLE $tableWeighingTickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_number TEXT NOT NULL UNIQUE,
        weighing_date TEXT NOT NULL,
        operator_code TEXT NOT NULL,
        operator_name TEXT NOT NULL,
        material_code TEXT NOT NULL,
        material_name TEXT NOT NULL,
        category TEXT,
        batch_number TEXT,
        grade TEXT,
        supplier_code TEXT,
        supplier_name TEXT,
        vehicle_number TEXT,
        driver_name TEXT,
        driver_phone TEXT,
        first_weight REAL,
        second_weight REAL,
        net_weight REAL NOT NULL,
        tare_weight REAL,
        unit TEXT DEFAULT 'KG',
        po_number TEXT,
        do_number TEXT,
        remarks TEXT,
        status TEXT DEFAULT 'Completed',
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Transaction Receipts
    await db.execute('''
      CREATE TABLE $tableTransactionReceipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_number TEXT NOT NULL UNIQUE,
        transaction_date TEXT NOT NULL,
        operator_code TEXT NOT NULL,
        operator_name TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        customer_address TEXT,
        material_code TEXT NOT NULL,
        material_name TEXT NOT NULL,
        category TEXT,
        grade TEXT,
        gross_weight REAL NOT NULL,
        tare_weight REAL DEFAULT 0,
        net_weight REAL NOT NULL,
        unit TEXT DEFAULT 'KG',
        price_per_kg INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        tax_rate REAL DEFAULT 0,
        tax_amount INTEGER DEFAULT 0,
        total_amount INTEGER NOT NULL,
        payment_method TEXT DEFAULT 'CASH',
        paid_amount INTEGER,
        change_amount INTEGER,
        po_number TEXT,
        invoice_number TEXT,
        remarks TEXT,
        status TEXT DEFAULT 'Paid',
        batch_number TEXT,
        supplier_code TEXT,
        supplier_name TEXT,
        vehicle_number TEXT,
        driver_name TEXT,
        driver_phone TEXT,
        do_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel QC Reports
    await db.execute('''
      CREATE TABLE $tableQCReports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_number TEXT NOT NULL UNIQUE,
        inspection_date TEXT NOT NULL,
        inspector_code TEXT NOT NULL,
        inspector_name TEXT NOT NULL,
        supervisor_name TEXT,
        product_code TEXT NOT NULL,
        product_name TEXT NOT NULL,
        category TEXT,
        grade TEXT,
        batch_number TEXT,
        lot_number TEXT,
        production_date TEXT,
        expiry_date TEXT,
        target_weight REAL NOT NULL,
        unit TEXT DEFAULT 'KG',
        tolerance REAL DEFAULT 0.5,
        tolerance_min REAL NOT NULL,
        tolerance_max REAL NOT NULL,
        sample1_weight REAL NOT NULL,
        sample2_weight REAL,
        sample3_weight REAL,
        average_weight REAL NOT NULL,
        standard_deviation REAL,
        result TEXT NOT NULL,
        remarks TEXT,
        is_approved INTEGER DEFAULT 0,
        approved_date TEXT,
        approved_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabel Measurements
    await db.execute('''
  CREATE TABLE $tableMeasurements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    measurement_date TEXT NOT NULL,
    operator_code TEXT,
    material_code TEXT,
    material_name TEXT,
    category TEXT,
    weight REAL NOT NULL,
    unit TEXT DEFAULT 'KG',
    weight_kg REAL NOT NULL,
    price_total INTEGER DEFAULT 0,
    notes TEXT,
    created_at TEXT NOT NULL,
    quantity INTEGER,
    unit_weight REAL,
    product TEXT,
    client TEXT,
    id_field TEXT,
    supplier TEXT,
    batch_number TEXT,
    material_code_field TEXT,
    sku TEXT,
    location TEXT,
    operator_field TEXT,
    custom TEXT
  )
''');

    // ✅ TAMBAHKAN TABEL PRODUCTS DI SINI
    await db.execute('''
      CREATE TABLE $tableProducts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT,
        product_code TEXT UNIQUE,
        product_name TEXT,
        material_code TEXT,
        unit_weight REAL,
        pre_tare REAL,
        hi_limit REAL,
        target_value REAL,
        low_limit REAL,
        minimum_limit REAL,
        looses REAL,
        kill_date TEXT,
        packing_date TEXT,
        use_by_date TEXT,
        label_format TEXT,
        label_total INTEGER,
        trace_groups TEXT,
        group_selected TEXT,
        input_set TEXT,
        description TEXT,
        created_at TEXT
      )
    ''');

    // ✅ TAMBAHKAN TABLE CLIENTS DI SINI (FRESH INSTALL)
await db.execute('''
  CREATE TABLE clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    serial_number TEXT NOT NULL,
    company_code TEXT NOT NULL,
    company_name TEXT NOT NULL,
    company_address TEXT NOT NULL,
    company_telephone TEXT NOT NULL,
    contacts TEXT NOT NULL,
    remarks TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');

// ✅ TAMBAHKAN TABLE IDS
await db.execute('''
  CREATE TABLE ids (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    barcode TEXT NOT NULL,
    remarks TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');
    
    print('✅ Database v$version created successfully');
    await _insertDefaultData(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
  print('🔄 Upgrading database from v$oldVersion to v$newVersion...');
  
  try {
    // Handle different upgrade paths
    if (oldVersion < 6) {
      await _migrateToLatest(db);
    }
    
    if (oldVersion == 5 && newVersion >= 6) {
      await _migrateV5toV6(db);
    }
    
    if (oldVersion < 7 && newVersion >= 7) {
      await _migrateV6toV7(db);
    }
    
    if (oldVersion < 8 && newVersion >= 8) {
      await _migrateV7toV8(db);
    }

    if (oldVersion < 9 && newVersion >= 9) {
      await _migrateV8toV9(db);
    }

    // ✅ ADD THIS NEW CASE
    if (oldVersion < 10 && newVersion >= 10) {
      await _migrateV9toV10(db);
    }
    
    print('✅ Database upgraded successfully to v$newVersion');
  } catch (e) {
    print('❌ Database upgrade error: $e');
    rethrow;
  }
}

// ✅ RENAME FUNCTION INI
Future _migrateV6toV7(Database db) async {
  print('📦 Starting migration v6 → v7 (Adding grade column)...');

  try {
    // Add grade column to weighing_tickets
    await _addGradeColumnToWeighingTickets(db);
    
    print('🎉 Migration v6 → v7 completed successfully!');
  } catch (e) {
    print('❌ Migration v6→v7 error: $e');
    rethrow;
  }
}

Future _migrateV7toV8(Database db) async {
  print('📦 Starting migration v7 → v8 (Adding products & clients tables)...');

  try {
    // Products table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProducts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT,
        product_code TEXT UNIQUE,
        product_name TEXT,
        material_code TEXT,              -- ← TAMBAHKAN BARIS INI
        unit_weight REAL,
        pre_tare REAL,
        hi_limit REAL,
        target_value REAL,
        low_limit REAL,
        minimum_limit REAL,
        looses REAL,
        kill_date TEXT,
        packing_date TEXT,
        use_by_date TEXT,
        label_format TEXT,
        label_total INTEGER,
        trace_groups TEXT,
        group_selected TEXT,
        input_set TEXT,
        description TEXT,
        created_at TEXT
      )
    ''');

    // ✅ Clients table (USE CONSTANT!)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableClients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_number TEXT NOT NULL,
        company_code TEXT NOT NULL,
        company_name TEXT NOT NULL,
        company_address TEXT NOT NULL,
        company_telephone TEXT NOT NULL,
        contacts TEXT NOT NULL,
        remarks TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    // ✅ TAMBAHKAN INI - IDs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableIds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT NOT NULL,
        remarks TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    print('🎉 Migration v7 → v8 completed successfully!');
  } catch (e) {
    print('❌ Migration v7→v8 error: $e');
    rethrow;
  }
}

Future _migrateV8toV9(Database db) async {
  print('📦 Starting migration v8 → v9 (Adding material_code column)...');

  try {
    // Check if material_code column already exists
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableProducts)');
    List<String> existingColumns = tableInfo.map((col) => col['name'] as String).toList();

    if (!existingColumns.contains('material_code')) {
      print('➕ Adding material_code column to products table');
      await db.execute(
        'ALTER TABLE $tableProducts ADD COLUMN material_code TEXT DEFAULT ""'
      );
      print('✅ material_code column added successfully');
    } else {
      print('ℹ️ material_code column already exists in products table');
    }
    
    print('🎉 Migration v8 → v9 completed successfully!');
  } catch (e) {
    print('❌ Migration v8→v9 error: $e');
    rethrow;
  }
}

Future _migrateV9toV10(Database db) async {
  print('📦 Starting migration v9 → v10 (Adding custom fields + gross/tare)...');

  try {
    await _upgradeDatabaseForCustomFields(db);
    
    // ✅ ADD GROSS & TARE COLUMNS
    final columns = await db.rawQuery('PRAGMA table_info($tableMeasurements)');
    final columnNames = columns.map((col) => col['name'] as String).toList();
    
    if (!columnNames.contains('gross_weight')) {
      await db.execute('ALTER TABLE $tableMeasurements ADD COLUMN gross_weight REAL');
      print('✅ Added column: gross_weight');
    }
    
    if (!columnNames.contains('tare_weight')) {
      await db.execute('ALTER TABLE $tableMeasurements ADD COLUMN tare_weight REAL');
      print('✅ Added column: tare_weight');
    }
    
    print('🎉 Migration v9 → v10 completed successfully!');
  } catch (e) {
    print('❌ Migration v9→v10 error: $e');
    rethrow;
  }
}

Future<void> _upgradeDatabaseForCustomFields(Database db) async {
  print('🔧 Adding custom fields to measurements table...');
  
  try {
    // Check if columns exist in measurements table
    final columns = await db.rawQuery('PRAGMA table_info($tableMeasurements)');
    final columnNames = columns.map((col) => col['name'] as String).toList();
    
    final newColumns = {
      'quantity': 'INTEGER',
      'unit_weight': 'REAL',
      'weight_status': 'TEXT',
      'product': 'TEXT',
      'client': 'TEXT',
      'id_field': 'TEXT',
      'supplier': 'TEXT',
      'batch_number': 'TEXT',
      'material_code_field': 'TEXT',
      'sku': 'TEXT',
      'location': 'TEXT',
      'operator_field': 'TEXT',
      'notes': 'TEXT',
      'custom': 'TEXT',
    };
    
    for (var entry in newColumns.entries) {
      if (!columnNames.contains(entry.key)) {
        await db.execute('ALTER TABLE $tableMeasurements ADD COLUMN ${entry.key} ${entry.value}');
        print('✅ Added column: ${entry.key}');
      }
    }
    
    print('✅ All custom fields added to measurements');
  } catch (e) {
    print('❌ Error adding custom fields: $e');
    // Don't rethrow - this is not critical for existing installs
  }
}

// ✅ PASTE FUNGSI INI di database_helper.dart
// Letakkan SETELAH fungsi _migrateV6toV7 (sekitar line 365)

Future _migrateV5toV6(Database db) async {
  print('📦 Starting migration v5 → v6...');

  try {
    // 1. Fix company_info columns
    await _addMissingColumns(db);

    // 2. Fix receipt_templates column names
    await _fixReceiptTemplatesColumns(db);

    // 3. Add unit column to label_templates
    await _addLabelTemplateUnitColumn(db);
    
    // 4. Add transaction receipt columns
    await _addTransactionReceiptColumns(db);

    print('🎉 Migration v5 → v6 completed successfully!');
  } catch (e) {
    print('❌ Migration v5→v6 error: $e');
    rethrow;
  }
}

  // ========== MIGRATION ==========
  
  Future _migrateToLatest(Database db) async {
  print('📦 Performing complete migration to latest version...');
  
  try {
    // Backup data penting
    List<Map<String, dynamic>> companyBackup = [];
    List<Map<String, dynamic>> materialsBackup = [];
    List<Map<String, dynamic>> receiptsBackup = [];
    
    try {
      companyBackup = await db.query(tableCompanyInfo);
      materialsBackup = await db.query(tableMaterials);
      receiptsBackup = await db.query(tableTransactionReceipts);
    } catch (e) {
      print('⚠️ Some tables not found (fresh install): $e');
    }

    // Create label_templates if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableLabelTemplates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        width REAL DEFAULT 300,
        height REAL DEFAULT 500,
        unit TEXT DEFAULT 'mm',
        elements TEXT NOT NULL,
        is_active INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Add missing columns to company_info
    await _addMissingColumns(db);
    
    // ✅ TAMBAHKAN BARIS INI (PANGGIL FUNGSI BARU)
    await _addTransactionReceiptColumns(db);

    print('✅ Migration to latest completed');
  } catch (e) {
    print('❌ Migration error: $e');
    rethrow;
  }
}

  // 5. MIGRATION V4 -> V5 (SPECIFIC)
Future _migrateV4toV5(Database db) async {
    print('📦 Starting migration v4 → v5...');

    try {
      // 1. Fix company_info columns
      await _addMissingColumns(db);

      // 2. Fix receipt_templates column names
      await _fixReceiptTemplatesColumns(db);

      // 3. Add unit column to label_templates
      await _addLabelTemplateUnitColumn(db);

      print('🎉 Migration v4 → v5 completed successfully!');
    } catch (e) {
      print('❌ Migration v4→v5 error: $e');
      rethrow;
    }
  }

  Future<void> _addTransactionReceiptColumns(Database db) async {
  print('🔧 Adding missing columns to transaction_receipts...');
  
  try {
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableTransactionReceipts)');
    List<String> existingColumns = tableInfo.map((col) => col['name'] as String).toList();

    Map<String, String> requiredColumns = {
      'batch_number': 'TEXT',
      'supplier_code': 'TEXT',
      'supplier_name': 'TEXT',
      'vehicle_number': 'TEXT',
      'driver_name': 'TEXT',
      'driver_phone': 'TEXT',
      'do_number': 'TEXT',
    };

    for (var entry in requiredColumns.entries) {
      if (!existingColumns.contains(entry.key)) {
        print('➕ Adding column: ${entry.key}');
        await db.execute(
          'ALTER TABLE $tableTransactionReceipts ADD COLUMN ${entry.key} ${entry.value}'
        );
      }
    }
    
    print('✅ All transaction_receipts columns added successfully');
  } catch (e) {
    print('❌ Error adding transaction receipt columns: $e');
    // Don't rethrow - this is not critical for fresh installs
  }
}

Future<void> _addGradeColumnToWeighingTickets(Database db) async {
  print('🔧 Adding grade column to weighing_tickets...');
  
  try {
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableWeighingTickets)');
    List<String> existingColumns = tableInfo.map((col) => col['name'] as String).toList();

    if (!existingColumns.contains('grade')) {
      print('➕ Adding column: grade');
      await db.execute(
        'ALTER TABLE $tableWeighingTickets ADD COLUMN grade TEXT'
      );
      print('✅ Grade column added successfully to weighing_tickets');
    } else {
      print('ℹ️ Grade column already exists in weighing_tickets');
    }
  } catch (e) {
    print('❌ Error adding grade column: $e');
    // Don't rethrow - this is not critical for fresh installs
  }
}

// 6. HELPER: Add Missing Columns to company_info
Future _addMissingColumns(Database db) async {
    print('🔧 Checking company_info columns...');
    
    try {
      var tableInfo = await db.rawQuery('PRAGMA table_info($tableCompanyInfo)');
      List<String> existingColumns = tableInfo.map((col) => col['name'] as String).toList();

      Map<String, String> requiredColumns = {
        'company_id': 'TEXT',
        'address2': 'TEXT',
        'city': 'TEXT',
        'province': 'TEXT',
        'postal_code': 'TEXT',
        'fax': 'TEXT',
        'website': 'TEXT',
        'department': 'TEXT',
        'logo_path': 'TEXT',
      };

      for (var entry in requiredColumns.entries) {
        if (!existingColumns.contains(entry.key)) {
          print('➕ Adding column: ${entry.key}');
          await db.execute('ALTER TABLE $tableCompanyInfo ADD COLUMN ${entry.key} ${entry.value}');
        }
      }
    } catch (e) {
      print('❌ Error adding columns: $e');
    }
  }

// 7. HELPER: Fix receipt_templates column names
Future _fixReceiptTemplatesColumns(Database db) async {
    print('🔧 Checking receipt_templates columns...');
    
    try {
      var tableInfo = await db.rawQuery('PRAGMA table_info($tableReceiptTemplates)');
      List<String> columns = tableInfo.map((col) => col['name'] as String).toList();
      
      // If using camelCase, recreate table
      if (columns.contains('templateName') || columns.contains('createdAt')) {
        print('🔄 Recreating receipt_templates with snake_case...');
        
        var backup = await db.query(tableReceiptTemplates);
        await db.execute('DROP TABLE IF EXISTS ${tableReceiptTemplates}_old');
        await db.execute('ALTER TABLE $tableReceiptTemplates RENAME TO ${tableReceiptTemplates}_old');
        
        await db.execute('''
          CREATE TABLE $tableReceiptTemplates (
            id TEXT PRIMARY KEY,
            template_name TEXT NOT NULL,
            fields TEXT NOT NULL,
            is_active INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            paper_size TEXT DEFAULT 'mm80',
            header_alignment TEXT DEFAULT 'center',
            enable_logo INTEGER DEFAULT 0,
            logo_path TEXT,
            paper_width INTEGER DEFAULT 48
          )
        ''');
        
        for (var row in backup) {
          await db.insert(tableReceiptTemplates, {
            'id': row['id'],
            'template_name': row['templateName'] ?? row['template_name'] ?? 'Unknown',
            'fields': row['fields'],
            'is_active': row['isActive'] ?? row['is_active'] ?? 0,
            'created_at': row['createdAt'] ?? row['created_at'] ?? DateTime.now().toIso8601String(),
            'updated_at': row['updatedAt'] ?? row['updated_at'],
            'paper_size': row['paperSize'] ?? row['paper_size'] ?? 'mm80',
            'header_alignment': row['headerAlignment'] ?? row['header_alignment'] ?? 'center',
            'enable_logo': row['enableLogo'] ?? row['enable_logo'] ?? 0,
            'logo_path': row['logoPath'] ?? row['logo_path'],
            'paper_width': row['paperWidth'] ?? row['paper_width'] ?? 48,
          });
        }
        
        await db.execute('DROP TABLE ${tableReceiptTemplates}_old');
        print('✅ Receipt templates table recreated');
      }
    } catch (e) {
      print('❌ Error fixing receipt templates: $e');
    }
  }

// 8. HELPER: Add unit column to label_templates
Future _addLabelTemplateUnitColumn(Database db) async {
  print('🔧 Checking label_templates columns...');
  
  try {
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableLabelTemplates)');
    List<String> columns = tableInfo.map((col) => col['name'] as String).toList();
    
    // Add unit column
    if (!columns.contains('unit')) {
      print('➕ Adding unit column to label_templates');
      await db.execute('ALTER TABLE $tableLabelTemplates ADD COLUMN unit TEXT DEFAULT \'mm\'');
    }
    
    // ✅ Add printer_type column
    if (!columns.contains('printer_type')) {
      print('➕ Adding printer_type column to label_templates');
      await db.execute('ALTER TABLE $tableLabelTemplates ADD COLUMN printer_type TEXT DEFAULT \'TSC\'');
    }
    
    // ✅ Add paper_size column
    if (!columns.contains('paper_size')) {
      print('➕ Adding paper_size column to label_templates');
      await db.execute('ALTER TABLE $tableLabelTemplates ADD COLUMN paper_size TEXT DEFAULT \'58x50\'');
    }
    
    // ✅ Add settings column
    if (!columns.contains('settings')) {
      print('➕ Adding settings column to label_templates');
      await db.execute('ALTER TABLE $tableLabelTemplates ADD COLUMN settings TEXT');
    }
    
    print('✅ All label_templates columns checked/added');
  } catch (e) {
    print('❌ Error adding label template columns: $e');
  }
}

  // ========== INSERT DEFAULT DATA ==========
  
  Future _insertDefaultData(Database db) async {
    print('📝 Inserting default data...');

    final defaultCompany = CompanyInfo.defaultCompany();
    await db.insert(tableCompanyInfo, defaultCompany.toMap());

    final defaultOperator = Operator.defaultOperator();
    await db.insert(tableOperators, defaultOperator.toMap());

    print('✓ Default data inserted');
  }

  // ========== COMPANY INFO CRUD ==========
  
  Future<CompanyInfo?> getCompanyInfo() async {
  try {
    final db = await database;
    final result = await db.query(tableCompanyInfo, limit: 1);
    if (result.isEmpty) return null;
    return CompanyInfo.fromMap(result.first);
  } catch (e) {
    print('❌ Error getCompanyInfo: $e');
    rethrow;
  }
}

  Future<int> updateCompanyInfo(CompanyInfo company) async {
    final db = await database;
    return await db.update(
      tableCompanyInfo,
      company.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  // ========== MATERIALS CRUD ==========
  
  Future<int> createMaterial(Material material) async {
    final db = await database;
    return await db.insert(tableMaterials, material.toMap());
  }

  Future<List<Material>> readAllMaterials({bool activeOnly = true}) async {
    final db = await database;
    final result = await db.query(
      tableMaterials,
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'material_name ASC',
    );
    return result.map((map) => Material.fromMap(map)).toList();
  }

  Future<Material?> getMaterialByCode(String code) async {
    final db = await database;
    final result = await db.query(
      tableMaterials,
      where: 'material_code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Material.fromMap(result.first);
  }

  Future<int> updateMaterial(Material material) async {
    final db = await database;
    return await db.update(
      tableMaterials,
      material.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<int> deleteMaterial(int id) async {
    final db = await database;
    return await db.update(
      tableMaterials,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== SUPPLIERS CRUD ==========
  
  Future<int> createSupplier(Supplier supplier) async {
    final db = await database;
    return await db.insert(tableSuppliers, supplier.toMap());
  }

  Future<List<Supplier>> readAllSuppliers({bool activeOnly = true}) async {
    final db = await database;
    final result = await db.query(
      tableSuppliers,
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'supplier_name ASC',
    );
    return result.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return await db.update(
      tableSuppliers,
      supplier.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.update(
      tableSuppliers,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== VEHICLES CRUD ==========
  
  Future<int> createVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.insert(tableVehicles, vehicle.toMap());
  }

  Future<List<Vehicle>> readAllVehicles({bool activeOnly = true}) async {
    final db = await database;
    final result = await db.query(
      tableVehicles,
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'vehicle_number ASC',
    );
    return result.map((map) => Vehicle.fromMap(map)).toList();
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.update(
      tableVehicles,
      vehicle.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.update(
      tableVehicles,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== OPERATORS CRUD ==========
  
  Future<int> createOperator(Operator operator) async {
    final db = await database;
    return await db.insert(tableOperators, operator.toMap());
  }

  Future<List<Operator>> readAllOperators({bool activeOnly = true}) async {
    final db = await database;
    final result = await db.query(
      tableOperators,
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'operator_name ASC',
    );
    return result.map((map) => Operator.fromMap(map)).toList();
  }

  Future<Operator?> getOperatorByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      tableOperators,
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Operator.fromMap(result.first);
  }

  Future<int> updateOperator(Operator operator) async {
    final db = await database;
    return await db.update(
      tableOperators,
      operator.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [operator.id],
    );
  }

  // ========== WEIGHING TICKETS CRUD ==========
  
  Future<int> createWeighingTicket(WeighingTicket ticket) async {
    final db = await database;
    return await db.insert(tableWeighingTickets, ticket.toMap());
  }

  Future<List<WeighingTicket>> readAllWeighingTickets({int limit = 100}) async {
    final db = await database;
    final result = await db.query(
      tableWeighingTickets,
      orderBy: 'weighing_date DESC',
      limit: limit,
    );
    return result.map((map) => WeighingTicket.fromMap(map)).toList();
  }

  Future<int> updateWeighingTicket(WeighingTicket ticket) async {
  final db = await database;
  
  // ✅ FIX: Cast Map<String, Object?> to Map<String, dynamic>
  final ticketMap = ticket.toMap();
  final dynamicMap = Map<String, dynamic>.from(ticketMap);
  
  return await db.update(
    tableWeighingTickets,
    dynamicMap,
    where: 'id = ?',
    whereArgs: [ticket.id],
  );
}

  Future<int> deleteWeighingTicket(int id) async {
    final db = await database;
    return await db.delete(tableWeighingTickets, where: 'id = ?', whereArgs: [id]);
  }

  // ========== TRANSACTION RECEIPTS CRUD ==========
  
  Future<int> createTransactionReceipt(TransactionReceipt receipt) async {
    final db = await database;
    return await db.insert(tableTransactionReceipts, receipt.toMap());
  }

  Future<List<TransactionReceipt>> readAllTransactionReceipts({int limit = 100}) async {
    final db = await database;
    final result = await db.query(
      tableTransactionReceipts,
      orderBy: 'transaction_date DESC',
      limit: limit,
    );
    return result.map((map) => TransactionReceipt.fromMap(map)).toList();
  }

  Future<int> updateTransactionReceipt(TransactionReceipt receipt) async {
    final db = await database;
    return await db.update(
      tableTransactionReceipts,
      receipt.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> deleteTransactionReceipt(int id) async {
    final db = await database;
    return await db.delete(tableTransactionReceipts, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllTransactionReceipts() async {
    final db = await database;
    return await db.delete(tableTransactionReceipts);
  }

  // ========== QC REPORTS CRUD ==========
  
  Future<int> createQCReport(QCReport report) async {
    final db = await database;
    return await db.insert(tableQCReports, report.toMap());
  }

  Future<List<QCReport>> readAllQCReports({int limit = 100}) async {
    final db = await database;
    final result = await db.query(
      tableQCReports,
      orderBy: 'inspection_date DESC',
      limit: limit,
    );
    return result.map((map) => QCReport.fromMap(map)).toList();
  }

  Future<int> updateQCReport(QCReport report) async {
  final db = await database;
  
  // ✅ FIX: Cast Map<String, Object?> to Map<String, dynamic>
  final reportMap = report.toMap();
  final dynamicMap = Map<String, dynamic>.from(reportMap);
  
  return await db.update(
    tableQCReports,
    dynamicMap,
    where: 'id = ?',
    whereArgs: [report.id],
  );
}

  Future<int> deleteQCReport(int id) async {
    final db = await database;
    return await db.delete(tableQCReports, where: 'id = ?', whereArgs: [id]);
  }

  // ========== MEASUREMENTS CRUD ==========
  
  Future<int> createMeasurement(Map<String, dynamic> measurement) async {
  final db = await database;
  
  // Prepare data with all custom fields
  final data = {
    'measurement_date': measurement['tanggal'] ?? DateTime.now().toIso8601String(),
    'material_name': measurement['barang'] ?? 'Unknown',
    'category': measurement['kategori'] ?? 'General',
    'weight': double.tryParse(measurement['berat']?.toString() ?? '0') ?? 0.0,
    'unit': measurement['unit'] ?? 'KG',
    'weight_kg': measurement['beratKg'] ?? 0.0,
    'price_total': measurement['hargaTotal'] ?? 0,
    'created_at': DateTime.now().toIso8601String(),
    'weight_status': measurement['weight_status'] ?? 'OK',
    
    // ✅ ADD ALL CUSTOM FIELDS
    'quantity': measurement['quantity'],
    'unit_weight': measurement['unit_weight'],
    'product': measurement['product'] ?? '-',
    'client': measurement['client'] ?? '-',
    'id_field': measurement['id_field'] ?? '-',
    'supplier': measurement['supplier'] ?? '-',
    'batch_number': measurement['batch_number'] ?? '-',
    'material_code_field': measurement['material_code'] ?? '-',
    'sku': measurement['sku'] ?? '-',
    'location': measurement['location'] ?? '-',
    'operator_field': measurement['operator'] ?? '-',
    'notes': measurement['notes'] ?? '-',
    'custom': measurement['custom'] ?? '-',
  };
  
  return await db.insert(tableMeasurements, data);
}

  Future<List<Map<String, dynamic>>> readAllMeasurements({int limit = 100}) async {
  final db = await database;
  final result = await db.query(
    tableMeasurements,
    orderBy: 'measurement_date DESC',
    limit: limit,
  );
  
  return result.map((item) {
    // ✅ FIX: Safe casting untuk semua fields
    return {
      'id': item['id'],
      'tanggal': DateTime.parse(
        item['measurement_date']?.toString() ?? DateTime.now().toIso8601String()
      ),
      'barang': item['material_name']?.toString() ?? '-',
      'kategori': item['category']?.toString() ?? '-',
      'berat': item['weight']?.toString() ?? '0',
      'unit': item['unit']?.toString() ?? 'KG',
      'beratKg': item['weight_kg'] ?? 0.0,
      'hargaTotal': item['price_total'] ?? 0,
      'created_at': item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'weight_status': item['weight_status']?.toString() ?? 'OK',

      // ✅ ADD ALL CUSTOM FIELDS WITH SAFE CASTING
      'quantity': item['quantity'],
      'unit_weight': item['unit_weight'],
      'product': item['product']?.toString() ?? '-',
      'client': item['client']?.toString() ?? '-',
      'id_field': item['id_field']?.toString() ?? '-',
      'supplier': item['supplier']?.toString() ?? '-',
      'batch_number': item['batch_number']?.toString() ?? '-',
      'material_code': item['material_code_field']?.toString() ?? '-',
      'sku': item['sku']?.toString() ?? '-',
      'location': item['location']?.toString() ?? '-',
      'operator': item['operator_field']?.toString() ?? '-',
      'notes': item['notes']?.toString() ?? '-',
      'custom': item['custom']?.toString() ?? '-',
    };
  }).toList();
}

  Future<int> deleteMeasurementByDate(String tanggal) async {
    final db = await database;
    return await db.delete(
      tableMeasurements,
      where: 'measurement_date = ?',
      whereArgs: [tanggal],
    );
  }

  Future<int> deleteAllMeasurements() async {
    final db = await database;
    return await db.delete(tableMeasurements);
  }

  // ========== STATISTICS ==========
  
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;

    var resultMaterials = await db.rawQuery('SELECT COUNT(*) as count FROM $tableMaterials WHERE is_active = 1');
    int totalMaterials = Sqflite.firstIntValue(resultMaterials) ?? 0;

    String today = DateTime.now().toIso8601String().split('T')[0];
    var resultToday = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableTransactionReceipts WHERE DATE(transaction_date) = ?',
      [today],
    );
    int transactionsToday = Sqflite.firstIntValue(resultToday) ?? 0;

    var resultRevenue = await db.rawQuery('SELECT SUM(total_amount) as total FROM $tableTransactionReceipts');
    int totalRevenue = (resultRevenue.first['total'] as int?) ?? 0;

    var resultRevenueToday = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM $tableTransactionReceipts WHERE DATE(transaction_date) = ?',
      [today],
    );
    int revenueToday = (resultRevenueToday.first['total'] as int?) ?? 0;

    return {
      'totalMaterials': totalMaterials,
      'transactionsToday': transactionsToday,
      'totalRevenue': totalRevenue,
      'revenueToday': revenueToday,
    };
  }

  // ========== DEBUG ==========
  
  Future<void> printAllData() async {
    print('╔═══════════════════════════════════════════════════════╗');
    print('║       📊 T-CONNECT INDUSTRIAL DATABASE v4            ║');
    print('╚═══════════════════════════════════════════════════════╝');
    
    final materials = await readAllMaterials(activeOnly: false);
    print('\n📦 MATERIALS (${materials.length}):');
    for (var m in materials) {
      print('  ${m.materialCode} - ${m.materialName} (${m.category})');
    }
    
    final receipts = await readAllTransactionReceipts(limit: 10);
    print('\n🧾 TRANSACTION RECEIPTS (${receipts.length}, last 10):');
    for (var r in receipts) {
      print('  ${r.receiptNumber} - ${r.materialName} - Rp ${r.totalAmount}');
    }
    
    final measurements = await readAllMeasurements(limit: 10);
    print('\n📊 MEASUREMENTS (${measurements.length}, last 10):');
    for (var m in measurements) {
      print('  ${m['barang']} - ${m['berat']} ${m['unit']}');
    }
    
    print('\n╚═══════════════════════════════════════════════════════╝\n');
  }
  
  // ========== BACKWARD COMPATIBILITY ==========
  
  Future<List<Map<String, dynamic>>> readAllBarang() async {
    final materials = await readAllMaterials();
    return materials.map((m) => {
      'id': m.id,
      'nama': m.materialName,
      'kategori': m.category,
      'harga': m.pricePerKg,
      'created_at': m.createdAt.toIso8601String(),
    }).toList();
  }

  Future<int> createBarang(Map<String, dynamic> barang) async {
    final material = Material(
      materialCode: 'MAT-${DateTime.now().millisecondsSinceEpoch % 10000}',
      materialName: barang['nama'] ?? 'Unknown',
      category: barang['kategori'] ?? 'General',
      pricePerKg: barang['harga'] ?? 0,
      createdAt: DateTime.now(),
    );
    return await createMaterial(material);
  }

  Future<int> deleteBarang(int id) async {
    return await deleteMaterial(id);
  }

  Future<List<Map<String, dynamic>>> readAllResi() async {
    final receipts = await readAllTransactionReceipts();
    return receipts.map((r) => {
      'id': r.id,
      'nomor': r.receiptNumber,
      'tanggal': r.transactionDate.toIso8601String(),
      'barang': r.materialName,
      'kategori': r.category ?? 'General',
      'berat': r.netWeight.toString(),
      'unit': r.unit,
      'beratKg': r.netWeight,
      'hargaPerKg': r.pricePerKg,
      'totalHarga': r.totalAmount,
      'created_at': r.createdAt.toIso8601String(),
    }).toList();
  }

  Future<int> createResi(Map<String, dynamic> resi) async {
    double berat = double.tryParse(resi['berat']?.toString() ?? '0') ?? 0.0;
    
    final receipt = TransactionReceipt(
      receiptNumber: resi['nomor'] ?? TransactionReceipt.generateReceiptNumber(),
      transactionDate: DateTime.parse(resi['tanggal'] ?? DateTime.now().toIso8601String()),
      operatorCode: 'OP-001',
      operatorName: 'System',
      materialCode: 'MAT-001',
      materialName: resi['barang'] ?? 'Unknown',
      category: resi['kategori'] ?? 'General',
      grossWeight: berat,
      netWeight: berat,
      unit: resi['unit'] ?? 'KG',
      pricePerKg: resi['hargaPerKg'] ?? 0,
      subtotal: resi['totalHarga'] ?? 0,
      totalAmount: resi['totalHarga'] ?? 0,
      createdAt: DateTime.now(),
    );
    return await createTransactionReceipt(receipt);
  }

  Future<int> deleteResi(int id) async {
    return await deleteTransactionReceipt(id);
  }

  Future<int> deleteAllResi() async {
    return await deleteAllTransactionReceipts();
  }

  Future<List<Map<String, dynamic>>> readAllPengukuran({int limit = 100}) async {
    return await readAllMeasurements(limit: limit);
  }

  Future<int> createPengukuran(Map<String, dynamic> pengukuran) async {
  // createPengukuran adalah alias untuk createMeasurement
  return await createMeasurement(pengukuran);
}

  Future<int> deleteAllPengukuran() async {
    return await deleteAllMeasurements();
  }

  // ========== PRODUCTS CRUD ==========
  
  Future<int> createProduct(ProductModel product) async {
    final db = await database;
    return await db.insert(
      tableProducts,  // ✅ Gunakan constant tableProducts
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProductModel>> readAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableProducts,  // ✅ Gunakan constant tableProducts
      orderBy: 'created_at DESC',  // ✅ Sesuaikan dengan schema snake_case
    );
    return List.generate(maps.length, (i) => ProductModel.fromMap(maps[i]));
  }

  Future<ProductModel?> readProduct(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    return await db.update(
      tableProducts,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CLIENTS CRUD ==========
  
Future<int> createClient(Map<String, dynamic> client) async {
  final db = await database;
  client['created_at'] = DateTime.now().toIso8601String();
  return await db.insert(tableClients, client);  // ✅ Use constant
}

Future<List<Map<String, dynamic>>> readAllClients() async {
  final db = await database;
  return await db.query(tableClients, orderBy: 'company_name ASC');
}

Future<Map<String, dynamic>?> readClient(int id) async {
  final db = await database;
  final results = await db.query(
    tableClients,
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return results.isNotEmpty ? results.first : null;
}

Future<int> updateClient(int id, Map<String, dynamic> client) async {
  final db = await database;
  client['updated_at'] = DateTime.now().toIso8601String();
  return await db.update(
    tableClients,
    client,
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> deleteClient(int id) async {
  final db = await database;
  return await db.delete(
    tableClients,
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<List<Map<String, dynamic>>> searchClients(String keyword) async {
  final db = await database;
  return await db.query(
    tableClients,
    where: 'company_name LIKE ? OR company_code LIKE ? OR serial_number LIKE ?',
    whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
    orderBy: 'company_name ASC',
  );
}

// ========== IDS CRUD ==========
  
  Future<int> createId(Map<String, dynamic> idData) async {
    final db = await database;
    idData['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(tableIds, idData);
  }

  Future<List<Map<String, dynamic>>> readAllIds() async {
    final db = await database;
    return await db.query(tableIds, orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> readId(int id) async {
    final db = await database;
    final results = await db.query(
      tableIds,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateId(int id, Map<String, dynamic> idData) async {
    final db = await database;
    idData['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      tableIds,
      idData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteId(int id) async {
    final db = await database;
    return await db.delete(
      tableIds,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchIds(String keyword) async {
    final db = await database;
    return await db.query(
      tableIds,
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'name ASC',
    );
  }

  // ================================================
  // --- RECEIPT TEMPLATES CRUD ---
  // ================================================

  Future<ReceiptTemplate> createReceiptTemplate(ReceiptTemplate template) async {
    final db = await database;
    await db.insert(
      tableReceiptTemplates,
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return template;
  }

  Future<List<ReceiptTemplate>> readAllReceiptTemplates() async {
    final db = await database;
    final result = await db.query(
      tableReceiptTemplates,
      orderBy: 'template_name ASC',
    );
    return result.map((map) => ReceiptTemplate.fromMap(map)).toList();
  }

  Future<ReceiptTemplate?> getActiveReceiptTemplate() async {
    final db = await database;
    final result = await db.query(
      tableReceiptTemplates,
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return ReceiptTemplate.fromMap(result.first);
    }

    final allTemplates = await readAllReceiptTemplates();
    if (allTemplates.isNotEmpty) {
      await setActiveReceiptTemplate(allTemplates.first.id);
      return allTemplates.first;
    }
    
    return null;
  }

  Future<ReceiptTemplate?> getReceiptTemplateById(String id) async {
    final db = await database;
    final result = await db.query(
      tableReceiptTemplates,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ReceiptTemplate.fromMap(result.first);
  }

  Future<int> updateReceiptTemplate(ReceiptTemplate template) async {
    final db = await database;
    return await db.update(
      tableReceiptTemplates,
      template.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> deleteReceiptTemplate(String id) async {
    final db = await database;
    final template = await getReceiptTemplateById(id);
    
    if (template == null) return 0;
    if (template.isActive) {
      throw Exception('Tidak bisa menghapus template yang sedang aktif.');
    }
    if (template.id == 'default') {
      throw Exception('Tidak bisa menghapus template default.');
    }

    return await db.delete(
      tableReceiptTemplates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> setActiveReceiptTemplate(String templateId) async {
    final db = await database;
    
    await db.update(
      tableReceiptTemplates,
      {'is_active': 0},
      where: 'is_active = ?',
      whereArgs: [1],
    );

    return await db.update(
      tableReceiptTemplates,
      {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [templateId],
    );
  }

  Future<ReceiptTemplate> duplicateReceiptTemplate(String templateId, String newName) async {
    final original = await getReceiptTemplateById(templateId);
    if (original == null) {
      throw Exception('Template original tidak ditemukan');
    }

    final newTemplate = original.copyWith(
      id: 'template_${DateTime.now().millisecondsSinceEpoch}',
      templateName: newName,
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: null,
    );
    
    await createReceiptTemplate(newTemplate);
    return newTemplate;
  }

  Future<ReceiptTemplate> resetToDefaultTemplate() async {
    final db = await database;
    await db.delete(tableReceiptTemplates);
    
    final defaultTemplate = ReceiptTemplate.createDefault();
    await createReceiptTemplate(defaultTemplate);
    return defaultTemplate;
  }

  // ================================================
  // --- LABEL TEMPLATES CRUD ---
  // ================================================

  Future<int> createLabelTemplate(LabelTemplate template) async {
  final db = await database;
  
  try {
    print('\n🔧 ═══════════════════════════════════════════════════');
    print('📝 CREATE LABEL TEMPLATE');
    print('   ID: ${template.id}');
    print('   Name: ${template.name}');
    print('   Size: ${template.width}x${template.height}mm');
    print('   Printer: ${template.printerType}');
    print('   Elements: ${template.elements.length}');
    print('═══════════════════════════════════════════════════');
    
    // ✅ STEP 1: Jika template ini akan di-set active, non-aktifkan yang lain dulu
    if (template.isActive) {
      await db.update(
        tableLabelTemplates,
        {'is_active': 0},
        where: 'is_active = ?',
        whereArgs: [1],
      );
      print('✅ Other templates deactivated');
    }
    
    // ✅ STEP 2: Cek apakah ID sudah ada
    final existing = await getLabelTemplateById(template.id);
    
    if (existing != null) {
      // ❌ ID SUDAH ADA - Ini adalah UPDATE, bukan CREATE
      print('⚠️ Template with ID ${template.id} already exists!');
      print('   Performing UPDATE instead...');
      
      final updateMap = template.toMap();
      updateMap.remove('created_at'); // Jangan update created_at
      
      final result = await db.update(
        tableLabelTemplates,
        updateMap,
        where: 'id = ?',
        whereArgs: [template.id],
      );
      
      print('✅ Template UPDATED (rows: $result)');
      print('═══════════════════════════════════════════════════\n');
      return result;
      
    } else {
      // ✅ ID BELUM ADA - Ini adalah INSERT baru
      print('✅ Creating NEW template...');
      
      final result = await db.insert(
        tableLabelTemplates, 
        template.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail, // ← Fail jika ada conflict
      );
      
      print('✅ Template CREATED successfully!');
      print('   Insert result: $result');
      
      // ✅ VERIFY: Baca kembali untuk memastikan
      final verify = await getLabelTemplateById(template.id);
      if (verify == null) {
        throw Exception('❌ Template created but cannot be read back!');
      }
      
      print('✅ Template verified in database');
      print('   Name: ${verify.name}');
      print('   Elements: ${verify.elements.length}');
      print('═══════════════════════════════════════════════════\n');
      
      return 1; // Success
    }
    
  } catch (e, stackTrace) {
    print('\n❌ ❌ ❌ ERROR CREATING TEMPLATE ❌ ❌ ❌');
    print('Error: $e');
    print('Stack trace:');
    print(stackTrace);
    print('═══════════════════════════════════════════════════\n');
    rethrow;
  }
}

  Future<List<LabelTemplate>> readAllLabelTemplates() async {
    final db = await database;
    
    try {
      final result = await db.query(
        tableLabelTemplates,
        orderBy: 'created_at DESC',
      );
      
      return result.map((map) => LabelTemplate.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error reading label templates: $e');
      return [];
    }
  }

  Future<LabelTemplate?> getActiveLabelTemplate() async {
    final db = await database;
    
    try {
      final result = await db.query(
        tableLabelTemplates,
        where: 'is_active = ?',
        whereArgs: [1],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return LabelTemplate.fromMap(result.first);
      }
      
      final allTemplates = await readAllLabelTemplates();
      if (allTemplates.isNotEmpty) {
        await setActiveLabelTemplate(allTemplates.first.id);
        return allTemplates.first;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting active label template: $e');
      return null;
    }
  }

  Future<LabelTemplate?> getLabelTemplateById(String id) async {
    final db = await database;
    
    try {
      final result = await db.query(
        tableLabelTemplates,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return LabelTemplate.fromMap(result.first);
    } catch (e) {
      print('❌ Error getting label template by ID: $e');
      return null;
    }
  }

  Future<int> updateLabelTemplate(LabelTemplate template) async {
  final db = await database;
  
  try {
    // Jika template ini akan di-set active, non-aktifkan yang lain
    if (template.isActive) {
      await db.update(
        tableLabelTemplates,
        {'is_active': 0},
        where: 'is_active = ? AND id != ?',
        whereArgs: [1, template.id],
      );
    }
    
    // ✅ CRITICAL FIX: Buat map baru tanpa created_at
    final updateMap = template.copyWith(updatedAt: DateTime.now()).toMap();
    updateMap.remove('created_at'); // ← Hapus created_at!
    
    final result = await db.update(
      tableLabelTemplates,
      updateMap,
      where: 'id = ?',
      whereArgs: [template.id],
    );
    
    print('✅ Label template updated: ${template.name} (rows affected: $result)');
    return result;
  } catch (e) {
    print('❌ Error updating label template: $e');
    rethrow;
  }
}

  Future<int> deleteLabelTemplate(String id) async {
    final db = await database;
    
    try {
      final template = await getLabelTemplateById(id);
      if (template == null) return 0;
      
      if (template.isActive) {
        throw Exception('Tidak bisa menghapus template yang sedang aktif.');
      }
      
      return await db.delete(
        tableLabelTemplates,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('❌ Error deleting label template: $e');
      rethrow;
    }
  }

  Future<int> setActiveLabelTemplate(String templateId) async {
    final db = await database;
    
    try {
      await db.update(
        tableLabelTemplates,
        {'is_active': 0},
        where: 'is_active = ?',
        whereArgs: [1],
      );
      
      return await db.update(
        tableLabelTemplates,
        {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [templateId],
      );
    } catch (e) {
      print('❌ Error setting active label template: $e');
      return 0;
    }
  }

  Future<LabelTemplate?> duplicateLabelTemplate(String templateId, String newName) async {
    try {
      final original = await getLabelTemplateById(templateId);
      if (original == null) {
        throw Exception('Template original tidak ditemukan');
      }
      
      final newTemplate = LabelTemplate(
        id: 'template_${DateTime.now().millisecondsSinceEpoch}',
        name: newName,
        width: original.width,
        height: original.height,
        elements: original.elements.map((e) => e.copyWith()).toList(),
        isActive: false,
        createdAt: DateTime.now(),
      );
      
      await createLabelTemplate(newTemplate);
      return newTemplate;
    } catch (e) {
      print('❌ Error duplicating template: $e');
      return null;
    }
  }

  Future<LabelTemplate> resetToDefaultLabelTemplate() async {
    final db = await database;
    
    try {
      await db.delete(tableLabelTemplates);
      
      final defaultTemplate = LabelTemplate(
        id: 'default_label_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Default Label',
        width: 300,
        height: 500,
        elements: [],
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      await createLabelTemplate(defaultTemplate);
      return defaultTemplate;
    } catch (e) {
      print('❌ Error resetting to default template: $e');
      rethrow;
    }
  }

  Future<void> fixLabelTemplatesSchema() async {
  final db = await database;
  
  print('🔧 Fixing label_templates schema...');
  
  try {
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableLabelTemplates)');
    List<String> columns = tableInfo.map((col) => col['name'] as String).toList();
    
    print('   Current columns: $columns');
    
    // Add missing columns
    if (!columns.contains('printer_type')) {
      print('   ➕ Adding printer_type');
      await db.execute('ALTER TABLE $tableLabelTemplates ADD COLUMN printer_type TEXT DEFAULT \'TSC\'');
    }
    
    if (!columns.contains('paper_size')) {
      print('   ➕ Adding paper_size');
      await db.execute('ALTER TABLE $tableLabelTemplates ADD COLUMN paper_size TEXT DEFAULT \'58x50\'');
    }
    
    if (!columns.contains('settings')) {
      print('   ➕ Adding settings');
      await db.execute('ALTER TABLE $tableLabelTemplates ADD COLUMN settings TEXT');
    }
    
    print('✅ Schema fix completed!');
  } catch (e) {
    print('❌ Error fixing schema: $e');
    rethrow;
  }
}

/// ✅ FORCE FIX: Recreate label_templates table dengan schema lengkap
Future<void> forceFixLabelTemplatesTable() async {
  print('🔧 ═══════════════════════════════════════════════════');
  print('🔧 FORCE FIX: Recreating label_templates table...');
  print('═══════════════════════════════════════════════════');
  
  final db = await database;
  
  try {
    // ═══ STEP 1: Backup existing templates ═══
    List<Map<String, dynamic>> backup = [];
    try {
      backup = await db.query(tableLabelTemplates);
      print('📦 Backed up ${backup.length} templates');
    } catch (e) {
      print('⚠️ No existing templates to backup (table might not exist)');
    }
    
    // ═══ STEP 2: Drop old table ═══
    try {
      await db.execute('DROP TABLE IF EXISTS $tableLabelTemplates');
      print('✅ Old table dropped');
    } catch (e) {
      print('⚠️ Table drop error: $e');
    }
    
    // ═══ STEP 3: Create new table with COMPLETE schema ═══
    await db.execute('''
      CREATE TABLE $tableLabelTemplates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        width REAL DEFAULT 58.0,
        height REAL DEFAULT 50.0,
        unit TEXT DEFAULT 'mm',
        elements TEXT NOT NULL,
        is_active INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        printer_type TEXT DEFAULT 'TSC',
        paper_size TEXT DEFAULT '58x50',
        settings TEXT
      )
    ''');
    print('✅ New table created with complete schema');
    
    // ═══ STEP 4: Verify columns ═══
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableLabelTemplates)');
    print('\n📊 Table columns:');
    for (var col in tableInfo) {
      print('   - ${col['name']} (${col['type']})');
    }
    
    // ═══ STEP 5: Restore data (if any) ═══
    if (backup.isNotEmpty) {
      print('\n🔄 Restoring ${backup.length} templates...');
      
      for (var row in backup) {
        try {
          // Ensure all required fields exist
          final template = {
            'id': row['id'],
            'name': row['name'] ?? 'Template',
            'width': row['width'] ?? 58.0,
            'height': row['height'] ?? 50.0,
            'unit': row['unit'] ?? 'mm',
            'elements': row['elements'] ?? '[]',
            'is_active': row['is_active'] ?? 0,
            'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
            'updated_at': row['updated_at'],
            'printer_type': row['printer_type'] ?? 'TSC',
            'paper_size': row['paper_size'] ?? '58x50',
            'settings': row['settings'],
          };
          
          await db.insert(tableLabelTemplates, template);
          print('   ✅ Restored: ${template['name']}');
        } catch (e) {
          print('   ⚠️ Failed to restore template: $e');
        }
      }
    }
    
    print('\n═══════════════════════════════════════════════════');
    print('✅ ✅ ✅ TABLE FIX COMPLETED SUCCESSFULLY! ✅ ✅ ✅');
    print('═══════════════════════════════════════════════════\n');
    
  } catch (e) {
    print('\n❌ ❌ ❌ FORCE FIX FAILED ❌ ❌ ❌');
    print('Error: $e');
    print('═══════════════════════════════════════════════════\n');
    rethrow;
  }
}

Future<void> forceUpgradeToV10() async {
    print('🔧 ═══════════════════════════════════════════════════');
    print('🔧 FORCE UPGRADE: Adding custom fields to measurements');
    print('═══════════════════════════════════════════════════');
    
    final db = await database;
    
    try {
      // Get current columns
      final columns = await db.rawQuery('PRAGMA table_info($tableMeasurements)');
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      print('📊 Current columns: $columnNames');
      
      // List of columns to add
      final newColumns = {
        'gross_weight': 'REAL',
        'tare_weight': 'REAL',
        'weight_status': 'TEXT',
        'quantity': 'INTEGER',
        'unit_weight': 'REAL',
        'product': 'TEXT',
        'client': 'TEXT',
        'id_field': 'TEXT',
        'supplier': 'TEXT',
        'batch_number': 'TEXT',
        'material_code_field': 'TEXT',
        'sku': 'TEXT',
        'location': 'TEXT',
        'operator_field': 'TEXT',
        'custom': 'TEXT',
      };
      
      // Add missing columns
      int addedCount = 0;
      for (var entry in newColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          await db.execute(
            'ALTER TABLE $tableMeasurements ADD COLUMN ${entry.key} ${entry.value}'
          );
          print('✅ Added column: ${entry.key}');
          addedCount++;
        } else {
          print('ℹ️ Column already exists: ${entry.key}');
        }
      }
      
      print('\n═══════════════════════════════════════════════════');
      print('✅ FORCE UPGRADE COMPLETED!');
      print('   Added $addedCount new columns');
      print('═══════════════════════════════════════════════════\n');
      
    } catch (e) {
      print('\n❌ ❌ ❌ FORCE UPGRADE FAILED ❌ ❌ ❌');
      print('Error: $e');
      print('═══════════════════════════════════════════════════\n');
      rethrow;
    }
  }

   Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('🔒 Database connection closed');
    }
  }

  /// Reset database instance (untuk testing)
  static void resetInstance() {
    _database = null;
  }
}