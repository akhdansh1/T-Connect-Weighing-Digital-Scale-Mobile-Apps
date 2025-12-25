import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../models/supplier.dart';

class SupplierManagementPage extends StatefulWidget {
  const SupplierManagementPage({Key? key}) : super(key: key);

  @override
  State<SupplierManagementPage> createState() => _SupplierManagementPageState();
}

class _SupplierManagementPageState extends State<SupplierManagementPage> {
  final dbHelper = DatabaseHelper.instance;
  List<Supplier> suppliers = [];
  List<Supplier> filteredSuppliers = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => isLoading = true);
    
    try {
      final allSuppliers = await dbHelper.readAllSuppliers();
      setState(() {
        suppliers = allSuppliers;
        _filterSuppliers();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading suppliers: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading suppliers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterSuppliers() {
    setState(() {
      filteredSuppliers = suppliers.where((supplier) {
        final matchesSearch = searchQuery.isEmpty ||
            supplier.supplierName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            supplier.supplierCode.toLowerCase().contains(searchQuery.toLowerCase()) ||
            supplier.companyName.toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesType = selectedType == 'All' ||
            supplier.supplierType == selectedType;
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _showAddEditDialog({Supplier? supplier}) {
    final isEdit = supplier != null;
    
    final codeController = TextEditingController(
      text: supplier?.supplierCode ?? _generateSupplierCode(),
    );
    final nameController = TextEditingController(text: supplier?.supplierName ?? '');
    final companyController = TextEditingController(text: supplier?.companyName ?? '');
    final contactController = TextEditingController(text: supplier?.contactPerson ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');
    final cityController = TextEditingController(text: supplier?.city ?? '');
    final provinceController = TextEditingController(text: supplier?.province ?? '');
    final postalController = TextEditingController(text: supplier?.postalCode ?? '');
    final taxController = TextEditingController(text: supplier?.taxId ?? '');
    final notesController = TextEditingController(text: supplier?.notes ?? '');
    
    String selectedType = supplier?.supplierType ?? 'Domestic';
    bool isActive = supplier?.isActive ?? true;

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
              Text(isEdit ? 'Edit Supplier' : 'Add New Supplier'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Supplier Code
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Supplier Code *',
                      hintText: 'SUP-XXXXXX',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.qr_code),
                      enabled: !isEdit,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Supplier Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Name *',
                      hintText: 'e.g., PT Supplier ABC',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  
                  // Company Name
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name *',
                      hintText: 'e.g., CV Jaya Makmur',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  
                  // Contact Person & Phone
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: contactController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Email
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'supplier@email.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  
                  // Address
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      hintText: 'Jl. Example No. 123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  // City & Province
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: provinceController,
                          decoration: const InputDecoration(
                            labelText: 'Province *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.map),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Postal Code & Tax ID
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: postalController,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.local_post_office),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: taxController,
                          decoration: const InputDecoration(
                            labelText: 'Tax ID / NPWP',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Supplier Type
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ['Domestic', 'Import', 'Local', 'International']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Additional information...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  
                  // Active Status
                  SwitchListTile(
                    title: const Text('Active Status'),
                    subtitle: Text(
                      isActive ? 'Supplier is active' : 'Supplier is inactive',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                    secondary: Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Validation
                if (nameController.text.trim().isEmpty ||
                    companyController.text.trim().isEmpty ||
                    contactController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty ||
                    cityController.text.trim().isEmpty ||
                    provinceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Create/Update Supplier
                final newSupplier = Supplier(
                  id: supplier?.id,
                  supplierCode: codeController.text.trim(),
                  supplierName: nameController.text.trim(),
                  companyName: companyController.text.trim(),
                  contactPerson: contactController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),  // ✅ FIX: Remove conditional
                  address: addressController.text.trim(),
                  city: cityController.text.trim(),
                  province: provinceController.text.trim(),
                  postalCode: postalController.text.trim(),  // ✅ FIX: Remove conditional
                  taxId: taxController.text.trim(),  // ✅ FIX: Remove conditional
                  supplierType: selectedType,
                  isActive: isActive,
                  notes: notesController.text.trim(),  // ✅ FIX: Remove conditional
                  createdAt: supplier?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                try {
                  if (isEdit) {
                    await dbHelper.updateSupplier(newSupplier);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Supplier updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await dbHelper.createSupplier(newSupplier);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Supplier added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                  
                  _loadSuppliers();
                } catch (e) {
                  print('Error saving supplier: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
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

  void _showDeleteConfirmation(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Supplier?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${supplier.supplierName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await dbHelper.deleteSupplier(supplier.id!);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Supplier deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                _loadSuppliers();
              } catch (e) {
                print('Error deleting supplier: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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

  String _generateSupplierCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'SUP-${timestamp.toString().substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Management'),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search suppliers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    _filterSuppliers();
                  },
                ),
                const SizedBox(height: 12),
                
                // Type Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', selectedType == 'All'),
                      _buildFilterChip('Domestic', selectedType == 'Domestic'),
                      _buildFilterChip('Import', selectedType == 'Import'),
                      _buildFilterChip('Local', selectedType == 'Local'),
                      _buildFilterChip('International', selectedType == 'International'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.business,
                  'Total',
                  suppliers.length.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.check_circle,
                  'Active',
                  suppliers.where((s) => s.isActive).length.toString(),
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.filter_list,
                  'Filtered',
                  filteredSuppliers.length.toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),
          
          // Suppliers List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSuppliers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadSuppliers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredSuppliers.length,
                          itemBuilder: (context, index) {
                            final supplier = filteredSuppliers[index];
                            return _buildSupplierCard(supplier);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedType = selected ? label : 'All';
            _filterSuppliers();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.green[100],
        checkmarkColor: Colors.green[700],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No suppliers yet' : 'No suppliers found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tap the + button to add your first supplier'
                : 'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAddEditDialog(supplier: supplier),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: supplier.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.business,
                      color: supplier.isActive ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.supplierName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          supplier.supplierCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!supplier.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.apartment, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      supplier.companyName,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    supplier.contactPerson,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    supplier.phone,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${supplier.city}, ${supplier.province}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.category,
                    supplier.supplierType,
                    Colors.blue,
                  ),
                  if (supplier.email != null)
                    _buildInfoChip(
                      Icons.email,
                      supplier.email!,
                      Colors.purple,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddEditDialog(supplier: supplier),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(supplier),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}