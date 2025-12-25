import '../models/weighing_ticket.dart';
import '../models/transaction_receipt.dart';
import '../models/qc_report.dart';
import '../models/company_info.dart';

/// Service untuk generate print templates dalam format ESC/POS
class PrintTemplateService {
  // ESC/POS Commands
  static const String ESC = '\x1B';
  static const String GS = '\x1D';
  
  // Text formatting
  static const String INIT = '$ESC@'; // Initialize printer
  static const String BOLD_ON = '$ESC\x45\x01';
  static const String BOLD_OFF = '$ESC\x45\x00';
  static const String CENTER = '$ESC\x61\x01';
  static const String LEFT = '$ESC\x61\x00';
  static const String RIGHT = '$ESC\x61\x02';
  static const String DOUBLE_HEIGHT = '$GS\x21\x01';
  static const String NORMAL_SIZE = '$GS\x21\x00';
  static const String CUT_PAPER = '$GS\x56\x00';
  static const String LINE_FEED = '\n';
  
  // Helper: Center text dengan padding
  static String centerText(String text, {int width = 32}) {
    if (text.length >= width) return text;
    int padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }
  
  // Helper: Create line separator
  static String line({int width = 32, String char = '='}) {
    return char * width;
  }
  
  // Helper: Format currency
  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
  
  // Helper: Left-right aligned text
  static String leftRight(String left, String right, {int width = 32}) {
    int spaces = width - left.length - right.length;
    if (spaces < 1) spaces = 1;
    return left + (' ' * spaces) + right;
  }

  // ========== WEIGHING TICKET TEMPLATE ==========
  
  static String generateWeighingTicket({
    required WeighingTicket ticket,
    required CompanyInfo company,
  }) {
    StringBuffer buffer = StringBuffer();
    
    // Initialize
    buffer.write(INIT);
    
    // Header
    buffer.write(CENTER + BOLD_ON);
    buffer.write(company.companyName + LINE_FEED);
    buffer.write(BOLD_OFF + NORMAL_SIZE);
    buffer.write(centerText(company.department) + LINE_FEED);
    buffer.write(line() + LINE_FEED);
    
    // Title
    buffer.write(BOLD_ON + DOUBLE_HEIGHT);
    buffer.write(centerText('WEIGHING TICKET') + LINE_FEED);
    buffer.write(BOLD_OFF + NORMAL_SIZE);
    buffer.write(line() + LINE_FEED);
    
    // Ticket Info
    buffer.write(LEFT);
    buffer.write(leftRight('Ticket No', ': ${ticket.ticketNumber}') + LINE_FEED);
    buffer.write(leftRight('Date', ': ${_formatDate(ticket.weighingDate)}') + LINE_FEED);
    buffer.write(leftRight('Time', ': ${_formatTime(ticket.weighingDate)}') + LINE_FEED);
    buffer.write(leftRight('Operator', ': ${ticket.operatorName}') + LINE_FEED);
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Material Info
    buffer.write(BOLD_ON);
    buffer.write('Material Information' + LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write(leftRight('Material', ': ${ticket.materialName}') + LINE_FEED);
    buffer.write(leftRight('Category', ': ${ticket.category}') + LINE_FEED);
    
    if (ticket.hasBatchNumber) {
      buffer.write(leftRight('Batch No', ': ${ticket.batchNumber}') + LINE_FEED);
    }
    
    if (ticket.hasSupplierInfo) {
      buffer.write(leftRight('Supplier', ': ${ticket.supplierName}') + LINE_FEED);
    }
    
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Vehicle Info (if available)
    if (ticket.hasVehicleInfo) {
      buffer.write(BOLD_ON);
      buffer.write('Vehicle Information' + LINE_FEED);
      buffer.write(BOLD_OFF);
      buffer.write(leftRight('Vehicle', ': ${ticket.vehicleNumber}') + LINE_FEED);
      
      if (ticket.driverName != null && ticket.driverName!.isNotEmpty) {
        buffer.write(leftRight('Driver', ': ${ticket.driverName}') + LINE_FEED);
      }
      
      buffer.write(line(char: '-') + LINE_FEED);
    }
    
    // Weight Data
    buffer.write(BOLD_ON);
    buffer.write('Weight Measurement' + LINE_FEED);
    buffer.write(BOLD_OFF);
    
    if (ticket.firstWeight != null) {
      buffer.write(leftRight('1st Weight', ': ${ticket.firstWeight!.toStringAsFixed(2)} ${ticket.unit}') + LINE_FEED);
    }
    
    if (ticket.secondWeight != null) {
      buffer.write(leftRight('2nd Weight', ': ${ticket.secondWeight!.toStringAsFixed(2)} ${ticket.unit}') + LINE_FEED);
    }
    
    if (ticket.tareWeight != null) {
      buffer.write(leftRight('Tare Weight', ': ${ticket.tareWeight!.toStringAsFixed(2)} ${ticket.unit}') + LINE_FEED);
    }
    
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Net Weight (HIGHLIGHT)
    buffer.write(BOLD_ON + DOUBLE_HEIGHT);
    buffer.write(leftRight('NET WEIGHT', ': ${ticket.netWeight.toStringAsFixed(2)}') + LINE_FEED);
    buffer.write(centerText(ticket.unit) + LINE_FEED);
    buffer.write(BOLD_OFF + NORMAL_SIZE);
    
    buffer.write(line() + LINE_FEED);
    
    // Footer
    buffer.write(CENTER);
    buffer.write('Status: ${ticket.status}' + LINE_FEED);
    buffer.write(line(char: '-') + LINE_FEED);
    buffer.write('Authorized Signature' + LINE_FEED);
    buffer.write(LINE_FEED);
    buffer.write('_______________________' + LINE_FEED);
    buffer.write('Weighing Officer' + LINE_FEED);
    buffer.write(line() + LINE_FEED);
    
    // Company info footer
    buffer.write(company.companyName + LINE_FEED);
    buffer.write(company.phone + LINE_FEED);
    
    // Cut paper
    buffer.write(LINE_FEED + LINE_FEED + LINE_FEED);
    buffer.write(CUT_PAPER);
    
    return buffer.toString();
  }

  // ========== TRANSACTION RECEIPT TEMPLATE ==========
  
  static String generateTransactionReceipt({
    required TransactionReceipt receipt,
    required CompanyInfo company,
  }) {
    StringBuffer buffer = StringBuffer();
    
    // Initialize
    buffer.write(INIT);
    
    // Header
    buffer.write(CENTER + BOLD_ON);
    buffer.write(company.companyName + LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write(centerText(company.address) + LINE_FEED);
    buffer.write(centerText('${company.city}, ${company.province}') + LINE_FEED);
    buffer.write(centerText(company.phone) + LINE_FEED);
    buffer.write(line() + LINE_FEED);
    
    // Title
    buffer.write(BOLD_ON);
    buffer.write(centerText('SALES RECEIPT') + LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write(line() + LINE_FEED);
    
    // Receipt Info
    buffer.write(LEFT);
    buffer.write(leftRight('Receipt No', ': ${receipt.receiptNumber}') + LINE_FEED);
    buffer.write(leftRight('Date', ': ${_formatDate(receipt.transactionDate)}') + LINE_FEED);
    buffer.write(leftRight('Time', ': ${_formatTime(receipt.transactionDate)}') + LINE_FEED);
    
    if (receipt.hasCustomer) {
      buffer.write(leftRight('Customer', ': ${receipt.customerName}') + LINE_FEED);
    }
    
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Item Details
    buffer.write(BOLD_ON);
    buffer.write('Item Details' + LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write(leftRight('Material', ': ${receipt.materialName}') + LINE_FEED);
    buffer.write(leftRight('Category', ': ${receipt.category}') + LINE_FEED);
    buffer.write(leftRight('Grade', ': ${receipt.grade}') + LINE_FEED);
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Weight & Price
    buffer.write(leftRight('Net Weight', ': ${receipt.netWeight.toStringAsFixed(2)} ${receipt.unit}') + LINE_FEED);
    buffer.write(leftRight('Price/kg', ': Rp ${formatCurrency(receipt.pricePerKg)}') + LINE_FEED);
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Price Breakdown
    buffer.write(leftRight('Subtotal', ': Rp ${formatCurrency(receipt.subtotal)}') + LINE_FEED);
    
    if (receipt.hasTax) {
      buffer.write(leftRight('Tax (${receipt.taxRate.toStringAsFixed(0)}%)', ': Rp ${formatCurrency(receipt.taxAmount)}') + LINE_FEED);
      buffer.write(line(char: '-') + LINE_FEED);
    }
    
    // Total (HIGHLIGHT)
    buffer.write(BOLD_ON + DOUBLE_HEIGHT);
    buffer.write(leftRight('TOTAL', 'Rp ${formatCurrency(receipt.totalAmount)}') + LINE_FEED);
    buffer.write(BOLD_OFF + NORMAL_SIZE);
    buffer.write(line() + LINE_FEED);
    
    // Payment Info
    buffer.write(LEFT);
    buffer.write(leftRight('Payment', ': ${receipt.paymentMethod}') + LINE_FEED);
    
    if (receipt.paidAmount != null) {
      buffer.write(leftRight('Paid', ': Rp ${formatCurrency(receipt.paidAmount!)}') + LINE_FEED);
    }
    
    if (receipt.hasChange) {
      buffer.write(leftRight('Change', ': Rp ${formatCurrency(receipt.changeAmount!)}') + LINE_FEED);
    }
    
    buffer.write(line() + LINE_FEED);
    
    // Footer
    buffer.write(CENTER);
    buffer.write('Thank You For Your Trust' + LINE_FEED);
    buffer.write(company.website + LINE_FEED);
    buffer.write(line(char: '-') + LINE_FEED);
    buffer.write('Operator: ${receipt.operatorName}' + LINE_FEED);
    
    // Cut paper
    buffer.write(LINE_FEED + LINE_FEED + LINE_FEED);
    buffer.write(CUT_PAPER);
    
    return buffer.toString();
  }

  // ========== QC REPORT TEMPLATE ==========
  
  static String generateQCReport({
    required QCReport report,
    required CompanyInfo company,
  }) {
    StringBuffer buffer = StringBuffer();
    
    // Initialize
    buffer.write(INIT);
    
    // Header
    buffer.write(CENTER + BOLD_ON);
    buffer.write('QUALITY CONTROL REPORT' + LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write(centerText(company.companyName) + LINE_FEED);
    buffer.write(centerText('${company.department} - QC Lab') + LINE_FEED);
    buffer.write(line() + LINE_FEED);
    
    // Report Info
    buffer.write(LEFT);
    buffer.write(leftRight('QC Report', ': ${report.reportNumber}') + LINE_FEED);
    buffer.write(leftRight('Date', ': ${_formatDate(report.inspectionDate)}') + LINE_FEED);
    buffer.write(leftRight('Time', ': ${_formatTime(report.inspectionDate)}') + LINE_FEED);
    buffer.write(leftRight('Inspector', ': ${report.inspectorName}') + LINE_FEED);
    
    if (report.supervisorName != null && report.supervisorName!.isNotEmpty) {
      buffer.write(leftRight('Supervisor', ': ${report.supervisorName}') + LINE_FEED);
    }
    
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Product Info
    buffer.write(BOLD_ON);
    buffer.write('Product Information' + LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write(leftRight('Product', ': ${report.productName}') + LINE_FEED);
    buffer.write(leftRight('Category', ': ${report.category}') + LINE_FEED);
    buffer.write(leftRight('Grade', ': ${report.grade}') + LINE_FEED);
    
    if (report.hasBatchInfo) {
      buffer.write(leftRight('Batch No', ': ${report.batchNumber}') + LINE_FEED);
      
      if (report.lotNumber != null && report.lotNumber!.isNotEmpty) {
        buffer.write(leftRight('Lot No', ': ${report.lotNumber}') + LINE_FEED);
      }
    }
    
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Specification
    buffer.write(BOLD_ON);
    buffer.write('Weight Specification' + LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write(leftRight('Target Wt', ': ${report.targetWeight.toStringAsFixed(2)} ${report.unit}') + LINE_FEED);
    buffer.write(leftRight('Tolerance', ': ±${report.tolerance.toStringAsFixed(2)}%') + LINE_FEED);
    buffer.write(leftRight('Min - Max', ': ${report.toleranceMin.toStringAsFixed(3)} - ${report.toleranceMax.toStringAsFixed(3)} ${report.unit}') + LINE_FEED);
    buffer.write(line(char: '-') + LINE_FEED);
    
    // Measurement Data
    buffer.write(BOLD_ON);
    buffer.write('Measurement Results' + LINE_FEED);
    buffer.write(BOLD_OFF);
    buffer.write(leftRight('Sample 1', ': ${report.sample1Weight.toStringAsFixed(2)} ${report.unit}') + LINE_FEED);
    
    if (report.sample2Weight != null) {
      buffer.write(leftRight('Sample 2', ': ${report.sample2Weight!.toStringAsFixed(2)} ${report.unit}') + LINE_FEED);
    }
    
    if (report.sample3Weight != null) {
      buffer.write(leftRight('Sample 3', ': ${report.sample3Weight!.toStringAsFixed(2)} ${report.unit}') + LINE_FEED);
    }
    
    buffer.write(line(char: '-') + LINE_FEED);
    buffer.write(leftRight('Average', ': ${report.averageWeight.toStringAsFixed(2)} ${report.unit}') + LINE_FEED);
    
    if (report.standardDeviation != null) {
      buffer.write(leftRight('Std Dev', ': ${report.standardDeviation!.toStringAsFixed(3)} ${report.unit}') + LINE_FEED);
    }
    
    buffer.write(line() + LINE_FEED);
    
    // Result (HIGHLIGHT)
    buffer.write(CENTER + BOLD_ON + DOUBLE_HEIGHT);
    String resultSymbol = report.isPassed ? '✓' : '✗';
    buffer.write('RESULT: $resultSymbol ${report.result}' + LINE_FEED);
    buffer.write(BOLD_OFF + NORMAL_SIZE);
    
    buffer.write(line() + LINE_FEED);
    
    // Signature Area
    buffer.write(LEFT);
    buffer.write('QC Inspector:' + LINE_FEED);
    buffer.write(LINE_FEED);
    buffer.write('_______________________' + LINE_FEED);
    buffer.write(report.inspectorName + LINE_FEED);
    buffer.write(LINE_FEED);
    buffer.write('Supervisor:' + LINE_FEED);
    buffer.write(LINE_FEED);
    buffer.write('_______________________' + LINE_FEED);
    
    buffer.write(line() + LINE_FEED);
    
    // Footer
    buffer.write(CENTER);
    buffer.write(company.companyName + LINE_FEED);
    buffer.write(company.phone + LINE_FEED);
    
    // Cut paper
    buffer.write(LINE_FEED + LINE_FEED + LINE_FEED);
    buffer.write(CUT_PAPER);
    
    return buffer.toString();
  }

  // ========== HELPER FUNCTIONS ==========
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}