class TemplateVariable {
  final String key;
  final String label;
  final String description;
  final List<String> supportedPrinters; // ['TSC', 'ESCPOS'] atau ['TSC'] saja
  final String category;
  
  const TemplateVariable({
    required this.key,
    required this.label,
    required this.description,
    required this.supportedPrinters,
    required this.category,
  });
}

class TemplateVariables {
  // ========== COMMON VARIABLES (Support semua printer) ==========
  static const tanggal = TemplateVariable(
    key: 'TANGGAL',
    label: 'Tanggal',
    description: 'Tanggal transaksi (DD/MM/YYYY)',
    supportedPrinters: ['TSC', 'ESCPOS'],
    category: 'Date & Time',
  );
  
  static const waktu = TemplateVariable(
    key: 'WAKTU',
    label: 'Waktu',
    description: 'Waktu transaksi (HH:MM)',
    supportedPrinters: ['TSC', 'ESCPOS'],
    category: 'Date & Time',
  );
  
  static const berat = TemplateVariable(
    key: 'BERAT',
    label: 'Berat',
    description: 'Berat netto (angka)',
    supportedPrinters: ['TSC', 'ESCPOS'],
    category: 'Weight Data',
  );
  
  static const unit = TemplateVariable(
    key: 'UNIT',
    label: 'Unit',
    description: 'Satuan berat (KG/GRAM)',
    supportedPrinters: ['TSC', 'ESCPOS'],
    category: 'Weight Data',
  );
  
  static const namaBarang = TemplateVariable(
    key: 'NAMA_BARANG',
    label: 'Nama Barang',
    description: 'Nama material/barang',
    supportedPrinters: ['TSC', 'ESCPOS'],
    category: 'Material Info',
  );
  
  static const kategori = TemplateVariable(
    key: 'KATEGORI',
    label: 'Kategori',
    description: 'Kategori barang',
    supportedPrinters: ['TSC', 'ESCPOS'],
    category: 'Material Info',
  );
  
  static const operator = TemplateVariable(
    key: 'OPERATOR',
    label: 'Operator',
    description: 'Nama operator',
    supportedPrinters: ['TSC', 'ESCPOS'],
    category: 'User Info',
  );
  
  static const nomorTicket = TemplateVariable(
    key: 'NOMOR_TICKET',
    label: 'Nomor Ticket',
    description: 'ID unik ticket',
    supportedPrinters: ['TSC', 'ESCPOS'],
    category: 'Transaction',
  );
  
  // ========== TSC-ONLY VARIABLES ==========
  static const barcode = TemplateVariable(
    key: 'BARCODE',
    label: 'Barcode',
    description: 'Barcode (TSC only)',
    supportedPrinters: ['TSC'],
    category: 'Graphics',
  );
  
  static const qrCode = TemplateVariable(
    key: 'QRCODE',
    label: 'QR Code',
    description: 'QR Code (TSC only)',
    supportedPrinters: ['TSC'],
    category: 'Graphics',
  );
  
  // ========== COLLECTIONS ==========
  static const List<TemplateVariable> allVariables = [
    tanggal,
    waktu,
    berat,
    unit,
    namaBarang,
    kategori,
    operator,
    nomorTicket,
    barcode,
    qrCode,
  ];
  
  // Get variables by printer type
  static List<TemplateVariable> getVariablesByPrinter(String printerType) {
    return allVariables
        .where((v) => v.supportedPrinters.contains(printerType))
        .toList();
  }
  
  // Get variables by category
  static List<TemplateVariable> getVariablesByCategory(String category) {
    return allVariables.where((v) => v.category == category).toList();
  }
  
  // Get all categories
  static List<String> get categories {
    return allVariables.map((v) => v.category).toSet().toList();
  }
}