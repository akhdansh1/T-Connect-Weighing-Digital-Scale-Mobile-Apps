import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../services/database_helper.dart';

class SupplierManagementPage extends StatefulWidget {
  final Function(Supplier)? onSupplierSelected;
  
  const SupplierManagementPage({
    Key? key,
    this.onSupplierSelected,
  }) : super(key: key);

  @override
  State<SupplierManagementPage> createState() => _SupplierManagementPageState();
}

class _SupplierManagementPageState extends State<SupplierManagementPage> {
  final dbHelper = DatabaseHelper.instance;
  List<Supplier> supplierList = [];
  List<Supplier> filteredList = [];
  final searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => isLoading = true);
    
    try {
      final data = await dbHelper.readAllSuppliers(activeOnly: false);
      setState(() {
        supplierList = data;
        filteredList = data;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading suppliers: $e');
      setState(() => isLoading = false);
    }
  }

  void _searchSuppliers(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredList = supplierList;
      } else {
        filteredList = supplierList.where((supplier) {
          return supplier.supplierName.toLowerCase().contains(keyword.toLowerCase()) ||
                 supplier.supplierCode.toLowerCase().contains(keyword.toLowerCase()) ||
                 supplier.companyName.toLowerCase().contains(keyword.toLowerCase());
        }).toList();
      }
    });
  }

  void _showAddSupplierDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierFormPage(
          onSave: () {
            _loadSuppliers();
          },
        ),
      ),
    );
  }

  void _showEditSupplierDialog(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierFormPage(
          supplier: supplier,
          onSave: () {
            _loadSuppliers();
          },
        ),
      ),
    );
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier?'),
        content: Text('Delete "${supplier.supplierName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && supplier.id != null) {
      try {
        await dbHelper.deleteSupplier(supplier.id!);
        _loadSuppliers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Supplier deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _showAddSupplierDialog,
            tooltip: 'Add New Supplier',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              controller: searchController,
              onChanged: _searchSuppliers,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or company...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _searchSuppliers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Supplier List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_outlined, 
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              supplierList.isEmpty 
                                  ? 'No suppliers yet' 
                                  : 'No results found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (supplierList.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showAddSupplierDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Supplier'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final supplier = filteredList[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                // ✅ TETAP DI HALAMAN INI - TIDAK LANGSUNG POP
                                if (widget.onSupplierSelected != null) {
                                  widget.onSupplierSelected!(supplier);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '✓ Selected: ${supplier.supplierName}\n'
                                        '💡 Click Supplier button again to apply to field',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'Back',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Supplier Icon
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.store,
                                            color: Colors.orange[700],
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Supplier Info
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
                                                supplier.companyName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[100],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  supplier.supplierCode,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.orange[900],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: supplier.isActive 
                                                ? Colors.green[100] 
                                                : Colors.grey[300],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            supplier.isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: supplier.isActive 
                                                  ? Colors.green[900] 
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        
                                        // Actions Menu
                                        PopupMenuButton(
                                          icon: const Icon(Icons.more_vert),
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.check_circle, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Select'),
                                                ],
                                              ),
                                              onTap: () {
                                                Future.delayed(Duration.zero, () {
                                                  if (widget.onSupplierSelected != null) {
                                                    widget.onSupplierSelected!(supplier);
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '✓ Selected: ${supplier.supplierName}\n'
                                                          '💡 Click Supplier button again to apply',
                                                        ),
                                                        backgroundColor: Colors.green,
                                                        duration: const Duration(seconds: 3),
                                                        action: SnackBarAction(
                                                          label: 'Back',
                                                          textColor: Colors.white,
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                });
                                              },
                                            ),
                                            PopupMenuItem(
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                              onTap: () {
                                                Future.delayed(Duration.zero, () {
                                                  _showEditSupplierDialog(supplier);
                                                });
                                              },
                                            ),
                                            PopupMenuItem(
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                              onTap: () {
                                                Future.delayed(Duration.zero, () {
                                                  _deleteSupplier(supplier);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    const Divider(height: 20),
                                    
                                    // Contact Details
                                    _buildInfoRow(Icons.person, supplier.contactPerson),
                                    const SizedBox(height: 6),
                                    _buildInfoRow(Icons.phone, supplier.phone),
                                    if (supplier.email != null && supplier.email!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _buildInfoRow(Icons.email, supplier.email!),
                                    ],
                                    const SizedBox(height: 6),
                                    _buildInfoRow(
                                      Icons.location_on, 
                                      '${supplier.city}, ${supplier.province}'
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
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SUPPLIER FORM PAGE
// ==========================================

class SupplierFormPage extends StatefulWidget {
  final Supplier? supplier;
  final VoidCallback onSave;

  const SupplierFormPage({
    Key? key,
    this.supplier,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  
  late TextEditingController codeController;
  late TextEditingController nameController;
  late TextEditingController companyController;
  late TextEditingController contactController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController provinceController;
  late TextEditingController postalController;
  late TextEditingController taxIdController;
  late TextEditingController notesController;

  String selectedType = 'Domestic';
  bool isActive = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.supplier != null;
    
    codeController = TextEditingController(text: widget.supplier?.supplierCode ?? '');
    nameController = TextEditingController(text: widget.supplier?.supplierName ?? '');
    companyController = TextEditingController(text: widget.supplier?.companyName ?? '');
    contactController = TextEditingController(text: widget.supplier?.contactPerson ?? '');
    phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    emailController = TextEditingController(text: widget.supplier?.email ?? '');
    addressController = TextEditingController(text: widget.supplier?.address ?? '');
    cityController = TextEditingController(text: widget.supplier?.city ?? '');
    provinceController = TextEditingController(text: widget.supplier?.province ?? '');
    postalController = TextEditingController(text: widget.supplier?.postalCode ?? '');
    taxIdController = TextEditingController(text: widget.supplier?.taxId ?? '');
    notesController = TextEditingController(text: widget.supplier?.notes ?? '');
    
    if (widget.supplier != null) {
      selectedType = widget.supplier!.supplierType;
      isActive = widget.supplier!.isActive;
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    companyController.dispose();
    contactController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    provinceController.dispose();
    postalController.dispose();
    taxIdController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final supplier = Supplier(
        id: widget.supplier?.id,
        supplierCode: codeController.text.trim(),
        supplierName: nameController.text.trim(),
        companyName: companyController.text.trim(),
        contactPerson: contactController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        province: provinceController.text.trim(),
        postalCode: postalController.text.trim(),
        taxId: taxIdController.text.trim(),
        supplierType: selectedType,
        isActive: isActive,
        notes: notesController.text.trim(),
        createdAt: widget.supplier?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await dbHelper.updateSupplier(supplier);
      } else {
        await dbHelper.createSupplier(supplier);
      }

      widget.onSave();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? '✓ Supplier updated' : '✓ Supplier created'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Supplier' : 'Add New Supplier'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Supplier Code
            _buildTextField(
              controller: codeController,
              label: 'Supplier Code *',
              icon: Icons.tag,
              hint: 'e.g., SUP-001',
            ),
            const SizedBox(height: 16),
            
            // Supplier Name
            _buildTextField(
              controller: nameController,
              label: 'Supplier Name *',
              icon: Icons.store,
              hint: 'e.g., PT Jaya Abadi',
            ),
            const SizedBox(height: 16),
            
            // Company Name
            _buildTextField(
              controller: companyController,
              label: 'Company Name *',
              icon: Icons.business,
              hint: 'Official company name',
            ),
            const SizedBox(height: 16),
            
            // Contact Person
            _buildTextField(
              controller: contactController,
              label: 'Contact Person *',
              icon: Icons.person,
              hint: 'e.g., Budi Santoso',
            ),
            const SizedBox(height: 16),
            
            // Phone
            _buildTextField(
              controller: phoneController,
              label: 'Phone *',
              icon: Icons.phone,
              hint: 'e.g., 021-1234567',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Email
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email,
              hint: 'e.g., contact@supplier.com',
              keyboardType: TextInputType.emailAddress,
              required: false,
            ),
            const SizedBox(height: 16),
            
            // Address
            _buildTextField(
              controller: addressController,
              label: 'Address *',
              icon: Icons.location_on,
              hint: 'Full address',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // City & Province
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: cityController,
                    label: 'City *',
                    icon: Icons.location_city,
                    hint: 'e.g., Jakarta',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: provinceController,
                    label: 'Province *',
                    icon: Icons.map,
                    hint: 'e.g., DKI Jakarta',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Postal Code & Tax ID
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: postalController,
                    label: 'Postal Code',
                    icon: Icons.pin,
                    hint: 'e.g., 12345',
                    keyboardType: TextInputType.number,
                    required: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: taxIdController,
                    label: 'Tax ID / NPWP',
                    icon: Icons.receipt_long,
                    hint: 'Tax number',
                    required: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Supplier Type
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                labelText: 'Supplier Type',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ['Domestic', 'International'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Active Status
            SwitchListTile(
              title: const Text('Active Status'),
              subtitle: Text(isActive ? 'Currently active' : 'Currently inactive'),
              value: isActive,
              onChanged: (value) {
                setState(() {
                  isActive = value;
                });
              },
              activeColor: Colors.green,
            ),
            const SizedBox(height: 16),
            
            // Notes
            _buildTextField(
              controller: notesController,
              label: 'Notes',
              icon: Icons.note,
              hint: 'Additional notes (optional)',
              maxLines: 3,
              required: false,
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            ElevatedButton.icon(
              onPressed: _saveSupplier,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Update Supplier' : 'Save Supplier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }
}