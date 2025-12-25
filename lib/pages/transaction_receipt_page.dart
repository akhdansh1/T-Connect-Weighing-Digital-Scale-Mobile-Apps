import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../models/transaction_receipt.dart';
import 'package:intl/intl.dart';
import '../utils/template_print_helper.dart';

class TransactionReceiptPage extends StatefulWidget {
  const TransactionReceiptPage({Key? key}) : super(key: key);

  @override
  State<TransactionReceiptPage> createState() => _TransactionReceiptPageState();
}

class _TransactionReceiptPageState extends State<TransactionReceiptPage> {
  final dbHelper = DatabaseHelper.instance;
  List<TransactionReceipt> receipts = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => isLoading = true);
    receipts = await dbHelper.readAllTransactionReceipts(limit: 200);
    setState(() => isLoading = false);
  }

  List<TransactionReceipt> get filteredReceipts {
    if (searchQuery.isEmpty) return receipts;
    return receipts.where((r) {
      return r.receiptNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          r.materialName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (r.customerName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Receipts'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceipts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search receipts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Receipts List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredReceipts.isEmpty
                    ? _buildEmptyState()
                    : _buildReceiptList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReceiptDialog(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('New Receipt'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No Receipts Yet' : 'No Results Found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty 
                ? 'Tap + to create your first receipt'
                : 'Try different search keywords',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredReceipts.length,
      itemBuilder: (context, index) {
        final receipt = filteredReceipts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showReceiptDialog(receipt: receipt),
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
                              receipt.receiptNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(receipt.transactionDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          receipt.status,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: receipt.isPaid 
                            ? Colors.green[50] 
                            : Colors.orange[50],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${receipt.materialName} (Grade ${receipt.grade})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (receipt.hasBatch)
                    Row(
                      children: [
                        Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          receipt.batchNumber!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.scale_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Net: ${receipt.netWeight.toStringAsFixed(2)} ${receipt.unit}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        'Rp ${_formatNumber(receipt.totalAmount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _printReceipt(receipt),
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showReceiptDialog(receipt: receipt),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
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
    );
  }

  void _showReceiptDialog({TransactionReceipt? receipt}) {
    final isEdit = receipt != null;
    
    // Controllers
    final numberController = TextEditingController(
      text: receipt?.receiptNumber ?? TransactionReceipt.generateReceiptNumber(),
    );
    final batchController = TextEditingController(
      text: receipt?.batchNumber ?? _generateBatchNumber(),
    );
    final materialController = TextEditingController(text: receipt?.materialName ?? '');
    final grossWeightController = TextEditingController(
      text: receipt?.grossWeight.toString() ?? '',
    );
    final tareWeightController = TextEditingController(
      text: receipt?.tareWeight.toString() ?? '0',
    );
    final netWeightController = TextEditingController(
      text: receipt?.netWeight.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: receipt?.pricePerKg.toString() ?? '0',
    );
    final operatorController = TextEditingController(
      text: receipt?.operatorName ?? 'Operator-001',
    );
    
    String selectedGrade = receipt?.grade ?? 'A';
    String selectedCategory = receipt?.category ?? 'General';
    int subtotal = receipt?.subtotal ?? 0;
    
    // Auto calculate net weight
    void calculateNetWeight() {
      double gross = double.tryParse(grossWeightController.text) ?? 0.0;
      double tare = double.tryParse(tareWeightController.text) ?? 0.0;
      double net = gross - tare;
      netWeightController.text = net > 0 ? net.toStringAsFixed(2) : '0.00';
      
      // Calculate price
      int price = int.tryParse(priceController.text) ?? 0;
      subtotal = (net * price).round();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add_circle,
                color: Colors.green[700],
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Receipt' : 'New Receipt'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Receipt Number
                  TextField(
                    controller: numberController,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    enabled: !isEdit,
                  ),
                  const SizedBox(height: 12),
                  
                  // Batch Number
                  TextField(
                    controller: batchController,
                    decoration: const InputDecoration(
                      labelText: 'Batch Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Material Name
                  TextField(
                    controller: materialController,
                    decoration: const InputDecoration(
                      labelText: 'Material Name *',
                      hintText: 'e.g., Beras Premium',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  
                  // Category & Grade
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: ['General', 'Food Grade', 'Raw Material', 'Chemical']
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGrade,
                          decoration: const InputDecoration(
                            labelText: 'Grade',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.star),
                          ),
                          items: ['A', 'B', 'C', 'Premium', 'Standard']
                              .map((grade) => DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedGrade = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'WEIGHT INFORMATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Gross Weight
                  TextField(
                    controller: grossWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Gross Weight *',
                      hintText: 'Total weight with container',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fitness_center),
                      suffixText: 'KG',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      setDialogState(() {
                        calculateNetWeight();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Tare Weight
                  TextField(
                    controller: tareWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Tare Weight',
                      hintText: 'Container/packaging weight',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                      suffixText: 'KG',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      setDialogState(() {
                        calculateNetWeight();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Net Weight (calculated)
                  TextField(
                    controller: netWeightController,
                    decoration: InputDecoration(
                      labelText: 'Net Weight (Auto)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.balance),
                      suffixText: 'KG',
                      filled: true,
                      fillColor: Colors.green[50],
                    ),
                    enabled: false,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'PRICE & OPERATOR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Price per KG
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per KG *',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) {
                      setDialogState(() {
                        calculateNetWeight();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Operator
                  TextField(
                    controller: operatorController,
                    decoration: const InputDecoration(
                      labelText: 'Operator Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  
                  // Total Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp ${_formatNumber(subtotal)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDelete(receipt);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Validation
                if (materialController.text.trim().isEmpty ||
                    grossWeightController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill required fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                calculateNetWeight();

                final newReceipt = TransactionReceipt(
                  id: receipt?.id,
                  receiptNumber: numberController.text.trim(),
                  batchNumber: batchController.text.trim(),
                  transactionDate: receipt?.transactionDate ?? DateTime.now(),
                  operatorCode: 'OP-001',
                  operatorName: operatorController.text.trim(),
                  materialCode: 'MAT-${DateTime.now().millisecondsSinceEpoch}',
                  materialName: materialController.text.trim(),
                  category: selectedCategory,
                  grade: selectedGrade,
                  grossWeight: double.parse(grossWeightController.text),
                  tareWeight: double.tryParse(tareWeightController.text) ?? 0.0,
                  netWeight: double.parse(netWeightController.text),
                  unit: 'KG',
                  pricePerKg: int.parse(priceController.text),
                  subtotal: subtotal,
                  totalAmount: subtotal,
                  createdAt: receipt?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                _saveReceipt(newReceipt, isEdit);
                Navigator.pop(context);
              },
              icon: Icon(isEdit ? Icons.save : Icons.add),
              label: Text(isEdit ? 'Update' : 'Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReceipt(TransactionReceipt receipt, bool isEdit) async {
    try {
      if (isEdit) {
        await dbHelper.updateTransactionReceipt(receipt);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Receipt updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await dbHelper.createTransactionReceipt(receipt);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Receipt created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      _loadReceipts();
    } catch (e) {
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

  void _confirmDelete(TransactionReceipt receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Receipt'),
          ],
        ),
        content: Text('Delete receipt "${receipt.receiptNumber}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await dbHelper.deleteTransactionReceipt(receipt.id!);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Receipt deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              _loadReceipts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(TransactionReceipt receipt) async {
    try {
      // Use TemplatePrintHelper for printing
      final success = await TemplatePrintHelper.printTransactionReceipt(
        context: context,
        receipt: receipt,
        showPreview: true,
      );
      
      if (success) {
        print('✅ Receipt printed successfully: ${receipt.receiptNumber}');
      } else {
        print('⚠️ Print cancelled or failed');
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

  String _generateBatchNumber() {
    final now = DateTime.now();
    return 'BATCH-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}