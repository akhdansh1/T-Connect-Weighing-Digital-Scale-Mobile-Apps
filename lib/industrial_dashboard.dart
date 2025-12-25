import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/material.dart' as mat;
import '../models/company_info.dart';
import '../models/weighing_ticket.dart';
import '../utils/template_print_helper.dart';
import '../pages/visual_label_designer_page.dart';
import 'material_management_page.dart';
import 'supplier_management_page.dart';
import 'operator_management_page.dart';
import 'vehicle_management_page.dart';

class IndustrialDashboard extends StatefulWidget {
  const IndustrialDashboard({Key? key}) : super(key: key);

  @override
  State<IndustrialDashboard> createState() => _IndustrialDashboardState();
}

class _IndustrialDashboardState extends State<IndustrialDashboard> {
  final dbHelper = DatabaseHelper.instance;
  
  CompanyInfo? companyInfo;
  Map<String, dynamic> stats = {};
  List<mat.Material> recentMaterials = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    try {
      // Load company info
      companyInfo = await dbHelper.getCompanyInfo();

      // Load statistics
      stats = await dbHelper.getDashboardStats();

      // Load recent materials
      final allMaterials = await dbHelper.readAllMaterials();
      recentMaterials = allMaterials.take(5).toList();

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() => isLoading = false);
    }
  }

  // ✅ REPLACE _showQuickWeighingDialog() di industrial_dashboard.dart dengan ini:

void _showQuickWeighingDialog() {
  final ticketNumberController = TextEditingController(
    text: WeighingTicket.generateTicketNumber(),
  );
  final batchController = TextEditingController(
    text: WeighingTicket.generateBatchNumber(),
  );
  final materialController = TextEditingController();
  final grossWeightController = TextEditingController();
  final tareWeightController = TextEditingController();
  final netWeightController = TextEditingController();
  final operatorController = TextEditingController(text: 'Operator-001');
  
  String selectedUnit = 'KG';
  String selectedCategory = 'General';
  String selectedGrade = 'A';  // ✅ NEW
  
  // ✅ Auto-calculate net weight
  void calculateNetWeight() {
    final gross = double.tryParse(grossWeightController.text) ?? 0.0;
    final tare = double.tryParse(tareWeightController.text) ?? 0.0;
    final net = gross - tare;
    netWeightController.text = net > 0 ? net.toStringAsFixed(2) : '0.00';
  }
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.scale, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Quick Weighing Entry'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ticket Number
              TextField(
                controller: ticketNumberController,
                decoration: const InputDecoration(
                  labelText: 'Ticket Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                enabled: false,
              ),
              const SizedBox(height: 12),
              
              // Batch Number
              TextField(
                controller: batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch Number',
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
                autofocus: true,
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
              const SizedBox(height: 12),
              
              // Gross Weight
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: grossWeightController,
                      decoration: const InputDecoration(
                        labelText: 'Gross Weight *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        setDialogState(() {
                          calculateNetWeight();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: ['KG', 'TON', 'GRAM', 'LBS']
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tare Weight
              TextField(
                controller: tareWeightController,
                decoration: const InputDecoration(
                  labelText: 'Tare Weight',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.number,
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
                  filled: true,
                  fillColor: Colors.green[50],
                ),
                enabled: false,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              
              // Operator
              TextField(
                controller: operatorController,
                decoration: const InputDecoration(
                  labelText: 'Operator',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'QC Report will be generated with QR Code',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Validation
              if (materialController.text.trim().isEmpty ||
                  grossWeightController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill Material and Gross Weight'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              // Parse weights
              final grossWeight = double.tryParse(grossWeightController.text);
              final tareWeight = double.tryParse(tareWeightController.text) ?? 0.0;
              final netWeight = double.tryParse(netWeightController.text);
              
              if (grossWeight == null || grossWeight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid gross weight'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              _saveAndPrintWeighingTicket(
                ticketNumber: ticketNumberController.text,
                batchNumber: batchController.text.trim(),
                materialName: materialController.text.trim(),
                category: selectedCategory,
                grade: selectedGrade,  // ✅ NEW
                grossWeight: grossWeight,
                tareWeight: tareWeight,
                netWeight: netWeight ?? (grossWeight - tareWeight),
                unit: selectedUnit,
                operatorName: operatorController.text.trim(),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Save & Print QC'),
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

// ✅ UPDATE fungsi _saveAndPrintWeighingTicket
Future<void> _saveAndPrintWeighingTicket({
  required String ticketNumber,
  required String batchNumber,
  required String materialName,
  required String category,
  required String grade,          // ✅ NEW
  required double grossWeight,
  required double tareWeight,
  required double netWeight,
  required String unit,
  required String operatorName,
}) async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Create WeighingTicket
    final ticket = WeighingTicket(
      ticketNumber: ticketNumber,
      weighingDate: DateTime.now(),
      operatorCode: 'OP-001',
      operatorName: operatorName,
      materialCode: 'MAT-${DateTime.now().millisecondsSinceEpoch}',
      materialName: materialName,
      category: category,
      batchNumber: batchNumber,
      grade: grade,               // ✅ NEW
      firstWeight: grossWeight,   // ✅ GROSS
      tareWeight: tareWeight,     // ✅ TARE
      netWeight: netWeight,       // ✅ NET
      unit: unit,
      status: 'Completed',
      createdAt: DateTime.now(),
    );
    
    // Save to database
    await dbHelper.createWeighingTicket(ticket);
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading
    
    // Print QC Report dengan template
    final success = await TemplatePrintHelper.printWeighingTicket(
      context: context,
      ticket: ticket,
      showPreview: true,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ QC Report saved & printed: $ticketNumber'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Refresh dashboard
      _loadDashboardData();
    }
    
  } catch (e) {
    print('❌ Error saving QC report: $e');
    
    if (mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyInfo?.companyName ?? 'T-Connect Industrial',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              companyInfo?.department ?? 'Weighing System',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    _buildWelcomeCard(),
                    const SizedBox(height: 16),

                    // Statistics Cards
                    _buildStatisticsSection(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActionsSection(),
                    const SizedBox(height: 24),

                    // Recent Materials
                    _buildRecentMaterialsSection(),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
      onPressed: _showQuickWeighingDialog,
      backgroundColor: Colors.green[600],
      icon: const Icon(Icons.scale),
      label: const Text('Quick Weighing'),
    ),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'System Ready',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.inventory_2,
                title: 'Materials',
                value: stats['totalMaterials']?.toString() ?? '0',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.receipt_long,
                title: 'Today',
                value: stats['transactionsToday']?.toString() ?? '0',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                title: 'Revenue',
                value: _formatCurrency(stats['totalRevenue'] ?? 0),
                color: Colors.orange,
                isSmallText: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                title: 'Today',
                value: _formatCurrency(stats['revenueToday'] ?? 0),
                color: Colors.purple,
                isSmallText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 16 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
             _buildActionCard(
  icon: Icons.inventory_2,
  title: 'Materials',
  subtitle: 'Manage materials',  // ✅ GANTI dari 'Coming soon'
  color: Colors.blue,
  onTap: () => _navigateTo(const MaterialManagementPage()),  // ✅ GANTI
),
_buildActionCard(
  icon: Icons.business,
  title: 'Suppliers',
  subtitle: 'Manage suppliers',  // ✅ GANTI dari 'Coming soon'
  color: Colors.green,
  onTap: () => _navigateTo(const SupplierManagementPage()),  // ✅ GANTI
),
_buildActionCard(
  icon: Icons.local_shipping,
  title: 'Vehicles',
  subtitle: 'Manage vehicles',  // ✅ GANTI dari 'Coming soon'
  color: Colors.orange,
  onTap: () => _navigateTo(const VehicleManagementPage()),  // ✅ GANTI
),
_buildActionCard(
  icon: Icons.people,
  title: 'Operators',
  subtitle: 'Manage operators',  // ✅ GANTI dari 'Coming soon'
  color: Colors.purple,
  onTap: () => _navigateTo(const OperatorManagementPage()),  // ✅ GANTI
),
_buildActionCard(
  icon: Icons.label,
  title: 'Label Designer',
  subtitle: 'Design print template',
  color: Colors.teal,
  onTap: () => _navigateTo(const VisualLabelDesignerPage()),  // ← Ini sudah OK
),
_buildActionCard(
  icon: Icons.settings,
  title: 'Settings',
  subtitle: 'App settings',
  color: Colors.grey,
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon')),
    );
  },  // ← Ini biarkan saja
),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildRecentMaterialsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Materials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
            child: const Text('View All'),
          ),
        ],  // ✅ TAMBAHKAN INI - Close children
      ),    // ✅ TAMBAHKAN INI - Close Row
      const SizedBox(height: 12),
      if (recentMaterials.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No materials yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material'),
                ),
              ],
            ),
          ),
        )
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentMaterials.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final material = recentMaterials[index];
            return _buildMaterialCard(material);
          },
        ),
    ],
  );
}

  Widget _buildMaterialCard(mat.Material material) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.materialName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${material.category} • ${material.grade}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                material.pricePerKg > 0 
                    ? 'Rp ${_formatNumber(material.pricePerKg)}'
                    : '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'per ${material.unit}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatCurrency(int amount) {
    if (amount == 0) return 'Rp 0';
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp ${_formatNumber(amount)}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).then((_) => _loadDashboardData()); // Refresh after return
  }
}